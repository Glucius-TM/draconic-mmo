#pragma once

#include <string>
#include <string_view>

namespace draconic {

// Encodes arbitrary bytes as a JSON string; bytes outside printable ASCII use \u00XX.
// This utility is for bounded diagnostic fields, not gameplay serialization.
[[nodiscard]] std::string json_string(std::string_view value);

} // namespace draconic
