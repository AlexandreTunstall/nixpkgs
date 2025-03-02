{ lib
, stdenv
, fetchFromGitHub
, fetchFromGitLab
, attr
, libevdev
, libxkbcommon
, meson
, ninja
, pkg-config
, protobuf
, protobufc
, python3
, python3Packages
, systemd
}:
let
  munit = fetchFromGitHub {
    owner = "nemequ";
    repo = "munit";
    rev = "fbbdf1467eb0d04a6ee465def2e529e4c87f2118";
    hash = "sha256-qm30C++rpLtxBhOABBzo+6WILSpKz2ibvUvoe8ku4ow=";
  };
in
stdenv.mkDerivation rec {
  pname = "libei";
  version = "0.99.1";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "libinput";
    repo = "libei";
    rev = version;
    hash = "sha256-r/rkN2d8P30P/IL1YaLWWRbA5s3uVq5Fc/K1vhS31tw=";
  };

  buildInputs = [
    libevdev
    libxkbcommon
    protobuf
    protobufc
    systemd
  ];
  nativeBuildInputs = [
    attr
    meson
    ninja
    pkg-config
    python3
  ] ++
  (with python3Packages; [
    jinja2
    pytest
    python-dbusmock
    strenum
    structlog
  ]);

  postPatch = ''
    ln -s "${munit}" ./subprojects/munit
    patchShebangs ./proto/ei-scanner
  '';

  meta = with lib; {
    description = "Library for Emulated Input";
    homepage = "https://gitlab.freedesktop.org/libinput/libei";
    license = licenses.mit;
    maintainers = [ maintainers.pedrohlc ];
    platforms = platforms.linux;
  };
}
