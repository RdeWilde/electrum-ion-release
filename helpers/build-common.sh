#!/bin/bash

die () {
 echo "Build Failure - Exiting"
 case "$1" in 
      1) echo "VERSION not set"
         exit 1
	 ;;
      2) echo "Build TYPE not set" 
         exit 2
	 ;;
      3) echo "Build Error $2"
         exit 3
	 ;;
      4) echo "DOCKER binary not found"
         exit 4
	 ;;
      *) echo "Other Error"
         exit 99
	 ;;
 esac
 }

find_docker () {
which docker || echo "docker" not found                                         
if [[ $? = 0 ]]; then
  DOCKERBIN=$(which docker)
  echo "export DOCKERBIN=$(which docker)" >> build-config.sh
  fi
}

check_vars() {
test -z $DOCKERBIN && find_docker
test -z $DOCKERBIN && die 4

test -z $VERSION && VERSION="$1"
test -z $VERSION && die 1

test -z $TYPE && TYPE="$2"
test -z $TYPE && die 2
echo "Variables set correctly "
echo "DOCKERBIN = $DOCKERBIN"
echo "VERSION = $VERSION"
echo "Build TYPE = $TYPE"
}

sign_release () {
         sha1sum ${release} > ${1}.sha1
         md5sum ${release} > ${1}.md5
         gpg --sign --armor --detach  ${1}
         gpg --sign --armor --detach  ${1}.md5
         gpg --sign --armor --detach  ${1}.sha1
}

build_win32trezor() {
 ./helpers/build-hidapi.sh
}
get_archpkg (){
  if [ "${TYPE}" = "SIGNED" ]
  then 
     archbranch="v${VERSION}"
  else
     archbranch="\"check_repo_for_correct_branch\""
  fi
  test -d ../../contrib/ArchLinux || mkdir -v ../../contrib/ArchLinux
  pushd ../../contrib/ArchLinux
  wget https://aur.archlinux.org/packages/en/electrum-grs-git/electrum-grs-git.tar.gz
  tar -xpzvf electrum-grs-git.tar.gz
  sed -e 's/_gitbranch\=.*/_gitbranch='${archbranch}'/g' electrum-grs-git/PKGBUILD > electrum-grs-git/PKGBUILD.new
  mv electrum-grs-git/PKGBUILD.new electrum-grs-git/PKGBUILD
  rm electrum-grs-git.tar.gz
  popd
}
build_osx (){
  if [ "$(uname)" = "Darwin" ];
   then
   if [ ! -f /opt/local/bin/python2.7 ]
   then 
    echo "This build requires macports python2.7 and pyqt4"
    exit 5
   fi
  ./helpers/build_osx.sh ${VERSION} 
  mv helpers/release-packages/OSX helpers/release-packages/OSX-py2app
  ./helpers/build_osx-pyinstaller.sh  ${VERSION} $TYPE
 else
  echo "OSX Build Requires OSX build host!"
 fi
}
prepare_repo(){
  ./helpers/prepare_repo.sh
}
buildRelease(){
  test -d releases || mkdir -pv $(pwd)/releases
  # echo "Making locales" 
  # $DOCKERBIN run --rm -it --privileged -e MKPKG_VER=${VERSION} -v $(pwd)/helpers:/root  -v $(pwd)/repo:/root/repo  -v $(pwd)/source:/opt/wine-electrum/drive_c/electrum-grs/ -v $(pwd):/root/electrum-grs-release mazaclub/electrum-grs-release:${VERSION} /bin/bash
  echo "Making Release packages for $VERSION"
  ./helpers/build_release.sh
}
buildWindows(){
   echo "Making Windows EXEs for $VERSION" \
   && cp build-config.sh helpers/build-config.sh \
   && $DOCKERBIN run --rm -it --privileged -e MKPKG_VER=${VERSION} -v $(pwd)/helpers:/root  -v $(pwd)/repo:/root/repo  -v $(pwd)/source:/opt/wine-electrum/drive_c/electrum-grs/ -v $(pwd):/root/electrum-grs-release mazaclub/electrum-grs-winbuild:${VERSION} /root/build-binary $VERSION \
   && ls -la $(pwd)/helpers/release-packages/Windows/Electrum-GRS-${VERSION}-Windows-setup.exe 
}
buildOSX(){
   echo "Attempting OSX Build: Requires Darwin Buildhost" \
   && build_osx ${VERSION} \
   && echo "OSX build complete" 
}
buildLinux(){
   echo "Linux Packaging" \
   && $DOCKERBIN run --rm -it --privileged -e MKPKG_VER=${VERSION} -v $(pwd)/helpers:/root  -v $(pwd)/repo:/root/repo  -v $(pwd)/source:/opt/wine-electrum/drive_c/electrum-grs/ -v $(pwd):/root/electrum-grs-release mazaclub/electrum-grs-release:${VERSION} /root/make_linux ${VERSION}
}
completeReleasePackage(){
  mv $(pwd)/helpers/release-packages/* $(pwd)/releases/
  if [ "${TYPE}" = "rc" ]; then export TYPE=SIGNED ; fi
  if [ "${TYPE}" = "SIGNED" ] ; then
    ${DOCKERBIN} push mazaclub/electrum-grs-winbuild:${VERSION}
    ${DOCKERBIN} push mazaclub/electrum-grs-release:${VERSION}
    ${DOCKERBIN} push mazaclub/electrum-grs32-release:${VERSION}
    ${DOCKERBIN} tag -f ogrisel/python-winbuilder mazaclub/python-winbuilder:${VERSION}
    ${DOCKERBIN} push mazaclub/python-winbuilder:${VERSION}
    cd releases
    for release in * 
    do
      if [ ! -d ${release} ]; then
         sign_release ${release}
      else
         cd ${release}
         for i in * 
         do 
           if [ ! -d ${i} ]; then
              sign_release ${i}
	   fi
         done
         cd ..
      fi
    done
  fi
  echo "You can find your Electrum-GRSs $VERSION binaries in the releases folder."
  
}

buildImage(){
  echo "Building image"
  case "${1}" in 
  winbuild) $DOCKERBIN build -t mazaclub/electrum-grs-winbuild:${VERSION} .
         ;;
   release) $DOCKERBIN build -f Dockerfile-release -t  mazaclub/electrum-grs-release:${VERSION} .
         ;;
  esac
}


buildLtcScrypt() {
## this will be integrated into the main build in a later release
   wget https://pypi.python.org/packages/source/l/ltc_scrypt/ltc_scrypt-1.0.tar.gz
   tar -xpzvf ltc_scrypt-1.0.tar.gz
   docker run -ti --rm \
    -e WINEPREFIX="/wine/wine-py2.7.8-32" \
    -v $(pwd)/ltc_scrypt-1.0:/code \
    -v $(pwd)/helpers:/helpers \
    ogrisel/python-winbuilder wineconsole --backend=curses  Z:\\helpers\\ltc_scrypt-build.bat
   cp -av ltc_scrypt-1.0/build/lib.win32-2.7/ltc_scrypt.pyd helpers/ltc_scrypt.pyd

}
buildDarkcoinHash() {
  ./helpers/build_darkcoin-hash.sh
}

prepareFile(){
  echo "Preparing file for Electrum-GRS version $VERSION"
  if [ -e "$TARGETPATH" ]; then
    echo "Version tar already downloaded."
  else
   wget https://github.com/mazaclub/electrum-grs/archive/v${VERSION}.zip -O $TARGETPATH
  fi

  if [ -d "$TARGETFOLDER" ]; then
    echo "Version is already extracted"
  else
     unzip -d $(pwd)/source ${TARGETPATH} 
  fi
}

config (){
# setup build-config.sh for export/import of common variables
#if [[ $# -gt 0 ]]; then
#  echo "#!/bin/bash" > build-config.sh
#  VERSION=$1
#  echo "export VERSION=$1" >> build-config.sh
#  TYPE=${2:-tagged}
#  echo "export TYPE=${2:-tagged}" >> build-config.sh
#  FILENAME=Electrum-GRS-$VERSION.zip
#  echo "export FILENAME=Electrum-GRS-$VERSION.zip" >> build-config.sh
#  TARGETPATH=$(pwd)/source/$FILENAME
#  echo "export TARGETPATH=$(pwd)/source/$FILENAME" >> build-config.sh
#  TARGETFOLDER=$(pwd)/source/Electrum-GRS-$VERSION
#  echo "export TARGETFOLDER=$(pwd)/source/Electrum-GRS-$VERSION" >> build-config.sh
#  echo "Building Electrum-GRS $VERSION from $FILENAME"
#else
#  echo "Usage: ./build <version>."
#  echo "For example: ./build 1.9.8"
#  exit
#fi

# ensure docker is installed
#source helpers/build-common.sh
#if [[ -z "$DOCKERBIN" ]]; then
#        echo "Could not find docker binary, exiting"
#        exit
#else
#        echo "Using docker at $DOCKERBIN"
#fi

# make sure production builds are clean
#if [ "${TYPE}" = "rc" -o "${TYPE}" = "SIGNED" ]
#then 
#   ./clean.sh all
#fi

 ./helpers./config.sh
}



prep_deps () {
## clone python-trezor so we have it for deps, and to include trezorctl.py 
## for pyinstaller to analyze
#test -d python-trezor || git clone https://github.com/mazaclub/python-trezor
## prepare repo for local build
#test -f prepared || prepare_repo
##get_archpkg
#
## build windows C extensions
#test -f helpers/hid.pyd || build_win32trezor
#test -f helpers/darkcoin_hash.pyd || buildDarkcoinHash
#
## Build docker images
#$DOCKERBIN images|awk '{print $1":"$2}'|grep "mazaclub/electrum-grs-winbuild:${VERSION}" || buildImage winbuild
#$DOCKERBIN images|awk '{print $1":"$2}'|grep "mazaclub/electrum-grs-release:${VERSION}" || buildImage release
## touch FORCE_IMG_BUILD if you want to 
#test -f FORCE_IMG_BUILD &&  buildImage winbuild
#test -f FORCE_IMG_BUILD &&  buildImage release
 ./helpers/prep_deps.sh
}
test -f /.dockerenv || find_docker
