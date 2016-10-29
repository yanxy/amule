IF (CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES)
	FIND_PATH (CRYPTOPP_INCLUDE_PREFIX cryptlib.h
		PATHS ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES}/*/
	)
ENDIF (CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES)

STRING (REGEX REPLACE "/usr/include/" "" CRYPTOPP_INCLUDE_DIRS "${CRYPTOPP_INCLUDE_PREFIX}")

MESSAGE (STATUS "Found cryptlib.h in ${CRYPTOPP_INCLUDE_DIRS}")

IF (CRYPTOPP_INCLUDE_DIRS)
	FIND_LIBRARY (CRYPTOPP crypto++)

	IF (NOT CRYPTOPP)
		FIND_LIBRARY (CRYPTOPP cryptopp)
	ENDIF (NOT CRYPTOPP)

ENDIF (CRYPTOPP_INCLUDE_DIRS)

MESSAGE (STATUS "Found libcrypto++ in ${CRYPTOPP}")
FILE (STRINGS ${CRYPTOPP_INCLUDE_PREFIX}/config.h CRYPTTEST_OUTPUT REGEX "define CRYPTOPP_VERSION")
STRING(REGEX REPLACE "#define CRYPTOPP_VERSION " "" CRYPTOPP_VERSION "${CRYPTTEST_OUTPUT}")
STRING(REGEX REPLACE "([0-9])([0-9])([0-9])" "\\1.\\2.\\3" CRYPTOPP_VERSION "${CRYPTOPP_VERSION}")


IF (${CRYPTOPP_VERSION} VERSION_LESS ${MIN_CRYPTOPP_VERSION})
	MESSAGE (FATAL_ERROR "crypto++ version ${CRYPTOPP_VERSION} is too old")
ELSE (${CRYPTOPP_VERSION} VERSION_LESS ${MIN_CRYPTOPP_VERSION})
	MESSAGE (STATUS "crypto++ version ${CRYPTOPP_VERSION} -- OK")

	IF (${CRYPTOPP_VERSION} VERSION_GREATER 5.5.0)
		MESSAGE (STATUS "Enabling usage of weak algo's for crypto")
		SET (__WEAK_CRYPTO__ TRUE)
	ENDIF (${CRYPTOPP_VERSION} VERSION_GREATER 5.5.0)
ENDIF (${CRYPTOPP_VERSION} VERSION_LESS ${MIN_CRYPTOPP_VERSION})
