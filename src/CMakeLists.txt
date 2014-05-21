set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/pobject")
set (GETTEXT_PACKAGE "pobject")
set (CMAKE_C_FLAGS "-g -O3")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_definitions (${DEPS_CFLAGS})
add_definitions( ${MYSQL_CFLAGS} )
link_libraries ( ${DEPS_LIBRARIES} )
link_libraries ( ${MYSQL_LIBS} )
link_directories ( ${DEPS_LIBRARY_DIRS} )
find_package (Vala REQUIRED)
include( UseVala )

set( POBJECT_LIB_SOURCES pobject_core.vala pobject_object.vala pobject_selector.vala pobject_migration.vala )

set( POBJECT_SOURCES pobject.vala pobject_preprocessor.vala pobject_generator.vala Config.vala )

vala_precompile(POBJECT_LIB_VALA_C
  ${POBJECT_LIB_SOURCES}
PACKAGES
  ${VALA_PACKAGES}
GENERATE_VAPI
  ${POBJECT_NAME}
CUSTOM_VAPIS
  ${CUSTOM_VAPIS_LIST}
GENERATE_HEADER
  pobject
OPTIONS
--thread -g --vapidir=${CMAKE_INSTALL_PREFIX}/share/vala/vapi
)

add_library(
  ${POBJECT_NAME} SHARED
  ${POBJECT_LIB_VALA_C}
)

vala_precompile(POBJECT_VALA_C
  ${POBJECT_SOURCES}
PACKAGES
  ${VALA_PACKAGES}
CUSTOM_VAPIS
  ${CUSTOM_VAPIS_LIST} ${POBJECT_NAME}.vapi
OPTIONS
--thread -g --vapidir=${CMAKE_INSTALL_PREFIX}/share/vala/vapi
)

add_executable(
  pobject
  ${POBJECT_VALA_C}
)
target_link_libraries( pobject ${POBJECT_NAME} )

ADD_CUSTOM_TARGET( pobject_core_preprocessed DEPENDS pobject_core.vala )
ADD_CUSTOM_COMMAND(
  SOURCE src/pobject_core.vala
  OUTPUT src/pobject_core.vala
  COMMAND ${PREPROCESS_LOGGER} ${CMAKE_SOURCE_DIR}/src/ ../log/messages.mdb
)
ADD_DEPENDENCIES( ${POBJECT_NAME} pobject_core_preprocessed )

ADD_CUSTOM_TARGET( pobject_preprocessed DEPENDS pobject.vala )
ADD_CUSTOM_COMMAND(
  SOURCE src/pobject.vala
  OUTPUT src/pobject.vala
  COMMAND ${PREPROCESS_LOGGER} ${CMAKE_SOURCE_DIR}/src/ ../log/messages.mdb
)
ADD_DEPENDENCIES( pobject pobject_preprocessed )

# CREATE PKGCONFIG FILES
if(NOT DEFINED CMAKE_INSTALL_LIBDIR)
  set(CMAKE_INSTALL_LIBDIR lib)
endif(NOT DEFINED CMAKE_INSTALL_LIBDIR)
set(prefix       ${CMAKE_INSTALL_PREFIX})
set(exec_prefix ${CMAKE_INSTALL_PREFIX})
set(libdir       ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
set(includedir  ${CMAKE_INSTALL_PREFIX}/include)
set(LIBS         "")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/libpobject.pc.in
  ${CMAKE_CURRENT_BINARY_DIR}/${POBJECT_NAME}.pc @ONLY)

# Install pobject util
install(
TARGETS
  pobject
RUNTIME DESTINATION
  bin/
)

# Install shared object
install(
TARGETS
  ${POBJECT_NAME}
LIBRARY DESTINATION
  lib/
)

# Install header files
install(
FILES
  ${CMAKE_CURRENT_BINARY_DIR}/pobject.h
DESTINATION
  include/${POBJECT_NAME}/
)

# Install message database
install(
FILES
  ../log/messages.mdb
DESTINATION
  share/pobject/log/
)

# Install template files
install(
FILES
  pobject_template.vala
DESTINATION
  share/pobject/templates/
)

# Install vapi files
install(
FILES
  ${CMAKE_CURRENT_BINARY_DIR}/${POBJECT_NAME}.vapi
DESTINATION
  ${CMAKE_INSTALL_PREFIX}/share/vala/vapi/
)

# Install pkg-config file...
install( FILES
  ${CMAKE_CURRENT_BINARY_DIR}/${POBJECT_NAME}.pc
DESTINATION
  ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

if(HAVE_VALADOC)
  valadoc(pobject
    ${CMAKE_BINARY_DIR}/valadoc/pobject
    ${APP_SOURCES}
  PACKAGES
    ${VALA_PACKAGES}
  CUSTOM_VAPIS
    ${CUSTOM_VAPIS_LIST}
  )
  install(DIRECTORY
    ${CMAKE_BINARY_DIR}/valadoc
  DESTINATION
    share/doc/pobject
  )
endif()
