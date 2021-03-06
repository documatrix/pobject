set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/pobject")
set (GETTEXT_PACKAGE "pobject")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_definitions (${DEPS_CFLAGS})
add_definitions( ${MYSQL_CFLAGS} )
include_directories( ${CMAKE_SOURCE_DIR}/src )
link_libraries ( ${DEPS_LIBRARIES} )
link_libraries ( ${POBJECT_NAME} )
link_libraries ( ${MYSQL_LIBS} )
link_directories ( ${DEPS_LIBRARY_DIRS} )
find_package (Vala REQUIRED)
include( UseVala )

set (TEST_POBJECT_SOURCES ${TEST_POBJECT_SOURCES} test_pobject.vala)

vala_precompile(TEST_POBJECT_VALA_C
  ${TEST_POBJECT_SOURCES}
PACKAGES
  ${VALA_PACKAGES} ${POBJECT_NAME}
OPTIONS
--thread --vapidir=${CMAKE_SOURCE_DIR}/src --vapidir=${CMAKE_INSTALL_PREFIX}/share/vala/vapi
CUSTOM_VAPIS
  ${CUSTOM_VAPIS_LIST}
)

add_executable(
  test_pobject
  ${TEST_POBJECT_VALA_C}
)

install(TARGETS
  test_pobject
RUNTIME DESTINATION
  bin/
)

ADD_CUSTOM_TARGET( test_pobject_preprocessed DEPENDS test_pobject.vala )
ADD_CUSTOM_COMMAND(
  SOURCE tests/test_pobject.vala
  OUTPUT tests/test_pobject.vala
  COMMAND ${PREPROCESS_LOGGER} ${CMAKE_SOURCE_DIR}/tests/ ../log/messages.mdb
  COMMAND ../src/pobject --template-path=../src/ -l -m ../log/messages.mdb preprocess ${CMAKE_SOURCE_DIR}/tests/
)
ADD_DEPENDENCIES( test_pobject test_pobject_preprocessed )

#ADD_CUSTOM_TARGET( test_pobject_pobject_preprocessed DEPENDS test_pobject_preprocessed )
#ADD_CUSTOM_COMMAND(
#  SOURCE tests/test_pobject.vala
#  OUTPUT tests/test_pobject.vala
#  COMMAND src/pobject --template-dir=src/ preprocess ${CMAKE_SOURCE_DIR}/tests/
#)
#ADD_DEPENDENCIES( test_pobject test_pobject_pobject_preprocessed )

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
