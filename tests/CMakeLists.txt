add_executable(draconic_foundation_tests foundation_tests.cpp)
target_link_libraries(draconic_foundation_tests PRIVATE draconic_foundation)
set_target_properties(draconic_foundation_tests PROPERTIES CXX_EXTENSIONS OFF)
draconic_apply_options(draconic_foundation_tests)
add_test(NAME foundation.unit COMMAND draconic_foundation_tests)
set_tests_properties(foundation.unit PROPERTIES TIMEOUT 10)

file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/fixtures")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/fixtures/unknown.conf" "password=never-echo-this\n")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/fixtures/duplicate.conf"
    "instance_name=local\nrealm_id=1\nshard_id=1\nlog_level=info\nrealm_id=2\n")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/fixtures/missing.conf" "instance_name=local\n")
string(REPEAT "x" 16385 oversized_content)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/fixtures/oversized.conf" "${oversized_content}")
unset(oversized_content)

function(draconic_cli_test case_name expected_exit expected_event expected_code)
    add_test(NAME "foundation.cli.${case_name}"
        COMMAND "${CMAKE_COMMAND}"
            "-DCLI=$<TARGET_FILE:draconic_foundation_cli>"
            "-DSOURCE_DIR=${PROJECT_SOURCE_DIR}"
            "-DFIXTURE_DIR=${CMAKE_CURRENT_BINARY_DIR}/fixtures"
            "-DCASE=${case_name}"
            "-DEXPECTED_EXIT=${expected_exit}"
            "-DEXPECTED_EVENT=${expected_event}"
            "-DEXPECTED_CODE=${expected_code}"
            "-DEXPECTED_VERSION=${PROJECT_VERSION}"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/check_cli.cmake")
    set_tests_properties("foundation.cli.${case_name}" PROPERTIES TIMEOUT 15)
endfunction()

draconic_cli_test(valid 0 config_valid "")
draconic_cli_test(no_arguments 2 foundation_error invalid_arguments)
draconic_cli_test(extra_argument 2 foundation_error invalid_arguments)
draconic_cli_test(unknown 2 foundation_error unknown_key)
draconic_cli_test(duplicate 2 foundation_error duplicate_key)
draconic_cli_test(missing 2 foundation_error missing_key)
draconic_cli_test(oversized 2 foundation_error file_too_large)
draconic_cli_test(unavailable 3 foundation_error config_file_unavailable)
draconic_cli_test(directory 3 foundation_error config_file_unavailable)
draconic_cli_test(version 0 "" "")
draconic_cli_test(help 0 "" "")
