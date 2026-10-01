#include "draconic/config.hpp"
#include "draconic/json.hpp"

#include <array>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string_view>
#include <system_error>
#include <variant>

namespace {

int emit_error(std::string_view code, int exit_code, std::size_t line = 0U) {
    std::cerr << "{\"event\":\"foundation_error\",\"code\":" << draconic::json_string(code)
              << ",\"line\":" << line << ",\"services_started\":0}\n";
    return exit_code;
}

int check_config(const std::filesystem::path& path) {
    std::error_code status_error;
    if (!std::filesystem::is_regular_file(path, status_error) || status_error) {
        return emit_error("config_file_unavailable", 3);
    }
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) {
        return emit_error("config_file_unavailable", 3);
    }

    // Read at most limit+1 bytes; never allocate based on an untrusted file size.
    std::array<char, draconic::max_config_bytes + 1U> buffer{};
    file.read(buffer.data(), static_cast<std::streamsize>(buffer.size()));
    if (file.bad() || (file.fail() && !file.eof())) {
        return emit_error("config_read_failed", 3);
    }
    const auto size = static_cast<std::size_t>(file.gcount());
    const auto parsed = draconic::parse_config(std::string_view(buffer.data(), size));
    if (const auto* error = std::get_if<draconic::config_error>(&parsed)) {
        return emit_error(draconic::to_string(error->code), 2, error->line);
    }

    const auto& config = std::get<draconic::process_config>(parsed);
    std::cout << "{\"event\":\"config_valid\",\"mode\":\"offline_validation\",\"version\":"
              << draconic::json_string(DRACONIC_VERSION)
              << ",\"instance_name\":" << draconic::json_string(config.instance_name)
              << ",\"realm_id\":" << config.realm_id << ",\"shard_id\":" << config.shard_id
              << ",\"log_level\":" << draconic::json_string(draconic::to_string(config.logging))
              << ",\"services_started\":0}\n";
    return 0;
}

} // namespace

#ifdef _WIN32
// The narrow Windows entry point loses path characters outside the active code page.
int wmain(int argc, wchar_t* argv[]) {
    constexpr std::wstring_view help_option = L"--help";
    constexpr std::wstring_view version_option = L"--version";
    constexpr std::wstring_view check_command = L"check-config";
#else
int main(int argc, char* argv[]) {
    constexpr std::string_view help_option = "--help";
    constexpr std::string_view version_option = "--version";
    constexpr std::string_view check_command = "check-config";
#endif
    if (argc == 2 && argv[1] == help_option) {
        std::cout << "Usage: draconic_foundation check-config <file>\n"
                     "       draconic_foundation --version\n"
                     "Offline foundation diagnostics only. No game or network services start.\n"
                     "Exit codes: 0 success, 2 invalid arguments/config, 3 file unavailable/read "
                     "error.\n";
        return 0;
    }
    if (argc == 2 && argv[1] == version_option) {
        std::cout << "{\"component\":\"draconic_foundation\",\"version\":"
                  << draconic::json_string(DRACONIC_VERSION) << ",\"phase\":0}\n";
        return 0;
    }
    if (argc == 3 && argv[1] == check_command) {
        return check_config(std::filesystem::path(argv[2]));
    }
    return emit_error("invalid_arguments", 2);
}
