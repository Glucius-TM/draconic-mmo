#include "draconic/json.hpp"

namespace draconic {

std::string json_string(std::string_view value) {
    constexpr char hexadecimal[] = "0123456789abcdef";
    std::string result;
    result.push_back('"');
    for (const char character : value) {
        const auto byte = static_cast<unsigned char>(character);
        if (character == '"' || character == '\\') {
            result.push_back('\\');
            result.push_back(character);
        } else if (byte < 0x20U || byte > 0x7EU) {
            result += "\\u00";
            result.push_back(hexadecimal[byte >> 4U]);
            result.push_back(hexadecimal[byte & 0x0FU]);
        } else {
            result.push_back(character);
        }
    }
    result.push_back('"');
    return result;
}

} // namespace draconic
