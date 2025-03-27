{ version
, rev
, hash
}:

{ fetchFromGitHub
, fetchpatch
, lib
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
    ./cpphs-fixes.patch
  ] ++ lib.optionals (lib.versionAtLeast version "0.11.7.2") [
    (fetchpatch {
      name = "fix-mcabal-build.patch";
      url = "https://github.com/augustss/MicroHs/commit/4fd6d0415b7a3dd36f54a8600c3fd714baa3f05b.patch";
      revert = true;
      hash = "sha256-PyqFdAO2PGyse8KTDTKNwGM58ocdGTPXR9/Ni8Jpips=";
    })
  ] ++ lib.optionals (lib.versionOlder version "0.12") [
    ./microcabal-parser-leniency.patch
    ./lib-fixes.patch
  ] ++ lib.optionals (version == "0.12.0.0") [
    ./remove-unicode-char-refs.patch
  ] ++ lib.optionals (version == "0.12.3.0") [
    ./lib-fixes-0.12.3.0.patch
  ];

  makeFlags = [
    "CABALDIR=$(out)/lib/mcabal"
    "MCABAL=$(out)/lib/mcabal"
    "USECPPHS=${microhs-boot}/bin/cpphs"
  ];

  buildFlags = [ "bootstrapcpphs" "generated/mcabal.c" "all" ];

  # Delete pre-generated sources
  # The Makefile tries to use git if submodule .git doesn't exist
  postPatch = ''
    rm -r generated
    touch {cpphssrc/malcolm-wallace-universe,MicroCabal}/.git
    cp src/MicroHs/Translate.hs $TMP/Translate.hs
    cp ${./NoTranslate.hs} src/MicroHs/Translate.hs
  '';

  preBuild = ''
    mkdir -p generated bin
    printf '#error "Should not be compiled"\n' > generated/mhs.c

    # bin/mhs depends on targets.conf, which needs to be generated first
    make $makeFlags targets.conf
    # The Makefile rules for bin/mhs don't link our boot compiler's RTS
    printf 'Building bin/mhs using ${microhs-boot}/bin/mhs\n'
    ${microhs-boot}/bin/mhs -z -i -imhs -isrc -ipaths MicroHs.Main -o bin/mhs
  '';

  postBuild = ''
    cp $TMP/Translate.hs src/MicroHs/Translate.hs
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

  meta = {
    description = "Small compiler for Haskell";
    longDescription = ''
      A compiler for an extended subset of Haskell 2010.
      The compiler translates to combinators and can compile itself.
    '';
    homepage = "https://github.com/augustss/MicroHs";
    license = lib.licensesSpdx."Apache-2.0";
    mainProgram = "mhs";
    maintainers = with lib.maintainers; [ AlexandreTunstall ];
    platforms = lib.platforms.all;
    broken = version == "0.12.0.1";
  };
}
