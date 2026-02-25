target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
    skyxmanager.cpp
    skyxmanager.h
)
# This makes sure other modules can find your .h file via #include "skyxmanager.h"
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
