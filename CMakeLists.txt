cmake_minimum_required(VERSION 3.26.0)
project(
	raylib
	VERSION 6.0.0
	LANGUAGES C
	DESCRIPTION "A simple and easy-to-use library to enjoy videogames programming"
	HOMEPAGE_URL "https://www.raylib.com"
)

include(CMakeDependentOption)
# PLATFORM_DESKTOP_GLFW
# PLATFORM_DESKTOP_SDL
# PLATFORM_DESKTOP_RGFW
# PLATFORM_DESKTOP_WIN32
# PLATFORM_WEB
# PLATFORM_WEB_RGFW
# PLATFORM_DRM
# PLATFORM_ANDROID
# PLATFORM_MEMORY
set(RAYLIB_PLATFORM "PLATFORM_DESKTOP_GLFW" CACHE STRING "raylib target platform")


# GRAPHICS_API_OPENGL_33
# GRAPHICS_API_OPENGL_SOFTWARE
# GRAPHICS_API_OPENGL_11
# GRAPHICS_API_OPENGL_21
# GRAPHICS_API_OPENGL_43
# GRAPHICS_API_OPENGL_ES2
# GRAPHICS_API_OPENGL_ES3
set(RAYLIB_GRAPHICS "DEFAULT" CACHE STRING "raylib graphics API")
set(RAYLIB_CONFIG_FLAGS "" CACHE STRING "Define external config flags. It will override config.h flags with the provided ones, if NONE, default config.h flags are used")  

option(RAYLIB_BUILD_SHARED_LIBS "Building raylib as a SHARED library" OFF)
option(RAYLIB_MODULE_AUDIO "Include audio module" ON)
option(RAYLIB_MODULE_MODELS "Include models module" ON)

option(RAYLIB_USE_EXTERNAL_GLFW "Use external GLFW library instead of rglfw module" OFF)
cmake_dependent_option(RAYLIB_GLFW_LINUX_ENABLE_WAYLAND
	"Build support for Wayland on Linux for GLFW" ON "UNIX;NOT APPLE" OFF
)
cmake_dependent_option(RAYLIB_GLFW_LINUX_ENABLE_X11
	"Build support for X11 on Linux for GLFW" ON "UNIX;NOT APPLE" OFF
)

cmake_dependent_option(RAYLIB_RGFW_LINUX_ENABLE_WAYLAND
  "Build support for Wayland on Linux for RGFW" ON "UNIX;NOT APPLE" OFF
)
cmake_dependent_option(RAYLIB_RGFW_LINUX_ENABLE_X11
  "Build support for X11 on Linux for RGFW" ON "UNIX;NOT APPLE" OFF
)


option(RAYLIB_FETCH_BACKEND "Fetch current backend from github (only for GLFW and SDL3)" OFF)

cmake_dependent_option(RAYLIB_BUILD_EXAMPLES
	"Build examples (only when raylib is top level)" ON "PROJECT_IS_TOP_LEVEL" OFF
)

if (RAYLIB_BUILD_SHARED_LIBS)
	add_library(raylib SHARED)
else()
	add_library(raylib STATIC)
endif()

function(gen_wayland)
  set(wl_gen_headers "")
  set(wl_gen_srcs "")

  find_program(WAYLAND_SCANNER wayland-scanner REQUIRED)
  function(wl_generate protocol)
    set(gen_header  "src/${protocol}-client-protocol.h")
    set(gen_src     "src/${protocol}-client-protocol.c")
    set(src_xml     "src/external/glfw/deps/wayland/${protocol}.xml")

    list(APPEND wl_gen_headers ${gen_header})
    list(APPEND wl_gen_srcs ${gen_src})
    add_custom_command(
      OUTPUT ${gen_header} ${gen_src}
      COMMAND ${WAYLAND_SCANNER} client-header ${src_xml} ${gen_header}
      COMMAND ${WAYLAND_SCANNER} private-code  ${src_xml} ${gen_src}
      DEPENDS ${protocol}
      VERBATIM
    )
  endfunction()

  wl_generate(wayland)
  wl_generate(xdg-shell)
  wl_generate(xdg-decoration-unstable-v1)
  wl_generate(viewporter)
  wl_generate(relative-pointer-unstable-v1)
  wl_generate(pointer-constraints-unstable-v1)
  wl_generate(fractional-scale-v1)
  wl_generate(xdg-activation-v1)
  wl_generate(idle-inhibit-unstable-v1)

  target_sources(raylib
    PRIVATE 			${wl_gen_srcs}
    PRIVATE
      FILE_SET 		waylandHeaders
      TYPE				HEADERS
      BASE_DIRS 	src
      FILES  			${wl_gen_headers}
  )
endfunction()

if (RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_GLFW")
	if (RAYLIB_GRAPHICS STREQUAL "DEFAULT")
		set(RAYLIB_GRAPHICS "GRAPHICS_API_OPENGL_33")
	endif()

	if (RAYLIB_USE_EXTERNAL_GLFW)
    set(GLFW_BUILD_WAYLAND ${RAYLIB_GLFW_LINUX_ENABLE_WAYLAND})
    set(GLFW_BUILD_X11 ${RAYLIB_GLFW_LINUX_ENABLE_X11})
		if (RAYLIB_FETCH_BACKEND)
			include(FetchContent)
			set(GLFW_STANDALONE OFF)
			set(GLFW_BUILD_DOCS OFF)
			set(GLFW_INSTALL OFF)
			set(GLFW_LIBRARY_TYPE "STATIC")
			FetchContent_Declare(glfw
				GIT_REPOSITORY "https://github.com/glfw/glfw.git"
				GIT_TAG "3.4"
        GIT_SHALLOW ON
        GIT_PROGRESS ON
				OVERRIDE_FIND_PACKAGE
				EXCLUDE_FROM_ALL
			)
		endif()

		find_package(glfw REQUIRED)
		target_link_libraries(raylib PRIVATE $<BUILD_LOCAL_INTERFACE:glfw>)
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
		set_source_files_properties(src/rglfw.c PROPERTIES COMPILE_OPTIONS "-U_GNU_SOURCE")

		if (APPLE)
			target_link_libraries(raylib PRIVATE
				"-framework Cocoa"
				"-framework IOKit"
				"-framework CoreFoundation"
				"-framework QuartzCore"
			)
			set_source_files_properties(src/rglfw.c PROPERTIES COMPILE_OPTIONS "-xobjective-c")
		endif()
	endif()


  if (RAYLIB_GLFW_LINUX_ENABLE_X11)
    target_compile_definitions(raylib PRIVATE _GLFW_X11)
  endif()

  if (RAYLIB_GLFW_LINUX_ENABLE_WAYLAND)
    target_compile_definitions(raylib PRIVATE _GLFW_WAYLAND)
    gen_wayland()
	endif()

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_SDL")
	if (RAYLIB_GRAPHICS STREQUAL "DEFAULT")
		set(RAYLIB_GRAPHICS "GRAPHICS_API_OPENGL_33")
	endif()

	if (RAYLIB_FETCH_BACKEND)
		include(FetchContent)
		set(SDL_TEST_LIBRARY OFF)
		set(SDL_SHARED OFF)
		set(SDL_STATIC ON)
		FetchContent_Declare(SDL3
			GIT_REPOSITORY "https://github.com/libsdl-org/SDL.git"
			GIT_TAG "release-3.4.x"
			GIT_SHALLOW ON
			GIT_PROGRESS ON
			OVERRIDE_FIND_PACKAGE
			EXCLUDE_FROM_ALL
		)
	endif()

	find_package(SDL3 QUIET)
	if(${SDL3_FOUND})
		target_link_libraries(raylib PRIVATE $<BUILD_LOCAL_INTERFACE:SDL3::SDL3>)
		target_compile_definitions(raylib PRIVATE USING_SDL3_PROJECT)
	else()
		find_package(SDL2 REQUIRED)
		target_link_libraries(raylib PRIVATE $<BUILD_LOCAL_INTERFACE:SDL2::SDL2>)
		target_compile_definitions(raylib PRIVATE USING_SDL2_PROJECT)
	endif()

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_RGFW")
	if (RAYLIB_GRAPHICS STREQUAL "DEFAULT")
    set(RAYLIB_GRAPHICS "GRAPHICS_API_OPENGL_33")
	endif()

  if (RAYLIB_RGFW_LINUX_ENABLE_X11)
    target_compile_definitions(raylib PRIVATE RGFW_X11 RGFW_UNIX)
  endif()

  if (RAYLIB_RGFW_LINUX_ENABLE_WAYLAND)
    target_compile_definitions(raylib PRIVATE RGFW_WAYLAND EGLAPIENTRY)
    gen_wayland()
	endif()

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_WIN32")
	if (RAYLIB_GRAPHICS STREQUAL "DEFAULT")
		set(RAYLIB_GRAPHICS "GRAPHICS_API_OPENGL_33")
	endif()

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_WEB" OR 
        RAYLIB_PLATFORM STREQUAL "PLATFORM_WEB_RGFW")

  if (RAYLIB_PLATFORM STREQUAL "PLATFORM_WEB_RGFW" AND 
      RAYLIB_GRAPHICS STREQUAL "GRAPHICS_API_OPENGL_SOFTWARE")
    message(FATAL_ERROR "PLATFORM_WEB_RGFW: Software rendering not supported!")
	endif()

	if (RAYLIB_GRAPHICS STREQUAL "DEFAULT")
		set(RAYLIB_GRAPHICS "GRAPHICS_API_OPENGL_ES2")
	endif()
	target_compile_definitions(raylib PRIVATE _DEFAULT_SOURCE)
	target_link_options(raylib INTERFACE "-sASYNCIFY")
	if (RAYLIB_PLATFORM STREQUAL "PLATFORM_WEB")
		target_link_options(raylib INTERFACE "-sUSE_GLFW=3")
	endif()

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_DRM")
	if (RAYLIB_GRAPHICS STREQUAL "DEFAULT")
		set(RAYLIB_GRAPHICS "GRAPHICS_API_OPENGL_ES2")
	endif()

  target_compile_definitions(raylib PRIVATE EGL_NO_X11)

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_ANDROID")
	if (RAYLIB_GRAPHICS STREQUAL "DEFAULT")
		set(RAYLIB_GRAPHICS "GRAPHICS_API_OPENGL_ES2")
	endif()

	target_compile_definitions(raylib PRIVATE 
    __ANDROID__
    __ANDROID_API__=${CMAKE_SYSTEM_VERSION}
  )
  target_link_options(raylib PRIVATE
    "-ffunction-sections"
    "-funwind-tables"
    "-fstack-protector-strong"
    "-fPIE"
    "-fPIC"
  )

elseif (RAYLIB_PLATFORM STREQUAL "PLATFORM_MEMORY")
	if (RAYLIB_GRAPHICS STREQUAL "DEFAULT")
		set(RAYLIB_GRAPHICS "GRAPHICS_API_OPENGL_SOFTWARE")
	endif()

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
		${RAYLIB_GRAPHICS}

	PRIVATE
		_GNU_SOURCE
		$<$<PLATFORM_ID:Windows>:UNICODE>
		$<$<PLATFORM_ID:Linux>:_DEFAULT_SOURCE>
		$<$<CONFIG:DEBUG>:_DEBUG>
		$<$<BOOL:${RAYLIB_BUILD_SHARED_LIBS}>:BUILD_LIBTYPE_SHARED>
)
if (NOT RAYLIB_CONFIG_FLAGS STREQUAL "")
  separate_arguments(config_flags NATIVE_COMMAND ${RAYLIB_CONFIG_FLAGS})
  target_compile_definitions(raylib PRIVATE EXTERNAL_CONFIG_FLAGS ${config_flags})
endif()

target_link_options(raylib PRIVATE $<$<PLATFORM_ID:Linux>:"-fPIC">)
if (RAYLIB_BUILD_SHARED_LIBS)
  target_link_options(raylib PRIVATE "-fPIC")
  if (UNIX)
    target_link_options(raylib PRIVATE "-fvisibility=hidden")
  endif()
endif()

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
