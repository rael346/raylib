cmake_minimum_required(VERSION 3.25.0)
project(
	raylib
	VERSION 5.6.0
	LANGUAGES C
	DESCRIPTION "A simple and easy-to-use library to enjoy videogames programming"
	HOMEPAGE_URL "https://www.raylib.com"
)

include(CMakeDependentOption)
# "PLATFORM_DESKTOP_GLFW"
# "PLATFORM_DESKTOP_SDL"
# "PLATFORM_DESKTOP_RGFW"
# "PLATFORM_WEB_RGFW"
# "PLATFORM_WEB"
# "PLATFORM_DRM"
# "PLATFORM_ANDROID"
set(RAYLIB_PLATFORM "PLATFORM_DESKTOP_GLFW" CACHE STRING "raylib target platform")
option(RAYLIB_BUILD_SHARED_LIBS "Building raylib as a SHARED library" OFF)
option(RAYLIB_USE_EXTERNAL_GLFW "Use external GLFW library instead of rglfw module" OFF)
option(RAYLIB_MODULE_AUDIO "Include audio module" ON)
option(RAYLIB_MODULE_MODELS "Include models module" ON)
cmake_dependent_option(RAYLIB_GLFW_BUILD_WAYLAND
	"Build support for Wayland on Linux for GLFW (this is for the GLFW version included with raylib, use GLFW_BUILD_WAYLAND if using external GLFW)" ON "UNIX;NOT APPLE" OFF
)
cmake_dependent_option(RAYLIB_BUILD_EXAMPLES
	"Build examples (only when raylib is top level)" ON "PROJECT_IS_TOP_LEVEL" OFF
)

if (RAYLIB_BUILD_SHARED_LIBS)
	add_library(raylib SHARED)
else()
	add_library(raylib STATIC)
endif()

if (RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_GLFW")
	set(GRAPHICS "GRAPHICS_API_OPENGL_33")

	if (RAYLIB_USE_EXTERNAL_GLFW)

		include(FetchContent)
		set(GLFW_STANDALONE OFF)
		set(GLFW_BUILD_DOCS OFF)
		set(GLFW_INSTALL OFF)
		set(GLFW_LIBRARY_TYPE "STATIC")
		FetchContent_Declare(glfw
			GIT_REPOSITORY "https://github.com/glfw/glfw.git"
			GIT_TAG "master"
			OVERRIDE_FIND_PACKAGE
			EXCLUDE_FROM_ALL
		)

		find_package(glfw REQUIRED)
		target_link_libraries(raylib PRIVATE glfw)
	else()
		target_sources(raylib
			PRIVATE 			src/rglfw.c
			PRIVATE
				FILE_SET 		glfwHeaders
				TYPE				HEADERS
				BASE_DIRS 	src/external/glfw/include
				FILES  			src/external/glfw/include/GLFW/glfw3.h
										src/external/glfw/include/GLFW/glfw3native.h
		)
		target_link_libraries(raylib PRIVATE
			"-framework Cocoa"
			"-framework IOKit"
			"-framework CoreFoundation"
			"-framework QuartzCore"
		)
		set_source_files_properties(src/rglfw.c PROPERTIES COMPILE_OPTIONS "-U_GNU_SOURCE")
		if (APPLE)
			set_source_files_properties(src/rglfw.c PROPERTIES COMPILE_OPTIONS "-xobjective-c")
		endif()
	endif()


	if (LINUX)
		target_compile_definitions(raylib PRIVATE
			$<IF:$<BOOL:${RAYLIB_GLFW_BUILD_WAYLAND}>,_GLFW_WAYLAND,_GLFW_X11>
		)
	endif()

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_SDL")
	set(GRAPHICS "GRAPHICS_API_OPENGL_33")

	include(FetchContent)
	set(SDL_TEST_LIBRARY OFF)
	set(SDL_SHARED OFF)
	set(SDL_STATIC ON)
	FetchContent_Declare(SDL3
		GIT_REPOSITORY "https://github.com/libsdl-org/SDL.git"
		GIT_TAG "main"
		GIT_SHALLOW ON
		GIT_PROGRESS ON
		OVERRIDE_FIND_PACKAGE
		EXCLUDE_FROM_ALL
	)

	find_package(SDL3 QUIET)
	if(${SDL3_FOUND})
		target_link_libraries(raylib PRIVATE SDL3::SDL3)
		target_compile_definitions(raylib PRIVATE USING_SDL3_PROJECT)
	else()
		find_package(SDL2 REQUIRED)
		target_link_libraries(raylib PRIVATE SDL2::SDL2)
		target_compile_definitions(raylib PRIVATE USING_SDL2_PROJECT)
	endif()

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_RGFW")
	set(GRAPHICS "GRAPHICS_API_OPENGL_33")

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_WEB" OR RAYLIB_PLATFORM STREQUAL "PLATFORM_WEB_RGFW")
	set(GRAPHICS "GRAPHICS_API_OPENGL_ES2")
	target_compile_definitions(raylib PRIVATE _DEFAULT_SOURCE)
	target_link_options(raylib INTERFACE "-sASYNCIFY")
	if (RAYLIB_PLATFORM STREQUAL "PLATFORM_WEB")
		target_link_options(raylib INTERFACE "-sUSE_GLFW=3")
	endif()

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_DRM")
	set(GRAPHICS "GRAPHICS_API_OPENGL_ES2")

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_ANDROID")
	set(GRAPHICS "GRAPHICS_API_OPENGL_ES2")

else()
	message(FATAL_ERROR "Platform ${RAYLIB_PLATFORM} not supported")
endif()

target_sources(raylib
	PRIVATE
		$<$<BOOL:${RAYLIB_MODULE_AUDIO}>:src/raudio.c>
		$<$<BOOL:${RAYLIB_MODULE_MODELS}>:src/rmodels.c>
		src/rcore.c
		src/rshapes.c
		src/rtext.c
		src/rtextures.c
		src/utils.c

	PUBLIC
		FILE_SET 		raylibHeaders
		TYPE 				HEADERS
		BASE_DIRS 	src
		FILES  			src/raylib.h
								src/rcamera.h
								src/rlgl.h
								src/raymath.h
)
target_compile_features(raylib PRIVATE c_std_99)
target_compile_definitions(raylib
	PUBLIC
		${RAYLIB_PLATFORM}
		${GRAPHICS}

	PRIVATE
		_GNU_SOURCE
		$<$<PLATFORM_ID:Windows>:UNICODE>
		$<$<PLATFORM_ID:Linux>:_DEFAULT_SOURCE>
		$<$<CONFIG:DEBUG>:_DEBUG>
)

if (PROJECT_IS_TOP_LEVEL)
	if (RAYLIB_BUILD_EXAMPLES)
		add_subdirectory("examples")
	endif()

	include(GNUInstallDirs)
	include(CMakePackageConfigHelpers)

	install(
		TARGETS 	raylib
		EXPORT 		raylibTargets
		FILE_SET 	raylibHeaders
	)

	install(
		EXPORT 				raylibTargets
		DESTINATION 	${CMAKE_INSTALL_LIBDIR}/cmake/raylib
	)

	write_basic_package_version_file(
			${CMAKE_CURRENT_BINARY_DIR}/raylibConfigVersion.cmake
			COMPATIBILITY ExactVersion
	)

	install(
			FILES 				cmake/raylibConfig.cmake
										${CMAKE_CURRENT_BINARY_DIR}/raylibConfigVersion.cmake
			DESTINATION 	${CMAKE_INSTALL_LIBDIR}/cmake/raylib
	)

	if (NOT TARGET uninstall)
		add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/Uninstall.cmake)
	endif()
endif()
