 git clone  https://github.com/trezor/cython-hidapi
 cd cython-hidapi
 git submodule init
 git submodule update
 cd ..
 test -d python-trezor || git clone https://github.com/mazaclub/python-trezor
 docker run --privileged -t --rm \
   -e WINEPREFIX="/wine/wine-py2.7.8-32" \
   -v $(pwd)/cython-hidapi:/code \
   -v $(pwd)/python-trezor:/trezor \
   -v $(pwd)/helpers:/helpers \
   ogrisel/python-winbuilder wineconsole --backend=curses Z:\\helpers\\python-trezor-build.bat
   #ogrisel/python-winbuilder wineconsole --backend=curses cmd
 cp -av cython-hidapi/build/lib.win32-2.7/hid.pyd ./helpers
 sudo chown -R ${USER}  python-trezor 
 pushd python-trezor/dist
 unzip trezor-*.win32.zip
 popd
