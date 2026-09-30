#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <variant>

namespace draconic {

inline constexpr std::size_t max_config_bytes = 16U * 1024U;
inline constexpr std::size_t max_config_line_bytes = 256U;
inline constexpr std::size_t max_instance_name_bytes = 48U;
inline constexpr std::uint32_t max_identity_id = 2147483647U;

enum class log_level { debug, info, warning, error };

struct process_config {
    std::string instance_name;
    std::uint32_t realm_id{};
    std::uint32_t shard_id{};
    log_level logging{log_level::info};
};

enum class config_error_code {
    file_too_large,
    line_too_long,
    invalid_character,
    invalid_syntax,
    unknown_key,
    duplicate_key,
    invalid_value,
    missing_key
};

struct config_error {
    config_error_code code;
    // One-based input line, or zero for file-wide and missing-key errors.
    std::size_t line;
};

using config_result = std::variant<process_config, config_error>;

// ASCII key=value format. All four keys are required; only full-line # comments are supported.
// Diagnostics intentionally exclude raw input, which might contain secrets.
[[nodiscard]] config_result parse_config(std::string_view input);
[[nodiscard]] std::string_view to_string(config_error_code code) noexcept;
[[nodiscard]] std::string_view to_string(log_level level) noexcept;

} // namespace draconic
