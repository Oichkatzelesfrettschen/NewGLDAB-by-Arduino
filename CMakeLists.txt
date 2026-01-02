cmake_minimum_required(VERSION 3.16)

# Project definition
project(NewGLDAB
    VERSION 1.0.0
    DESCRIPTION "Advanced Ornithopter Flight Control System"
    LANGUAGES C CXX ASM
)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Options
option(BUILD_TESTS "Build unit tests" ON)
option(BUILD_DOCS "Build documentation" ON)
option(ENABLE_STATIC_ANALYSIS "Enable static analysis" OFF)
option(ARDUINO_BUILD "Build for Arduino target" ON)

# Arduino toolchain setup
if(ARDUINO_BUILD)
    set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/cmake/ArduinoToolchain.cmake CACHE FILEPATH "Arduino toolchain")
    
    # Arduino-specific settings
    set(ARDUINO_BOARD "pro16MHzatmega328" CACHE STRING "Arduino board type")
    set(ARDUINO_PORT "/dev/ttyUSB0" CACHE STRING "Arduino upload port")
    set(ARDUINO_BAUD "57600" CACHE STRING "Arduino upload baud rate")
endif()

# Build types
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# Compiler flags
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(
        -Wall
        -Wextra
        -Wpedantic
        -Wno-unused-parameter
    )
    
    if(CMAKE_BUILD_TYPE MATCHES "Debug")
        add_compile_options(-Og -g)
        add_definitions(-DDEBUG -DENABLE_LOGGING)
    elseif(CMAKE_BUILD_TYPE MATCHES "Release")
        add_compile_options(-Os -flto)
        add_definitions(-DNDEBUG)
    endif()
endif()

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src
)

# Source files (when refactored)
set(GLDAB_SOURCES
    src/main.cpp
    # Future modular sources:
    # src/sensors/hall_sensor.cpp
    # src/sensors/imu_sensor.cpp
    # src/control/pid_controller.cpp
    # src/control/quaternion.cpp
    # src/utils/kalman_filter.cpp
)

# Arduino libraries
if(ARDUINO_BUILD)
    # Servo library
    add_library(servo INTERFACE)
    target_include_directories(servo INTERFACE 
        ${ARDUINO_SDK_PATH}/libraries/Servo/src
    )
    
    # EEPROM library
    add_library(eeprom INTERFACE)
    target_include_directories(eeprom INTERFACE 
        ${ARDUINO_SDK_PATH}/hardware/arduino/avr/libraries/EEPROM/src
    )
endif()

# Main executable/library
if(ARDUINO_BUILD)
    # Arduino firmware
    add_executable(NewGLDAB_firmware ${GLDAB_SOURCES})
    
    target_link_libraries(NewGLDAB_firmware PRIVATE
        servo
        eeprom
        arduino_core
    )
    
    # Generate hex file for upload
    add_custom_command(TARGET NewGLDAB_firmware POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex -R .eeprom 
                $<TARGET_FILE:NewGLDAB_firmware> 
                ${CMAKE_BINARY_DIR}/NewGLDAB.hex
        COMMENT "Generating HEX file"
    )
    
    # Upload target
    add_custom_target(upload
        COMMAND avrdude -c arduino -p m328p -P ${ARDUINO_PORT} -b ${ARDUINO_BAUD} 
                -U flash:w:${CMAKE_BINARY_DIR}/NewGLDAB.hex:i
        DEPENDS NewGLDAB_firmware
        COMMENT "Uploading firmware to Arduino"
    )
else()
    # Native library for testing
    add_library(NewGLDAB STATIC ${GLDAB_SOURCES})
    
    target_compile_definitions(NewGLDAB PRIVATE NATIVE_BUILD)
endif()

# Unit tests
if(BUILD_TESTS AND NOT ARDUINO_BUILD)
    enable_testing()
    
    # Find Unity test framework
    find_package(Unity QUIET)
    if(NOT Unity_FOUND)
        # Download and build Unity
        include(FetchContent)
        FetchContent_Declare(
            unity
            GIT_REPOSITORY https://github.com/ThrowTheSwitch/Unity.git
            GIT_TAG v2.5.2
        )
        FetchContent_MakeAvailable(unity)
    endif()
    
    # Test executables
    add_subdirectory(test)
    
    # Add test targets
    add_test(NAME test_sensors COMMAND test_sensors)
    add_test(NAME test_control COMMAND test_control)
    add_test(NAME test_quaternion COMMAND test_quaternion)
endif()

# Documentation
if(BUILD_DOCS)
    find_package(Doxygen)
    if(DOXYGEN_FOUND)
        set(DOXYGEN_IN ${CMAKE_SOURCE_DIR}/docs/Doxyfile.in)
        set(DOXYGEN_OUT ${CMAKE_BINARY_DIR}/Doxyfile)
        
        configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)
        
        add_custom_target(docs
            COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            COMMENT "Generating API documentation with Doxygen"
            VERBATIM
        )
    endif()
endif()

# Static analysis
if(ENABLE_STATIC_ANALYSIS)
    find_program(CLANG_TIDY clang-tidy)
    if(CLANG_TIDY)
        set(CMAKE_CXX_CLANG_TIDY ${CLANG_TIDY} 
            -checks=*,-fuchsia-*,-google-*,-llvm*)
    endif()
    
    find_program(CPPCHECK cppcheck)
    if(CPPCHECK)
        add_custom_target(cppcheck
            COMMAND ${CPPCHECK} --enable=all --inline-suppr 
                    --suppress=missingIncludeSystem
                    ${CMAKE_SOURCE_DIR}/src
            COMMENT "Running cppcheck static analysis"
        )
    endif()
endif()

# Formal verification targets
add_custom_target(verify_tla
    COMMAND tlc ${CMAKE_SOURCE_DIR}/docs/formal-verification/GLDAB_System.tla
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/docs/formal-verification
    COMMENT "Running TLA+ model checking"
)

add_custom_target(verify_z3
    COMMAND z3 ${CMAKE_SOURCE_DIR}/docs/formal-verification/GLDAB_Constraints.smt2
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/docs/formal-verification
    COMMENT "Running Z3 constraint verification"
)

add_custom_target(verify ALL
    DEPENDS verify_tla verify_z3
    COMMENT "Running all formal verification"
)

# Installation
if(ARDUINO_BUILD)
    install(FILES ${CMAKE_BINARY_DIR}/NewGLDAB.hex
            DESTINATION bin
            COMPONENT firmware)
endif()

install(DIRECTORY ${CMAKE_SOURCE_DIR}/docs/
        DESTINATION share/doc/NewGLDAB
        COMPONENT documentation)

# Package configuration
set(CPACK_PACKAGE_NAME "NewGLDAB")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${PROJECT_DESCRIPTION})
set(CPACK_PACKAGE_VENDOR "Kazuhiko Kakuta")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README.md")

include(CPack)

# Print configuration summary
message(STATUS "")
message(STATUS "NewGLDAB Configuration:")
message(STATUS "  Version:           ${PROJECT_VERSION}")
message(STATUS "  Build type:        ${CMAKE_BUILD_TYPE}")
message(STATUS "  Arduino build:     ${ARDUINO_BUILD}")
message(STATUS "  Build tests:       ${BUILD_TESTS}")
message(STATUS "  Build docs:        ${BUILD_DOCS}")
message(STATUS "  Static analysis:   ${ENABLE_STATIC_ANALYSIS}")
if(ARDUINO_BUILD)
    message(STATUS "  Arduino board:     ${ARDUINO_BOARD}")
    message(STATUS "  Upload port:       ${ARDUINO_PORT}")
endif()
message(STATUS "")
