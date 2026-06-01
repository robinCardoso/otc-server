# Locate Crypto++ library
# This module defines
#   Crypto++_FOUND
#   Crypto++_INCLUDE_DIR
#   Crypto++_LIBRARIES

find_path(Crypto++_INCLUDE_DIR NAMES cryptopp/cryptlib.h
    PATHS "C:/msys64/mingw64/include" "C:/msys64/ucrt64/include")
find_library(Crypto++_LIBRARIES NAMES cryptopp libcryptopp
    PATHS "C:/msys64/mingw64/lib" "C:/msys64/ucrt64/lib")

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Crypto++ DEFAULT_MSG Crypto++_INCLUDE_DIR Crypto++_LIBRARIES)

mark_as_advanced(Crypto++_INCLUDE_DIR Crypto++_LIBRARIES)
