#!/usr/bin/env bash

#-------------------------------------------------------#
#Sanity Checks
if [ "${BUILD}" != "YES" ] || \
   [ -z "${BINDIR}" ] || \
   [ -z "${EGET_EXCLUDE}" ] || \
   [ -z "${EGET_TIMEOUT}" ] || \
   [ -z "${GIT_TERMINAL_PROMPT}" ] || \
   [ -z "${GIT_ASKPASS}" ] || \
   [ -z "${GITHUB_TOKEN}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ]; then
 #exit
  echo -e "\n[+]Skipping Builds...\n"
  exit 1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
export SKIP_BUILD="NO" #YES, in case of deleted repos, broken builds etc
if [ "${SKIP_BUILD}" == "NO" ]; then
    #go-appimage : Go implementation of AppImage tools 
     export BIN="go-appimage"
     export SOURCE_URL="https://github.com/probonopd/go-appimage"
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
      #Fetch
       eval "$EGET_TIMEOUT" eget "$SOURCE_URL" --tag "continuous" --asset "appimaged" --asset "$(uname -m)" --asset "AppImage" --asset "^.zsync" --to "$BINDIR/go-appimaged.no_strip"
       eval "$EGET_TIMEOUT" eget "$SOURCE_URL" --tag "continuous" --asset "appimagetool" --asset "$(uname -m)" --asset "AppImage" --asset "^.zsync" --to "$BINDIR/go-appimagetool.no_strip"
       eval "$EGET_TIMEOUT" eget "$SOURCE_URL" --tag "continuous" --asset "mkappimage" --asset "$(uname -m)" --asset "AppImage" --asset "^.zsync" --to "$BINDIR/go-mkappimage.no_strip"
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
unset SKIP_BUILD ; export BUILT="YES"
#In case of zig polluted env
unset AR CC CFLAGS CXX CPPFLAGS CXXFLAGS DLLTOOL HOST_CC HOST_CXX LDFLAGS LIBS OBJCOPY RANLIB
#In case of go polluted env
unset GOARCH GOOS CGO_ENABLED CGO_CFLAGS
#PKG Config
unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH
#-------------------------------------------------------#