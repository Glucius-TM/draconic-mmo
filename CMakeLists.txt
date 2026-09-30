cmake_minimum_required(VERSION 3.24)
project(DraconicMMO VERSION 0.1.0 LANGUAGES CXX)

include(CTest)
include(cmake/CompilerOptions.cmake)

add_library(draconic_foundation STATIC
    server/src/config.cpp
    server/src/json.cpp
)
target_include_directories(draconic_foundation PUBLIC server/include)
target_compile_features(draconic_foundation PUBLIC cxx_std_20)
set_target_properties(draconic_foundation PROPERTIES CXX_EXTENSIONS OFF)
draconic_apply_options(draconic_foundation)

add_executable(draconic_foundation_cli server/src/main.cpp)
target_link_libraries(draconic_foundation_cli PRIVATE draconic_foundation)
target_compile_definitions(draconic_foundation_cli PRIVATE
    DRACONIC_VERSION="${PROJECT_VERSION}"
)
set_target_properties(draconic_foundation_cli PROPERTIES
    OUTPUT_NAME draconic_foundation
    CXX_EXTENSIONS OFF
)
draconic_apply_options(draconic_foundation_cli)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
