#include "draconic/config.hpp"
#include "draconic/json.hpp"

#include <array>
#include <cstddef>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <variant>

namespace {

constexpr std::string_view valid_config =
    "instance_name=local-test\nrealm_id=1\nshard_id=2\nlog_level=info\n";

void require(bool condition, std::string_view message) {
    if (!condition) {
        throw std::runtime_error(std::string(message));
    }
}

void require_error(std::string_view input, draconic::config_error_code expected, std::size_t line) {
    const auto parsed = draconic::parse_config(input);
    const auto* error = std::get_if<draconic::config_error>(&parsed);
    require(error != nullptr, "Invalid configuration must be rejected");
    require(error->code == expected, "Unexpected configuration error code");
    require(error->line == line, "Unexpected configuration error line");
}

void accepts_required_fields_and_crlf() {
    const auto parsed = draconic::parse_config(
        "# identity\r\n\r\n instance_name = process_01 \r\nrealm_id=2147483647\r\n"
        "\tshard_id = 27\r\nlog_level=warning");
    const auto* config = std::get_if<draconic::process_config>(&parsed);
    require(config != nullptr, "Complete configuration with CRLF must parse");
    require(config->instance_name == "process_01", "Name must be preserved after trimming");
    require(config->realm_id == draconic::max_identity_id, "Maximum ID must be accepted");
    require(config->shard_id == 27U, "Shard ID must be parsed");
    require(config->logging == draconic::log_level::warning, "Log level must be parsed");

    for (const auto level : {"debug", "info", "warning", "error"}) {
        const auto text =
            "instance_name=local\nrealm_id=1\nshard_id=1\nlog_level=" + std::string(level);
        const auto result = draconic::parse_config(text);
        const auto* config_with_level = std::get_if<draconic::process_config>(&result);
        require(config_with_level != nullptr, "Documented log level must be accepted");
        require(draconic::to_string(config_with_level->logging) == level,
                "Log level must round-trip");
    }
}

void rejects_ambiguous_and_incomplete_configuration() {
    using code = draconic::config_error_code;
    require_error("", code::missing_key, 0U);
    require_error("# comment only\n", code::missing_key, 0U);
    require_error("instance_name=local\nrealm_id=1\nshard_id=1", code::missing_key, 0U);
    require_error(std::string(valid_config) + "realm_id=2", code::duplicate_key, 5U);
    require_error(std::string(valid_config) + "password=never-echo-this", code::unknown_key, 5U);
    require_error("instance_name local", code::invalid_syntax, 1U);
    require_error("instance_name=local=extra", code::invalid_syntax, 1U);
    require_error("instance_name=", code::invalid_value, 1U);
    require_error("instance_name=local\nrealm_id=1 # inline", code::invalid_value, 2U);
    require_error("instance_name=local\nrealm_id=1\nshard_id=1\nlog_level=INFO",
                  code::invalid_value, 4U);
}

void rejects_noncanonical_and_overflowing_ids() {
    using code = draconic::config_error_code;
    for (const auto invalid : {"0", "-1", "+1", "01", "1.0", "1e2", "0x10", "1z", "1 2",
                               "2147483648", "4294967296", "999999999999999999999999"}) {
        const auto text = "instance_name=local\nrealm_id=" + std::string(invalid) +
                          "\nshard_id=1\nlog_level=info";
        require_error(text, code::invalid_value, 2U);
    }
    require_error("instance_name=local\nrealm_id=1\nshard_id=-1\nlog_level=info",
                  code::invalid_value, 3U);
}

void enforces_ascii_identity_and_size_limits() {
    using code = draconic::config_error_code;
    const auto suffix = "\nrealm_id=1\nshard_id=1\nlog_level=info";
    const auto longest =
        "instance_name=" + std::string(draconic::max_instance_name_bytes, 'a') + suffix;
    require(std::holds_alternative<draconic::process_config>(draconic::parse_config(longest)),
            "Maximum instance name length must be accepted");
    require_error("instance_name=" + std::string(draconic::max_instance_name_bytes + 1U, 'a') +
                      suffix,
                  code::invalid_value, 1U);
    for (const auto invalid : {"9local", "Local", "local node", "local\"node", "../local"}) {
        require_error("instance_name=" + std::string(invalid) + suffix, code::invalid_value, 1U);
    }
    std::string embedded_nul(valid_config);
    embedded_nul.push_back('\0');
    require_error(embedded_nul, code::invalid_character, 5U);
    require_error(std::string("# ") + static_cast<char>(0xFF), code::invalid_character, 1U);
    require_error("\xEF\xBB\xBFinstance_name=local", code::invalid_character, 1U);
    const auto full_line =
        std::string("#") + std::string(draconic::max_config_line_bytes - 1U, ' ');
    require(std::holds_alternative<draconic::process_config>(
                draconic::parse_config(full_line + "\n" + std::string(valid_config))),
            "Maximum physical line length must be accepted");
    require_error(full_line + " \n", code::line_too_long, 1U);
    std::string exact_limit(valid_config);
    exact_limit.append(draconic::max_config_bytes - exact_limit.size(), '\n');
    require(std::holds_alternative<draconic::process_config>(draconic::parse_config(exact_limit)),
            "Maximum file length must be accepted");
    exact_limit.push_back('\n');
    require_error(exact_limit, code::file_too_large, 0U);
}

void escapes_diagnostic_bytes_without_log_injection() {
    require(draconic::json_string("") == "\"\"", "Empty JSON string");
    require(draconic::json_string("name\"\\\n\r\t") == "\"name\\\"\\\\\\u000a\\u000d\\u0009\"",
            "Escapes must prevent quote, slash, and newline injection");
    require(draconic::json_string(std::string("a\0b", 3U)) == "\"a\\u0000b\"",
            "Embedded NUL must be encoded, not truncate the log");
    for (unsigned int byte = 0U; byte <= 255U; ++byte) {
        const std::string input(1U, static_cast<char>(byte));
        const auto escaped = draconic::json_string(input);
        require(escaped.front() == '"' && escaped.back() == '"', "JSON string must be quoted");
        for (const char character : escaped) {
            const auto encoded_byte = static_cast<unsigned char>(character);
            require(encoded_byte >= 0x20U && encoded_byte <= 0x7EU,
                    "Diagnostic string must never contain raw control or high bytes");
        }
    }
}

} // namespace

int main() {
    struct test_case {
        std::string_view name;
        void (*run)();
    };
    const std::array tests{
        test_case{"required_fields_and_crlf", accepts_required_fields_and_crlf},
        test_case{"ambiguous_and_incomplete", rejects_ambiguous_and_incomplete_configuration},
        test_case{"numeric_validation", rejects_noncanonical_and_overflowing_ids},
        test_case{"identity_and_size_limits", enforces_ascii_identity_and_size_limits},
        test_case{"diagnostic_json_escaping", escapes_diagnostic_bytes_without_log_injection}};
    int failures = 0;
    for (const auto& test : tests) {
        try {
            test.run();
            std::cout << "PASS " << test.name << '\n';
        } catch (const std::exception& error) {
            ++failures;
            std::cerr << "FAIL " << test.name << ": " << error.what() << '\n';
        }
    }
    return failures == 0 ? 0 : 1;
}
