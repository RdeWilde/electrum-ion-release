#git clone https://github.com/dashpay/x11_hash
git clone https://github.com/mazaclub/x11_hash
cd x11_hash
git checkout 1.4
cd ..

  docker run -t --rm \
   -e WINEPREFIX="/wine/wine-py2.7.8-32" \
   -v $(pwd)/x11_hash:/code \
   -v $(pwd)/helpers:/helpers \
   ogrisel/python-winbuilder wineconsole --backend=curses Z:\\helpers\\x11_hash-build.bat
   test -d helpers/x11_hash || mkdir helpers/x11_hash
   cp -av x11_hash/build/lib.win32-2.7/x11_hash* helpers/
