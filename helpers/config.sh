
# make sure production builds are clean
if [ "${TYPE}" = "rc" -o "${TYPE}" = "SIGNED" ]
then 
#   ./clean.sh all
echo "not cleaning - please reenable"
fi
# setup build-config.sh for export/import of common variables
if [[ $# -gt 0 ]]; then
  echo "#!/bin/bash" > build-config.sh
  echo "OS=$3"
  echo "export OS=$3" >> build-config.sh
  export VERSION=$1
  echo "export VERSION=$1" >> build-config.sh
  export TYPE=${2:-tagged}
  echo "export TYPE=${2:-tagged}" >> build-config.sh
  echo "Checking Product: "
  PRODUCT=$(grep "name=" ../../setup.py|awk -F\= '{print $2}'|sed -e 's/\,//g' -e 's/\"//g')
  MAZACLUB_PRODUCT=${4:-${PRODUCT}}
  echo ${PRODUCT}
  echo ${MAZACLUB_PRODUCT}
  export FILENAME=${MAZACLUB_PRODUCT}-$VERSION.zip
  echo "export FILENAME=${MAZACLUB_PRODUCT}-$VERSION.zip" >> build-config.sh
  export TARGETPATH=$(pwd)/source/$FILENAME
  echo "export TARGETPATH=$(pwd)/source/$FILENAME" >> build-config.sh
  export TARGETFOLDER=$(pwd)/source/Electrum-DASH-$VERSION
  echo "export TARGETFOLDER=$(pwd)/source/Electrum-DASH-$VERSION" >> build-config.sh
  echo "Building ${MAZACLUB_PRODUCT} $VERSION from $FILENAME"
else
  echo "Usage: ./build <version>."
  echo "For example: ./build 1.9.8"
  exit
fi

# ensure docker is installed
source helpers/build-common.sh
source helpers/build-config.sh
if [[ -z "$DOCKERBIN" ]]; then
        echo "Could not find docker binary, exiting"
        exit
else
        echo "Using docker at $DOCKERBIN"
fi
cp build-config.sh helpers/

