{ version
, rev
, hash
}:

{ fetchFromGitHub
, microhs-boot
, stdenv
, writeShellScript
}:

stdenv.mkDerivation {
  pname = "microhs";
  inherit version;

  src = fetchFromGitHub {
    owner = "augustss";
    repo = "MicroHs";
    fetchSubmodules = true;
    inherit rev hash;
  };

  patches = [
    ./install-cabaldir.patch
    ./microcabal-parser-leniency.patch
    ./lib-fixes.patch
    ./cpphs-fixes.patch
  ];

  nativeBuildInputs = [ microhs-boot ];

  makeFlags = [
    "CABALDIR=$(out)/lib/mcabal"
    "MCABAL=$(out)/lib/mcabal"
    "USECPPHS=${microhs-boot}/bin/cpphs"
  ];

  buildFlags = [ "bootstrapcpphs" "generated/mcabal.c" "all" ];

  # The bin/mhs target cannot be skipped by copying the boot mhs
  # The Makefile tries to use git if submodule .git doesn't exist
  preBuild = ''
    rm -r generated
    mkdir -p generated bin
    printf 'Generating mhs.c using the boot compiler\n'
    mhs -z -i -imhs -isrc -ilib -ipaths MicroHs.Main -ogenerated/mhs.c
    touch {cpphssrc/malcolm-wallace-universe,MicroCabal}/.git
  '';

  postInstall = ''
    mkdir -p $out/bin
    for x in cpphs mcabal mhs; do
      ln -s "$out/lib/mcabal/bin/$x" "$out/bin/$x"
    done
  '';

  passthru = {
    haskellCompilerName = "mhs-${version}";
    targetPrefix = "";
    isMhs = true;
  };
}
