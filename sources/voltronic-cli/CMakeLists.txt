CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
PROJECT("skymax")

set (CMAKE_CXX_FLAGS "-O2 --std=c++0x ${CMAKE_CXX_FLAGS}")

file(GLOB SOURCES *.cpp)
ADD_EXECUTABLE(bin/skymax ${SOURCES})
target_link_libraries(bin/skymax -lpthread)
