cmake_minimum_required(VERSION 3.15)
project(system_theme_windows_native_test LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(CTest)

add_executable(system_theme_windows_native_test
  "theme_change_message_test.cpp"
)
target_include_directories(system_theme_windows_native_test PRIVATE
  "${CMAKE_CURRENT_LIST_DIR}/.."
)

add_test(NAME system_theme_windows_native_test COMMAND system_theme_windows_native_test)
