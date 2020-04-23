{ stdenv, mkDerivation, fetchFromGitHub, pkgconfig, cmake, qtbase, qttools,
  qtwebchannel, qtx11extras,
  gnome2, nss, nspr, alsaLib, atk, cairo, cups, dbus,
  expat, fontconfig, gdk-pixbuf, glib, gtk2,
  libxcb, pango, pulseaudio, xorg, deepin }:

let
  rpahtLibraries = [
    stdenv.cc.cc.lib  # libstdc++.so.6
    alsaLib
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    gdk-pixbuf
    glib
    gnome2.GConf
    gtk2
    libxcb
    nspr
    nss
    pango
    pulseaudio
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
  ];
  libPath = stdenv.lib.makeLibraryPath rpahtLibraries;
in

mkDerivation rec {
  pname = "qcef";
  version = "1.1.7";

  srcs = [
    (fetchFromGitHub {
      owner = "linuxdeepin";
      repo = pname;
      rev = version;
      sha256 = "1x0vb4nkfa1lq0nh6iqpxfvsqmb6qfn305pbc92bsqpgiqd7jvb1";
      name = pname;
    })
    (fetchFromGitHub {
      owner = "linuxdeepin";
      repo = "cef-binary";
      rev = "fecf00339545d2819224333cc506d5aa22ae8008";
      sha256 = "06i1zc7ciy7d0qhndiwpjrsii0x5i5hg9j6ddi4w5yf1nzgsrj4n";
      name = "cef-binary";
    })
  ];

  sourceRoot = pname;

  nativeBuildInputs = [
    pkgconfig
    cmake
    qttools
    deepin.setupHook
  ];

  buildInputs = [
    qtbase
    qtwebchannel
    qtx11extras
  ] ++ rpahtLibraries;

  postUnpack = ''
    rmdir ${pname}/cef
    ln -s ../cef-binary ${pname}/cef
  '';

  postPatch = ''
    searchHardCodedPaths
    fixPath $out /usr src/core/qcef_global_settings.{h,cpp}
    sed '/COMMAND rm -rf Release Resources/a COMMAND ldd qcef/libcef.so' -i src/CMakeLists.txt
    sed '/COMMAND rm -rf Release Resources/a COMMAND patchelf --set-rpath ${libPath} qcef/libcef.so' -i src/CMakeLists.txt
  '';

  postFixup = ''
    searchHardCodedPaths $out
  '';

  passthru.updateScript = deepin.updateScript { name = "${pname}-${version}"; };

  meta = with stdenv.lib; {
    description = "Qt5 binding of Chromium Embedded Framework";
    homepage = "https://github.com/linuxdeepin/qcef";
    license = licenses.lgpl3;
    platforms = platforms.linux;
    badPlatforms = [ "aarch64-linux" ];  # the cef-binary is not available
    maintainers = with maintainers; [ romildo ];
  };
}
