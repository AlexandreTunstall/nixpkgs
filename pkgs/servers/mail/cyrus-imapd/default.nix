{ stdenv, lib, fetchurl, pkgconfig, perl, perlPackages, bison, flex, openssl, jansson, cyrus_sasl, icu, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "cyrus-imapd";
  version = "3.4.2";

  src = fetchurl {
    url = "https://github.com/cyrusimap/cyrus-imapd/releases/download/${pname}-${version}/${pname}-${version}.tar.gz";
    sha256 = "1iajc54l7y54lvchzzl18r754xs9iafv16hnajqa58bhpssjbch8";
  };

  nativeBuildInputs = [ pkgconfig flex bison perl makeWrapper ];
  buildInputs = [ openssl jansson cyrus_sasl icu ];

  preBuildPhases = [ "preBuildPhase" ];

  preBuildPhase = ''
    patchShebangs .
  '';

  postFixup = ''
    for prog in installsieve sieveshell cyradm
    do
      wrapProgram $out/bin/$prog \
          --set PATH ${lib.makeBinPath [ perl ]} \
          --set PERL5LIB "$PERL5LIB:$out/${perl.libPrefix}"
    done
  '';

  meta = with lib; {
    homepage = "https://www.cyrusimap.org/imap/";
    description = "An email, contacts and calendar server";
    license = licenses.bsdOriginal;
    platforms = platforms.unix;
    maintainers = with maintainers; [ petabyteboy ];
  };
}
