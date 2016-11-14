INCLUDE (CheckIncludeFile)
INCLUDE (CheckFunctionExists)
INCLUDE (FindPackageHandleStandardArgs)

MACRO (_ADD_LIBRARY_IF_EXISTS _LST _LIB)
	STRING (TOUPPER "${_LIB}" _LIBVAR)
	FIND_LIBRARY (${_LIBVAR}_LIB "${_LIB}")

	IF (${_LIBVAR}_LIB)
		LIST (APPEND ${_LST} ${${_LIBVAR}_LIB})
	ENDIF (${_LIBVAR}_LIB)

	UNSET (${_LIBVAR}_LIB CACHE)
ENDMACRO (_ADD_LIBRARY_IF_EXISTS)

# Modified version of the library CHECK_FUNCTION_EXISTS
# This version will not produce any output, and the result variable is only
# set when the function is found
MACRO (_CHECK_FUNCTION_EXISTS FUNCTION VARIABLE)
	UNSET (_RESULT_VAR)
	TRY_COMPILE (_RESULT_VAR
		${CMAKE_BINARY_DIR}
		${CMAKE_ROOT}/Modules/CheckFunctionExists.c
		CMAKE_FLAGS -DCOMPILE_DEFINITIONS:STRING="-DCHECK_FUNCTION_EXISTS=${FUNCTION}"
			"-DLINK_LIBRARIES:STRING=${CMAKE_REQUIRED_LIBRARIES}"
		OUTPUT_VARIABLE OUTPUT)

	IF (_RESULT_VAR)
		SET (${VARIABLE} 1 CACHE INTERNAL "Have function ${FUNCTION}")
		FILE (APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
			"Determining if the function ${FUNCTION} exists passed with the following output:\n${OUTPUT}\n\n")
	ELSE (_RESULT_VAR)
		FILE (APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
			"Determining if the function ${FUNCTION} exists failed with the following output:\n${OUTPUT}\n\n")
	ENDIF (_RESULT_VAR)
ENDMACRO (_CHECK_FUNCTION_EXISTS)

IF ("HAVE_LIBREADLINE" MATCHES "^HAVE_LIBREADLINE$")
	FOREACH (_maybe_readline_lib "readline" "edit" "editline")
		_ADD_LIBRARY_IF_EXISTS (_readline_libs ${_maybe_readline_lib})
	ENDFOREACH (_maybe_readline_lib)

	FOREACH (_maybe_termcap_lib "termcap" "curses" "ncurses")
		_ADD_LIBRARY_IF_EXISTS (_termcap_libs ${_maybe_termcap_lib})
	ENDFOREACH (_maybe_termcap_lib)

	MESSAGE (STATUS "Looking for readline")

	FOREACH (_readline_lib IN LISTS _readline_libs)
		SET (CMAKE_REQUIRED_LIBRARIES "${_readline_lib}")
		_CHECK_FUNCTION_EXISTS (readline HAVE_LIBREADLINE)

		IF (HAVE_LIBREADLINE)
			BREAK()
		ENDIF (HAVE_LIBREADLINE)

		FOREACH (_termcap_lib IN LISTS _termcap_libs)
			SET (CMAKE_REQUIRED_LIBRARIES "${_readline_lib}" "${_termcap_lib}")
			_CHECK_FUNCTION_EXISTS (readline HAVE_LIBREADLINE)

			IF (HAVE_LIBREADLINE)
				BREAK()
			ENDIF (HAVE_LIBREADLINE)
		ENDFOREACH (_termcap_lib)

		IF (HAVE_LIBREADLINE)
			BREAK()
		ENDIF (HAVE_LIBREADLINE)
	ENDFOREACH (_readline_lib)

	IF (HAVE_LIBREADLINE)
		MESSAGE (STATUS "Looking for readline - found")
	ELSE (HAVE_LIBREADLINE)
		MESSAGE (STATUS "Looking for readline - not found")
	ENDIF (HAVE_LIBREADLINE)
ENDIF ("HAVE_LIBREADLINE" MATCHES "^HAVE_LIBREADLINE$")

IF (HAVE_LIBREADLINE)
	SET (READLINE_LIBRARIES "${CMAKE_REQUIRED_LIBRARIES}" CACHE STRING "Required link libraries for the readline library")
	CHECK_FUNCTION_EXISTS (add_history HAVE_READLINE_HISTORY)
	SET (CMAKE_REQUIRED_LIBRARIES "")
ENDIF (HAVE_LIBREADLINE)

CHECK_INCLUDE_FILE (stdio.h HAVE_STDIO_H)

# Stripped down and output modified version of the library CHECK_INCLUDE_FILES
MACRO (_CHECK_INCLUDE_FILES INCLUDE VARIABLE)
	IF ("${VARIABLE}" MATCHES "^${VARIABLE}$")
		SET (CMAKE_CONFIGURABLE_FILE_CONTENT "/* */\n")

		FOREACH (FILE ${INCLUDE})
			SET (CMAKE_CONFIGURABLE_FILE_CONTENT "${CMAKE_CONFIGURABLE_FILE_CONTENT}#include <${FILE}>\n")
			SET (_LAST_INCLUDE "${FILE}")
		ENDFOREACH (FILE)

		SET (CMAKE_CONFIGURABLE_FILE_CONTENT "${CMAKE_CONFIGURABLE_FILE_CONTENT}\n\nint main(){return 0;}\n")
		CONFIGURE_FILE ("${CMAKE_ROOT}/Modules/CMakeConfigurableFile.in"
			"${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/CheckIncludeFiles.c" @ONLY IMMEDIATE)
		MESSAGE (STATUS "Looking for ${_LAST_INCLUDE}")
		TRY_COMPILE (${VARIABLE}
			${CMAKE_BINARY_DIR}
			${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/CheckIncludeFiles.c
			OUTPUT_VARIABLE OUTPUT)

		IF (${VARIABLE})
			MESSAGE (STATUS "Looking for ${_LAST_INCLUDE} - found")
			SET (${VARIABLE} 1 CACHE INTERNAL "Have ${_LAST_INCLUDE}")
			FILE (APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
				"Determining if ${_LAST_INCLUDE} exist passed with the following output:\n${OUTPUT}\n\n")
		ELSE (${VARIABLE})
			MESSAGE (STATUS "Looking for ${_LAST_INCLUDE} - not found.")
			SET (${VARIABLE} 0 CACHE INTERNAL "Have ${_LAST_INCLUDE}")
			FILE (APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
				"Determining if ${_LAST_INCLUDE} exist failed with the following output:\n${OUTPUT}\n"
				"Source:\n${CMAKE_CONFIGURABLE_FILE_CONTENT}\n")
		ENDIF (${VARIABLE})
	ENDIF ("${VARIABLE}" MATCHES "^${VARIABLE}$")
ENDMACRO (_CHECK_INCLUDE_FILES)

IF (HAVE_STDIO_H)
	_CHECK_INCLUDE_FILES ("stdio.h;readline.h" HAVE_READLINE_H)
	IF (HAVE_READLINE_H)
		_CHECK_INCLUDE_FILES ("stdio.h;readline.h;history.h" HAVE_HISTORY_H)
	ELSE (HAVE_READLINE_H)
		_CHECK_INCLUDE_FILES ("stdio.h;readline/readline.h" HAVE_READLINE_READLINE_H)
		IF (HAVE_READLINE_READLINE_H)
			_CHECK_INCLUDE_FILES ("stdio.h;readline/readline.h;readline/history.h" HAVE_READLINE_HISTORY_H)
			IF (NOT HAVE_READLINE_HISTORY_H)
				_CHECK_INCLUDE_FILES ("stdio.h;readline/readline.h;history.h" HAVE_HISTORY_H)
			ENDIF (NOT HAVE_READLINE_HISTORY_H)
		ENDIF (HAVE_READLINE_READLINE_H)
	ENDIF (HAVE_READLINE_H)
ENDIF (HAVE_STDIO_H)

FIND_PACKAGE_HANDLE_STANDARD_ARGS (readline DEFAULT_MSG READLINE_LIBRARIES)
