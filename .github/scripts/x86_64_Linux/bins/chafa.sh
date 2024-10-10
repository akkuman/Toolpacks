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
SKIP_BUILD="NO" #YES, in case of deleted repos, broken builds etc
if [ "${SKIP_BUILD}" == "NO" ]; then
    #chafa : 📺🗿 Terminal graphics for the 21st century.
     export BIN="chafa"
     export SOURCE_URL="https://github.com/hpjansson/chafa"
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
      #Static builds aren't static: https://hpjansson.org/chafa/download/ https://hpjansson.org/chafa/releases/static/
      ##Build (alpine-musl)
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       docker stop "alpine-builder" 2>/dev/null ; docker rm "alpine-builder" 2>/dev/null
       docker run --privileged --net="host" --name "alpine-builder" --pull="always" "azathothas/alpine-builder:latest" \
        bash -l -c '
        #Setup ENV
         mkdir -p "/build-bins" && pushd "$(mktemp -d)" >/dev/null 2>&1
        #Switch to default: https://github.com/JonathonReinhart/staticx/pull/284
         git clone --filter "blob:none" "https://github.com/JonathonReinhart/staticx" --branch "add-type-checking" && cd "./staticx"
         #https://github.com/JonathonReinhart/staticx/blob/main/build.sh
         pip install -r "./requirements.txt" --break-system-packages --upgrade --force
         apk update && apk upgrade --no-interactive
         apk add busybox scons --latest --upgrade --no-interactive
         export BOOTLOADER_CC="musl-gcc"
         rm -rf "./build" "./dist" "./scons_build" "./staticx/assets"
         python "./setup.py" sdist bdist_wheel
         find dist/ -name "*.whl" | while read -r file; do 
           newname=$(echo "$file" | sed "s/none-[^/]*\.whl$/none-any.whl/");
           mv "$file" "$newname"; 
         done
         find "dist/" -name "*.whl" | xargs pip install --break-system-packages --upgrade --force
         staticx --version ; popd >/dev/null 2>&1
        #Install Deps
         pushd "$(mktemp -d)" >/dev/null 2>&1
         apk update --no-interactive 2>/dev/null
         apk add freetype freetype-dev freetype-static --latest --upgrade --no-interactive 2>/dev/null
         apk add imagemagick-jpeg --latest --upgrade --no-interactive 2>/dev/null
         apk add jpeg --latest --upgrade --no-interactive 2>/dev/null
         apk add jpeg-dev --latest --upgrade --no-interactive 2>/dev/null
         apk add libavif --latest --upgrade --no-interactive 2>/dev/null
         apk add libavif-dev --latest --upgrade --no-interactive 2>/dev/null
         apk add libjpeg --latest --upgrade --no-interactive 2>/dev/null
         apk add libjpeg-turbo-dev --latest --upgrade --no-interactive 2>/dev/null
         apk add libjpeg-turbo-static --latest --upgrade --no-interactive 2>/dev/null
         apk add libwebp-dev --latest --upgrade --no-interactive 2>/dev/null
         apk add libwebp-static --latest --upgrade --no-interactive 2>/dev/null
         apk add librsvg librsvg-dev --latest --upgrade --no-interactive 2>/dev/null
         apk add openjpeg --latest --upgrade --no-interactive 2>/dev/null
         apk add openjpeg-dev --latest --upgrade --no-interactive 2>/dev/null         
         apk add tiff --latest --upgrade --no-interactive 2>/dev/null
         apk add tiff-dev --latest --upgrade --no-interactive 2>/dev/null
        #Build
         git clone --filter "blob:none" --quiet "https://github.com/hpjansson/chafa" && cd "./chafa"
         export CFLAGS="-O2 -flto=auto -static -w -pipe"
         export LDFLAGS="-static -s -Wl,-S -Wl,--build-id=none"
         "./autogen.sh" ; "./configure" --disable-shared --disable-Werror --enable-static --enable-year2038
         make --jobs="$(($(nproc)+1))" --keep-going
        #Staticx
         staticx --loglevel DEBUG "./tools/chafa/chafa" --strip "/build-bins/chafa"
        #strip & info 
         find "/build-bins/" -type f -exec objcopy --remove-section=".comment" --remove-section=".note.*" "{}" \;
         find "/build-bins/" -type f ! -name "*.no_strip" -exec strip --strip-debug --strip-dwo --strip-unneeded --preserve-dates "{}" \; 2>/dev/null
         file "/build-bins/"* && du -sh "/build-bins/"*
         popd >/dev/null 2>&1
        '
      #Copy & Meta
       docker cp "alpine-builder:/build-bins/." "$(pwd)/"
       find "." -maxdepth 1 -type f -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath
       #Meta
       find "." -maxdepth 1 -type f -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
       sudo rsync -av --copy-links --exclude="*/" "./." "${BINDIR}"
      #Delete Containers
       docker stop "alpine-builder" 2>/dev/null ; docker rm "alpine-builder"
       popd >/dev/null 2>&1
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