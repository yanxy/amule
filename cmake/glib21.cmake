# Recreation of our old glib check. Don't know what to do with it
# so leaving as is now. It's detected by nothin more.

INCLUDE (CheckFunctionExists)
INCLUDE (CheckIncludeFile)
INCLUDE (CheckIncludeFileCXX)

IF (BUILD_MONOLITHIC OR BUILD_DAEMON)
	CHECK_FUNCTION_EXISTS (fallocate HAVE_FALLOCATE)
	CHECK_FUNCTION_EXISTS (getrlimit HAVE_GETRLIMIT)
	CHECK_FUNCTION_EXISTS (setrlimit HAVE_SETRLIMIT)

	CHECK_INCLUDE_FILE (fcntl.h HAVE_FCNTL_H)
	CHECK_INCLUDE_FILE (sys/resource.h HAVE_SYS_RESOURCE_H)
	CHECK_INCLUDE_FILE(sys/statvfs.h HAVE_SYS_STATVFS_H)

	SET (TEST_APP "#include <features.h>
	#ifdef __GNU_LIBRARY__
		#if (__GLIBC__ == 2 && __GLIBC_MINOR__ >= 1) || (__GLIBC__ > 2)
			Lucky GNU user
		#endif
	#endif")

	EXECUTE_PROCESS (COMMAND echo ${TEST_APP}
		COMMAND ${CMAKE_C_COMPILER} -E -xc -
		OUTPUT_VARIABLE GLIB_TEST_OUTPUT
	)

	STRING(REGEX MATCH "Lucky GNU user" MATCH "${GLIB_TEST_OUTPUT}")

	IF (${MATCH})
		SET (__GLIBC__ TRUE)
		MESSAGE (STATUS "glibc -- found")
	ENDIF (${MATCH})

	TRY_RUN (posix_fallocate_run_result
		posix_fallocate_compile_result
		${CMAKE_CURRENT_SOURCE_DIR}
		${CMAKE_CURRENT_SOURCE_DIR}/cmake/glib21-posix-fallocate.c
	)

	IF (${posix_fallocate_run_result} EQUAL 0)
		SET (HAVE_POSIX_FALLOCATE TRUE)
		MESSAGE (STATUS "posix fallocate -- OK")
	ENDIF (${posix_fallocate_run_result} EQUAL 0)
ENDIF (BUILD_MONOLITHIC OR BUILD_DAEMON)

IF (BUILD_DAEMON)
	CHECK_INCLUDE_FILE(sys/select.h HAVE_SYS_SELECT_H)
	CHECK_INCLUDE_FILE(sys/time.h HAVE_SYS_TIME_H)
	CHECK_INCLUDE_FILE(sys/wait.h HAVE_SYS_WAIT_H)
	CHECK_INCLUDE_FILE(unistd.h HAVE_UNISTD_H)
ENDIF (BUILD_DAEMON)

IF (BUILD_DAEMON OR BUILD_WEBSERVER)
	CHECK_INCLUDE_FILE(sys/types.h HAVE_SYS_TYPES_H)
ENDIF (BUILD_DAEMON OR BUILD_WEBSERVER)

IF (BUILD_DAEMON OR BUILD_WEBSERVER OR NEED_LIB_MULECOMMON)
	INCLUDE (CheckTypeSize) #Sets also HAVE_SYS_TYPES_H, HAVE_STDINT_H, and HAVE_STDDEF_H
	CHECK_TYPE_SIZE (int INTSIZE)
ENDIF (BUILD_DAEMON OR BUILD_WEBSERVER OR NEED_LIB_MULECOMMON)

IF (NEED_LIB_MULEAPPCORE)
	CHECK_INCLUDE_FILE(errno.h HAVE_ERRNO_H)
	CHECK_INCLUDE_FILE(signal.h HAVE_SIGNAL_H)

	IF (ENABLE_MMAP)
		CHECK_INCLUDE_FILE(sys/mman.h HAVE_SYS_MMAN_H)

		IF (HAVE_SYS_MMAN_H)
			CHECK_FUNCTION_EXISTS (munmap HAVE_MUNMAP)

			IF (HAVE_MUNMAP)
				CHECK_FUNCTION_EXISTS (sysconf HAVE_SYSCONF)

				IF (HAVE_SYSCONF)
					SET (TEST_APP "#include <unistd.h>
						main ()
						{
							return sysconf(_SC_PAGESIZE)\;
						}"
					)

				        EXECUTE_PROCESS (COMMAND echo ${TEST_APP}
				                COMMAND ${CMAKE_C_COMPILER} -xc -
				                ERROR_VARIABLE SC_PAGESIZE_ERROR
				        )

					IF (SC_PAGESIZE_ERROR)
						MESSAGE (STATUS "_SC_PAGESIZE not defined, mmap support is disabled")
					ELSE (SC_PAGESIZE_ERROR)
						MESSAGE (STATUS "_SC_PAGESIZE found")
						SET (HAVE__SC_PAGESIZE TRUE)
					ENDIF (SC_PAGESIZE_ERROR)
				ELSE (HAVE_SYSCONF)
					MESSAGE (STATUS "sysconf function not fouind, mmap support is disabled")
				ENDIF (HAVE_SYSCONF)
			ELSE (HAVE_MUNMAP)
				MESSAGE (STATUS "munmap function not found, mmap support is disabled")
			ENDIF (HAVE_MUNMAP)
		ELSE (HAVE_SYS_MMAN_H)
			MESSAGE (STATUS "sys/mman.h wasn't found, mmap support is disabled")
		ENDIF (HAVE_SYS_MMAN_H)
	ENDIF (ENABLE_MMAP)
ENDIF (NEED_LIB_MULEAPPCORE)

IF (NEED_LIB_MULECOMMON)
	CHECK_INCLUDE_FILE_CXX(cxxabi.h HAVE_CXXABI)
	CHECK_INCLUDE_FILE(execinfo.h HAVE_EXECINFO)
	CHECK_INCLUDE_FILE(inttypes.h HAVE_INTTYPES_H)

	IF (HAVE_INTTYPES_H AND HAVE_SYS_TYPES_H)
	        SET (TEST_APP "#include <sys/types.h>
			#include <inttypes.h>")

	        EXECUTE_PROCESS (COMMAND echo ${TEST_APP}
        	        COMMAND ${CMAKE_C_COMPILER} -c -xc -
	                ERROR_VARIABLE INTTYPES_SYSTYPES_TEST_ERRORS
        	)

		IF (INTTYPES_SYSTYPES_TEST_ERRORS)
			SET (HAVE_INTTYPES_H FALSE)
		ELSE (INTTYPES_SYSTYPES_TEST_ERRORS)
			SET (TEST_APP "#include <sys/types.h>
                        #include <inttypes.h>
			uintmax_t i = (uintmax_t) -1\;")

	                EXECUTE_PROCESS (COMMAND echo ${TEST_APP}
        	                COMMAND ${CMAKE_C_COMPILER} -c -xc -
                	        ERROR_VARIABLE INTTYPES_SYSTYPES_UINTMAX_TEST_ERRORS
	                )

			IF (NOT INTTYPES_SYSTYPES_UINTMAX_TEST_ERRORS)
				SET (HAVE_INTTYPES_H_WITH_UINTMAX TRUE)
			ENDIF (NOT INTTYPES_SYSTYPES_UINTMAX_TEST_ERRORS)
		ENDIF (INTTYPES_SYSTYPES_TEST_ERRORS)		
	ENDIF (HAVE_INTTYPES_H AND HAVE_SYS_TYPES_H)

	IF (HAVE_INTTYPES_H)
		SET (TEST_APP "#include <inttypes.h>
			#ifdef PRId32
			char *p = PRId32\;
			#endif")

                EXECUTE_PROCESS (COMMAND echo ${TEST_APP}
       	                COMMAND ${CMAKE_C_COMPILER} -c -xc -
               	        ERROR_VARIABLE INTTYPES_BROKEN_PRI_TEST_ERRORS
                )

		IF (INTTYPES_BROKEN_PRI_TEST_ERRORS)
			SET (PRI_MACROS_BROKEN TRUE)
		ENDIF (INTTYPES_BROKEN_PRI_TEST_ERRORS)
	ENDIF (HAVE_INTTYPES_H)

	CHECK_FUNCTION_EXISTS (strerror_r HAVE_STRERROR_R)

	IF (HAVE_STRERROR_R)
		SET (TEST_APP "int main ()
			{
				char buf[100]\;
				char x = *strerror_r (0, buf, sizeof buf)\;
			}")

		EXECUTE_PROCESS (COMMAND echo ${TEST_APP}
			COMMAND ${CMAKE_C_COMPILER} -E -xc -
			OUTPUT_VARIABLE STR_ERROR_CHAR_P_OUTPUT
			ERROR_VARIABLE STR_ERROR_CHAR_P_TEST
                )

		IF (STR_ERROR_CHAR_P_TEST)
			SET (STRERROR_R_CHAR_P TRUE)
			MESSAGE (STATUS "strerror_r returns char*")
		ENDIF (STR_ERROR_CHAR_P_TEST)
	ENDIF (HAVE_STRERROR_R)
ENDIF (NEED_LIB_MULECOMMON)
