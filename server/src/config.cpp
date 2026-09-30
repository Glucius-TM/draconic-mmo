#include "draconic/config.hpp"

#include <array>
#include <charconv>
#include <system_error>

namespace draconic {
namespace {

constexpr std::array<std::string_view, 4> keys{"instance_name", "realm_id", "shard_id",
                                               "log_level"};

std::string_view trim(std::string_view text) noexcept {
    constexpr std::string_view whitespace = " \t\r";
    const auto first = text.find_first_not_of(whitespace);
    if (first == std::string_view::npos) {
        return {};
    }
    const auto last = text.find_last_not_of(whitespace);
    return text.substr(first, last - first + 1U);
}

bool valid_instance_name(std::string_view name) noexcept {
    if (name.empty() || name.size() > max_instance_name_bytes || name.front() < 'a' ||
        name.front() > 'z') {
        return false;
    }
    for (const char character : name) {
        if (!((character >= 'a' && character <= 'z') || (character >= '0' && character <= '9') ||
              character == '-' || character == '_')) {
            return false;
        }
    }
    return true;
}

bool parse_identity(std::string_view value, std::uint32_t& result) noexcept {
    // Canonical decimal IDs: no signs, leading zeroes, prefixes, or trailing characters.
    if (value.empty() || value.front() < '1' || value.front() > '9') {
        return false;
    }
    const auto parsed = std::from_chars(value.data(), value.data() + value.size(), result);
    return parsed.ec == std::errc{} && parsed.ptr == value.data() + value.size() &&
           result <= max_identity_id;
}

bool assign_value(process_config& config, std::size_t index, std::string_view value) {
    switch (index) {
    case 0:
        if (!valid_instance_name(value)) {
            return false;
        }
        config.instance_name = value;
        return true;
    case 1:
        return parse_identity(value, config.realm_id);
    case 2:
        return parse_identity(value, config.shard_id);
    case 3:
        if (value == "debug") {
            config.logging = log_level::debug;
        } else if (value == "info") {
            config.logging = log_level::info;
        } else if (value == "warning") {
            config.logging = log_level::warning;
        } else if (value == "error") {
            config.logging = log_level::error;
        } else {
            return false;
        }
        return true;
    default:
        return false;
    }
}

} // namespace

config_result parse_config(std::string_view input) {
    if (input.size() > max_config_bytes) {
        return config_error{config_error_code::file_too_large, 0U};
    }

    process_config config;
    std::array<bool, keys.size()> seen{};
    std::size_t offset = 0U;
    std::size_t line_number = 0U;
    while (offset < input.size()) {
        ++line_number;
        const auto end = input.find('\n', offset);
        const auto count = (end == std::string_view::npos ? input.size() : end) - offset;
        auto line = input.substr(offset, count);
        offset = end == std::string_view::npos ? input.size() : end + 1U;

        if (line.size() > max_config_line_bytes) {
            return config_error{config_error_code::line_too_long, line_number};
        }
        for (const char character : line) {
            const auto byte = static_cast<unsigned char>(character);
            if ((byte < 0x20U && character != '\t' && character != '\r') || byte > 0x7EU) {
                return config_error{config_error_code::invalid_character, line_number};
            }
        }
        line = trim(line);
        if (line.empty() || line.front() == '#') {
            continue;
        }

        const auto equals = line.find('=');
        if (equals == std::string_view::npos ||
            line.find('=', equals + 1U) != std::string_view::npos) {
            return config_error{config_error_code::invalid_syntax, line_number};
        }
        const auto key = trim(line.substr(0U, equals));
        const auto value = trim(line.substr(equals + 1U));
        std::size_t index = 0U;
        while (index < keys.size() && key != keys[index]) {
            ++index;
        }
        if (index == keys.size()) {
            return config_error{config_error_code::unknown_key, line_number};
        }
        if (seen[index]) {
            return config_error{config_error_code::duplicate_key, line_number};
        }
        if (!assign_value(config, index, value)) {
            return config_error{config_error_code::invalid_value, line_number};
        }
        seen[index] = true;
    }

    for (const bool present : seen) {
        if (!present) {
            return config_error{config_error_code::missing_key, 0U};
        }
    }
    return config;
}

std::string_view to_string(config_error_code code) noexcept {
    switch (code) {
    case config_error_code::file_too_large:
        return "file_too_large";
    case config_error_code::line_too_long:
        return "line_too_long";
    case config_error_code::invalid_character:
        return "invalid_character";
    case config_error_code::invalid_syntax:
        return "invalid_syntax";
    case config_error_code::unknown_key:
        return "unknown_key";
    case config_error_code::duplicate_key:
        return "duplicate_key";
    case config_error_code::invalid_value:
        return "invalid_value";
    case config_error_code::missing_key:
        return "missing_key";
    }
    return "unknown_error";
}

std::string_view to_string(log_level level) noexcept {
    switch (level) {
    case log_level::debug:
        return "debug";
    case log_level::info:
        return "info";
    case log_level::warning:
        return "warning";
    case log_level::error:
        return "error";
    }
    return "unknown";
}

} // namespace draconic
