# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "AsmrSiteServer_autogen"
  "CMakeFiles\\AsmrSiteServer_autogen.dir\\AutogenUsed.txt"
  "CMakeFiles\\AsmrSiteServer_autogen.dir\\ParseCache.txt"
  )
endif()
