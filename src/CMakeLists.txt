cmake_minimum_required(VERSION 3.14...3.25)

project(sd VERSION 0.0.1 LANGUAGES C CXX)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -ffast-math")

set(SD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp)
set(SD_BRANCH "master-585-44cca3d")

# Clone stable-diffusion.cpp if necessary
if(NOT EXISTS ${SD_DIR})
    message(STATUS "Downloading stable-diffusion.cpp...")
    execute_process(COMMAND git clone --recursive --branch ${SD_BRANCH} --depth 1 https://github.com/leejet/stable-diffusion.cpp.git ${SD_DIR})
endif()

set(GGML_CPU ON CACHE BOOL "" FORCE)
set(SD_VULKAN ON CACHE BOOL "" FORCE)

if(SD_VULKAN)
    set(VK_DIR ${CMAKE_CURRENT_SOURCE_DIR}/vulkan)
    set(SPIRV_DIR ${CMAKE_CURRENT_SOURCE_DIR}/spirv)
    set(VK_VERSION "vulkan-sdk-1.3.275")
    
    # Download Vulkan headers if necessary
    if(NOT EXISTS ${VK_DIR}/Vulkan-Headers/include)
        message(STATUS "Downloading Vulkan ${VK_VERSION} SDK headers...")
        execute_process(COMMAND git clone --depth 1 --branch ${VK_VERSION} https://github.com/KhronosGroup/Vulkan-Headers.git ${VK_DIR}/Vulkan-Headers)
    endif()
    set(Vulkan_INCLUDE_DIRS "${VK_DIR}/Vulkan-Headers/include" CACHE STRING "" FORCE)
    include_directories(BEFORE ${Vulkan_INCLUDE_DIRS})

    # Download SPIRV Headers if necessary
    if(NOT EXISTS ${SPIRV_DIR}/SPIRV-Headers/include)
        message(STATUS "Downloading SPIRV-Headers...")
        execute_process(COMMAND git clone --depth 1 --branch ${VK_VERSION} https://github.com/KhronosGroup/SPIRV-Headers.git ${SPIRV_DIR}/SPIRV-Headers)
    endif()
    set(SPIRV_Headers_DIR "${SPIRV_DIR}/SPIRV-Headers/include" CACHE STRING "" FORCE)
    include_directories(BEFORE ${SPIRV_Headers_DIR})
else()
    set(GGML_BLAS ON CACHE BOOL "" FORCE)
    set(GGML_BALS_VENDOR "OpenBLAS" CACHE STRING "" FORCE)
endif()

# Android / ARM config
if(ANDROID)
    if(SD_VULKAN)
        find_library(VULKAN_LIB vulkan REQUIRED)
    endif()

    set(SD_WEBP OFF CACHE BOOL "" FORCE)
    set(SD_WEBM OFF CACHE BOOL "" FORCE)
    set(SD_OPENCL OFF CACHE BOOL "" FORCE)

    # set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
    # set(GGML_CPU_REPACK OFF CACHE BOOL "" FORCE)
    # set(GGML_CPU_ALL_VARIANTS OFF CACHE BOOL "" FORCE)
    # set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
    # set(GGML_ACCELERATE OFF CACHE BOOL "" FORCE)
    # set(GGML_CPU_KLEIDIAI OFF CACHE BOOL "" FORCE)
    
    # set(GGML_HEXAGON OFF CACHE BOOL "" FORCE)
endif()

set(SD_BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)

# Subproject
add_subdirectory(${SD_DIR})

# link principal (força build)
if(TARGET stable-diffusion)
else()
    message(FATAL_ERROR "stable-diffusion target not found")
endif()

# Link Vulkan
if(TARGET stable-diffusion AND TARGET ${VULKAN_LIB})
    target_link_libraries(stable-diffusion PRIVATE ${VULKAN_LIB})
endif()

# flag necessária Android moderno
    if(ANDROID)
        target_link_options(stable-diffusion PRIVATE "-Wl,-z,max-page-size=16384")
    endif()