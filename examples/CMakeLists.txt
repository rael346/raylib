project(raylib_examples)

set(EXAMPLE_DIRS
	"audio"
	"core"
	"models"
	"others"
	"shaders"
	"shapes"
	"text"
	"textures"
)

foreach (DIR ${EXAMPLE_DIRS})
	file(GLOB RESOURCES ${DIR}/resources/*)
	file(COPY ${RESOURCES} DESTINATION "resources/")

	file(GLOB SOURCES ${DIR}/*.c)
	foreach (SRC ${SOURCES})
		get_filename_component(EXAMPLE_NAME ${SRC} NAME_WE)
		if (EXAMPLE_NAME STREQUAL "rlgl_standalone" OR
				EXAMPLE_NAME STREQUAL "raylib_opengl_interop")
			continue()
		endif()

		add_executable(${EXAMPLE_NAME} ${SRC})
		target_link_libraries(${EXAMPLE_NAME} raylib)

		if (RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_RGFW" AND APPLE)
			target_link_libraries(${EXAMPLE_NAME}
				"-framework Cocoa"
				"-framework IOKit"
			)
		endif()

		if (RAYLIB_PLATFORM STREQUAL "PLATFORM_WEB" OR RAYLIB_PLATFORM STREQUAL "PLATFORM_WEB_RGFW")
			set_target_properties(${EXAMPLE_NAME} PROPERTIES SUFFIX ".html")
			target_link_options(${EXAMPLE_NAME} PRIVATE "SHELL:--preload-file resources")
		endif()
	endforeach()
endforeach ()

if (RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_GLFW")
	add_executable(rlgl_standalone "others/rlgl_standalone.c")
	target_link_libraries(rlgl_standalone raylib)

	if (RAYLIB_USE_EXTERNAL_GLFW)
		target_link_libraries(rlgl_standalone glfw)
	else()
		target_sources(rlgl_standalone
			PRIVATE 			../src/rglfw.c
			PRIVATE
				FILE_SET 		glfwHeaders
				TYPE				HEADERS
				BASE_DIRS 	../src/external/glfw/include
				FILES  			../src/external/glfw/include/GLFW/glfw3.h
										../src/external/glfw/include/GLFW/glfw3native.h
		)
		target_link_libraries(rlgl_standalone
			"-framework Cocoa"
			"-framework IOKit"
			"-framework CoreFoundation"
			"-framework QuartzCore"
		)
		set_source_files_properties(../src/rglfw.c PROPERTIES COMPILE_OPTIONS "-U_GNU_SOURCE")
		if (APPLE)
			set_source_files_properties(../src/rglfw.c PROPERTIES COMPILE_OPTIONS "-xobjective-c")
		endif()
	endif()
endif()

if (RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_GLFW" OR
		RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_SDL" OR
		RAYLIB_PLATFORM STREQUAL "PLATFORM_DESKTOP_RGFW")
	add_executable(raylib_opengl_interop "others/raylib_opengl_interop.c")
	target_link_libraries(raylib_opengl_interop raylib)

	if (APPLE)
		target_link_libraries(raylib_opengl_interop
			"-framework OpenGL"
			"-framework Cocoa"
			"-framework IOKit"
			"-framework CoreFoundation"
			"-framework QuartzCore"
		)
	endif()
endif()
