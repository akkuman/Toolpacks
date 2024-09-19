#!/usr/bin/env bash

#-------------------------------------------------------#
#Sanity Checks
if [ "$BUILD" != "YES" ] || \
   [ -z "$BINDIR" ] || \
   [ -z "$EGET_EXCLUDE" ] || \
   [ -z "$EGET_TIMEOUT" ] || \
   [ -z "$GIT_TERMINAL_PROMPT" ] || \
   [ -z "$GIT_ASKPASS" ] || \
   [ -z "$GITHUB_TOKEN" ] || \
   [ -z "$SYSTMP" ] || \
   [ -z "$TMPDIRS" ]; then
 #exit
  echo -e "\n[+]Skipping Builds...\n"
  exit 1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
export SKIP_BUILD="NO" #YES, in case of deleted repos, broken builds etc
if [ "$SKIP_BUILD" == "NO" ]; then
    #opengist : Self-hosted pastebin powered by Git, open-source alternative to Github Gist.
     export BIN="btop"
     export SOURCE_URL="https://github.com/thomiceli/opengist"
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
      #fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       eval "$EGET_TIMEOUT" eget "$SOURCE_URL" --asset "opengist" --asset "linux" --asset "amd64" --asset "tar.gz" "$EGET_EXCLUDE" --download-only
       ouch decompress "./"* --yes
       find "." -type f -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath | xargs -I {} rsync -av --copy-links "{}" "${BINDIR}"
       objcopy --remove-section=".comment" --remove-section=".note.*" "${BINDIR}/opengist"
       strip --strip-debug --strip-dwo --strip-unneeded -R ".comment" -R ".gnu.version" "${BINDIR}/opengist" ; file "${BINDIR}/opengist" && du -sh "${BINDIR}/opengist"
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