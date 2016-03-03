#!/bin/bash
echo "helpers/build_release.sh"
set -xeo pipefail
source build-config.sh
source helpers/build-common.sh
check_vars
$DOCKERBIN run --rm -t --privileged -e MKPKG_VER=${VERSION} -v $(pwd)/releases:/releases -v $(pwd)/helpers:/root  -v $(pwd)/repo:/root/repo  -v $(pwd)/source:/opt/wine-electrum/drive_c/electrum-dash/ -v $(pwd):/root/electrum-dash-release mazaclub/electrum-dash-release:${VERSION} /root/make_release $VERSION $TYPE 
test -d releases/ || mkdir releases
if [ -d  ${TRAVIS_BUILD_DIR} ] ; then 
  sudo chown -R $(whoami) releases
  cp -av helpers/release-packages/Source releases/
else 
  mv helpers/release-packages/Source releases/Source 
fi
