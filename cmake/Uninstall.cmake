set(MANIFEST "${CMAKE_BINARY_DIR}/install_manifest.txt")

if(NOT EXISTS ${MANIFEST})
	message(FATAL_ERROR "Cannot find install manifest: ${MANIFEST}")
endif()

message(STATUS "============== Uninstalling raylib ===================")
file(string ${MANIFEST} files)
foreach(file ${files})
	if(NOT EXISTS ${files})
		message(STATUS "File '${file}' in manifest does not exist")
		continue()
	endif()

	message(STATUS "Removing ${file}")

	execute_process(
			COMMAND ${CMAKE_COMMAND} -E remove ${file}
			OUTPUT_VARIABLE rm_out
			RESULT_VARIABLE rm_retval
		)

	if(NOT "${rm_retval}" STREQUAL 0)
		message(FATAL_ERROR "Failed to remove ${file}")
	endif()
endforeach()
message(STATUS "============== Uninstalled raylib ===================")
