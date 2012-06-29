MACRO(QT4_AUTO_WRAP outfiles)
    FOREACH(fileName ${ARGN})
        IF(fileName MATCHES "\\.h$")
            FILE(STRINGS ${fileName} lines REGEX Q_OBJECT)
            IF(lines)
                SET(moc_headers ${moc_headers} ${fileName})
                #MESSAGE(STATUS "moc: ${fileName}")
            ENDIF()
        ENDIF()
        IF(fileName MATCHES "\\.ui$")
            SET(ui_files ${ui_files} ${fileName})
            #MESSAGE(STATUS "uic: ${fileName}")
        ENDIF()
        IF(fileName MATCHES "\\.qrc$")
            SET(qrc_files ${qrc_files} ${fileName})
            #MESSAGE(STATUS "qrc: ${fileName}")
        ENDIF()
    ENDFOREACH()
    QT4_WRAP_CPP(${outfiles} ${moc_headers})
    QT4_WRAP_UI(${outfiles} ${ui_files})
    QT4_ADD_RESOURCES(${outfiles} ${qrc_files})
ENDMACRO()


MACRO(SOURCE_GROUP_BY_PATH)
    FOREACH(filename ${ARGV})
        GET_FILENAME_COMPONENT(path "${filename}" REALPATH)
        FILE(RELATIVE_PATH path ${PROJECT_SOURCE_DIR} ${path})
        GET_FILENAME_COMPONENT(path "${path}" PATH)
        string(REPLACE "/" "\\" path "${path}")
        IF(${filename} MATCHES "ui_|cxx$")
            SOURCE_GROUP("generated" FILES ${filename})
        ELSEIF(${filename} MATCHES "h$|hpp$|cpp$|c$|cu$|ui$|qrc$")
            SOURCE_GROUP("${path}" FILES ${filename})
        ENDIF()
    ENDFOREACH()
ENDMACRO(SOURCE_GROUP_BY_PATH)


MACRO(DEPLOY_QT_CUDA target)
    IF(WIN32)
        INSTALL(CODE "
            file(WRITE \"\${CMAKE_INSTALL_PREFIX}/qt.conf\" \"\")
            include(BundleUtilities)
            fixup_bundle(\"\${CMAKE_INSTALL_PREFIX}/${target}.exe\" \"\" \"\")
            " COMPONENT Runtime)
    ELSEIF(APPLE)
        INSTALL(CODE "
            file(WRITE \"\${CMAKE_INSTALL_PREFIX}/${target}.app/Contents/Resources/qt.conf\" \"\")
            include(BundleUtilities)
            function(gp_resolve_item_override context item exepath dirs resolved_item_var resolved_var)
                IF (\${item} STREQUAL \"@rpath/libcudart.dylib\")
                    #message(\"RI: \${item} \${\${resolved_item_var}} \${\${resolved_var}}\")
                    set(\${resolved_item_var} \"/usr/local/cuda/lib/libcudart.dylib\" PARENT_SCOPE)
                    set(\${resolved_var} 1 PARENT_SCOPE)
                ENDIF()
                IF (\${item} STREQUAL \"@rpath/libcurand.dylib\")
                    #message(\"RI: \${item} \${\${resolved_item_var}} \${\${resolved_var}}\")
                    set(\${resolved_item_var} \"/usr/local/cuda/lib/libcurand.dylib\" PARENT_SCOPE)
                    set(\${resolved_var} 1 PARENT_SCOPE)
                ENDIF()
                IF (\${item} STREQUAL \"@rpath/libnpp.dylib\")
                    #message(\"RI: \${item} \${\${resolved_item_var}} \${\${resolved_var}}\")
                    set(\${resolved_item_var} \"/usr/local/cuda/lib/libnpp.dylib\" PARENT_SCOPE)
                    set(\${resolved_var} 1 PARENT_SCOPE)
                ENDIF()
                IF (\${item} STREQUAL \"@rpath/libtlshook.dylib\")
                    #message(\"RI: \${item} \${\${resolved_item_var}} \${\${resolved_var}}\")
                    set(\${resolved_item_var} \"/usr/local/cuda/lib/libtlshook.dylib\" PARENT_SCOPE)
                    set(\${resolved_var} 1 PARENT_SCOPE)
                ENDIF()
            endfunction()
            function(gp_resolved_file_type_override file type_var)
                IF(\${file} MATCHES \"(CUDA.framework|libcuda.dylib)\")
                    #message(\"GP: \${file} \${\${type_var}}\")
                    set(\${type_var} \"system\" PARENT_SCOPE)
                ENDIF()
            endfunction()
            fixup_bundle(\"\${CMAKE_INSTALL_PREFIX}/${target}.app\" \"\" \"\")
            " COMPONENT Runtime)
    ENDIF()
ENDMACRO()


IF(WIN32)
    OPTION(INSTALL_MSVCRT "Install Microsoft CRT" OFF)
    IF(${INSTALL_MSVCRT})
        SET(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION ".")
        INCLUDE(InstallRequiredSystemLibraries)
    ENDIF()
ENDIF()