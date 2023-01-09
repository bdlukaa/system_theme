cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "system_theme")
project(${PROJECT_NAME} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)

set(PLUGIN_NAME "system_theme_plugin")

include_directories(
  ${PLUGIN_NAME}
  INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}"
)

add_compile_definitions("NOMINMAX")

add_library(${PLUGIN_NAME} SHARED
  "system_theme_plugin.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin "Advapi32.lib")

set(system_theme_bundled_libraries
  ""
  PARENT_SCOPE
)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4458 /wd4244 /wd4701")