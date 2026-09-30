option(DRACONIC_WARNINGS_AS_ERRORS "Treat native compiler warnings as errors" ON)
option(DRACONIC_ENABLE_SANITIZERS "Enable AddressSanitizer and UndefinedBehaviorSanitizer" OFF)

function(draconic_apply_options target)
    if(MSVC)
        target_compile_options(${target} PRIVATE /W4 /permissive- /utf-8 /EHsc)
        if(DRACONIC_WARNINGS_AS_ERRORS)
            target_compile_options(${target} PRIVATE /WX)
        endif()
        if(DRACONIC_ENABLE_SANITIZERS)
            message(FATAL_ERROR "Combined ASan/UBSan preset requires GCC or Clang on Linux.")
        endif()
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(${target} PRIVATE
            -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow
        )
        if(DRACONIC_WARNINGS_AS_ERRORS)
            target_compile_options(${target} PRIVATE -Werror)
        endif()
        if(DRACONIC_ENABLE_SANITIZERS)
            target_compile_options(${target} PRIVATE
                -fsanitize=address,undefined -fno-omit-frame-pointer
            )
            target_link_options(${target} PRIVATE -fsanitize=address,undefined)
        endif()
    else()
        message(FATAL_ERROR "Unvalidated C++ compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif()
endfunction()
