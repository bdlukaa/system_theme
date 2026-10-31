cmake_minimum_required(VERSION 3.10)
project(system_theme_linux_tests LANGUAGES CXX)

enable_testing()

add_executable(accent_color_test
  "accent_color_test.cc"
  "../accent_color.cc"
)
target_compile_features(accent_color_test PRIVATE cxx_std_14)

add_test(NAME accent_color_test COMMAND accent_color_test)
