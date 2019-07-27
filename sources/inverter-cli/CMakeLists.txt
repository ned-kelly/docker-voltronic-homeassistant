CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
PROJECT("inverter_poller")

set (CMAKE_CXX_FLAGS "-O2 --std=c++0x ${CMAKE_CXX_FLAGS}")

file(GLOB SOURCES *.cpp)
ADD_EXECUTABLE(inverter_poller ${SOURCES})
target_link_libraries(inverter_poller -lpthread)
