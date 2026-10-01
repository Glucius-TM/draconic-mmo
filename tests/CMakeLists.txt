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

set(valid_content "instance_name=local\nrealm_id=1\nshard_id=1\nlog_level=info\n")
string(LENGTH "${valid_content}" valid_size)
math(EXPR padding_size "16384 - ${valid_size}")
string(REPEAT "\n" ${padding_size} padding)
file(CONFIGURE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/fixtures/exact_limit.conf"
    CONTENT "${valid_content}${padding}" @ONLY NEWLINE_STYLE UNIX)
string(REPEAT " " 255 line_padding)
file(CONFIGURE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/fixtures/exact_line.conf"
    CONTENT "#${line_padding}\n${valid_content}" @ONLY NEWLINE_STYLE UNIX)
file(CONFIGURE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/fixtures/long_line.conf"
    CONTENT "#${line_padding} \n${valid_content}" @ONLY NEWLINE_STYLE UNIX)
file(CONFIGURE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/fixtures/crlf.conf"
    CONTENT "${valid_content}" @ONLY NEWLINE_STYLE DOS)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/fixtures/ruta con espacios-龍")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/fixtures/ruta con espacios-龍/配置.conf" "${valid_content}")
string(ASCII 239 187 191 bom)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/fixtures/bom.conf" "${bom}${valid_content}")
string(ASCII 1 control_character)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/fixtures/control.conf" "${valid_content}#${control_character}")
unset(padding)
unset(line_padding)

function(draconic_cli_test case_name expected_exit expected_event expected_code expected_line)
    add_test(NAME "foundation.cli.${case_name}"
        COMMAND "${CMAKE_COMMAND}"
            "-DCLI=$<TARGET_FILE:draconic_foundation_cli>"
            "-DSOURCE_DIR=${PROJECT_SOURCE_DIR}"
            "-DFIXTURE_DIR=${CMAKE_CURRENT_BINARY_DIR}/fixtures"
            "-DCASE=${case_name}"
            "-DEXPECTED_EXIT=${expected_exit}"
            "-DEXPECTED_EVENT=${expected_event}"
            "-DEXPECTED_CODE=${expected_code}"
            "-DEXPECTED_LINE=${expected_line}"
            "-DEXPECTED_VERSION=${PROJECT_VERSION}"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/check_cli.cmake")
    set_tests_properties("foundation.cli.${case_name}" PROPERTIES TIMEOUT 15)
endfunction()

draconic_cli_test(valid 0 config_valid "" "")
draconic_cli_test(exact_limit 0 config_valid "" "")
draconic_cli_test(exact_line 0 config_valid "" "")
draconic_cli_test(crlf 0 config_valid "" "")
draconic_cli_test(unicode_path 0 config_valid "" "")
draconic_cli_test(no_arguments 2 foundation_error invalid_arguments 0)
draconic_cli_test(extra_argument 2 foundation_error invalid_arguments 0)
draconic_cli_test(unknown 2 foundation_error unknown_key 1)
draconic_cli_test(duplicate 2 foundation_error duplicate_key 5)
draconic_cli_test(missing 2 foundation_error missing_key 0)
draconic_cli_test(oversized 2 foundation_error file_too_large 0)
draconic_cli_test(long_line 2 foundation_error line_too_long 1)
draconic_cli_test(bom 2 foundation_error invalid_character 1)
draconic_cli_test(control 2 foundation_error invalid_character 5)
draconic_cli_test(unavailable 3 foundation_error config_file_unavailable 0)
draconic_cli_test(directory 3 foundation_error config_file_unavailable 0)
draconic_cli_test(version 0 "" "" "")
draconic_cli_test(help 0 "" "" "")

add_test(NAME foundation.install
    COMMAND "${CMAKE_COMMAND}"
        "-DBUILD_DIR=${PROJECT_BINARY_DIR}"
        "-DINSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install-smoke/$<CONFIG>"
        "-DINSTALL_BINDIR=${CMAKE_INSTALL_BINDIR}"
        "-DINSTALL_DATADIR=${CMAKE_INSTALL_DATADIR}"
        "-DEXECUTABLE_SUFFIX=${CMAKE_EXECUTABLE_SUFFIX}"
        "-DCONFIG=$<CONFIG>"
        "-DEXPECTED_VERSION=${PROJECT_VERSION}"
        -P "${PROJECT_SOURCE_DIR}/cmake/CheckInstall.cmake")
set_tests_properties(foundation.install PROPERTIES TIMEOUT 30)
