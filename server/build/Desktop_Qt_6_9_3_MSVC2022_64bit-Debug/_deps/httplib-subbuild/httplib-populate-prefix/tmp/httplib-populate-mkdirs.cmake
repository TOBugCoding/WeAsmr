# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "E:/QT_projct/WeAsmrPlayer_gay/server/build/Desktop_Qt_6_9_3_MSVC2022_64bit-Debug/_deps/httplib-src"
  "E:/QT_projct/WeAsmrPlayer_gay/server/build/Desktop_Qt_6_9_3_MSVC2022_64bit-Debug/_deps/httplib-build"
  "E:/QT_projct/WeAsmrPlayer_gay/server/build/Desktop_Qt_6_9_3_MSVC2022_64bit-Debug/_deps/httplib-subbuild/httplib-populate-prefix"
  "E:/QT_projct/WeAsmrPlayer_gay/server/build/Desktop_Qt_6_9_3_MSVC2022_64bit-Debug/_deps/httplib-subbuild/httplib-populate-prefix/tmp"
  "E:/QT_projct/WeAsmrPlayer_gay/server/build/Desktop_Qt_6_9_3_MSVC2022_64bit-Debug/_deps/httplib-subbuild/httplib-populate-prefix/src/httplib-populate-stamp"
  "E:/QT_projct/WeAsmrPlayer_gay/server/build/Desktop_Qt_6_9_3_MSVC2022_64bit-Debug/_deps/httplib-subbuild/httplib-populate-prefix/src"
  "E:/QT_projct/WeAsmrPlayer_gay/server/build/Desktop_Qt_6_9_3_MSVC2022_64bit-Debug/_deps/httplib-subbuild/httplib-populate-prefix/src/httplib-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "E:/QT_projct/WeAsmrPlayer_gay/server/build/Desktop_Qt_6_9_3_MSVC2022_64bit-Debug/_deps/httplib-subbuild/httplib-populate-prefix/src/httplib-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "E:/QT_projct/WeAsmrPlayer_gay/server/build/Desktop_Qt_6_9_3_MSVC2022_64bit-Debug/_deps/httplib-subbuild/httplib-populate-prefix/src/httplib-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
