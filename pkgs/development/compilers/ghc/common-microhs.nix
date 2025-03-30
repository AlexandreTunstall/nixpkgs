{ ghc-src
, microhs
, coreutils
, perl
, stdenv
, runCommand
, writeShellScriptBin
, writeText
}:

let
  # "ghc" is actually MicroHs inside the microhs package sets
  compiler = microhs.ghc;

  bootLibs = [
    microhs.binary
    microhs.filepath
  ];

  compilerWithPkgs = microhs.wrapMhs {
    microhs = compiler;
    packages = bootLibs;
  };

  fake-ghc = writeShellScriptBin "ghc" ''
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --numeric-version)
          printf '%s\n' ${ghc-src.version}
          ;;
        --version)
          printf 'The Glorious Glasgow Haskell Compilation System, version %s\n' ${ghc-src.version}
          ;;
        --info)
          cat ${fake-ghc-info}
          ;;
      esac
      shift
    done
  '';

  fake-ghc-pkg = runCommand "fake-ghc-pkg" {} ''
    mkdir -p $out/bin
    ln -s ${fake-ghc}/bin/ghc $out/bin/ghc-pkg
    ln -s ${fake-ghc}/bin/ghc $out/bin/ghc
  '';

  # We can't use config, because it may have ABI or exec format
  mkGhcPlatform = { parsed, ... }: "${parsed.cpu.name}-${parsed.vendor.name}-${parsed.kernel.name}";

  # TODO: Probably don't need the first 5 strings
  fake-ghc-info = writeText "fake-ghc-info" ''
    -- ./configure is very strict in how this can be formatted
     [("C compiler command", "${stdenv.cc}/bin/cc")
     ,("ld command", "${stdenv.cc.bintools}/bin/ld")
     ,("ar command", "${stdenv.cc.bintools}/bin/ar")
     ,("ar flags", "q")
     ,("ar supports at file", "YES")
     ,("Host platform", "${mkGhcPlatform stdenv.buildPlatform}")
     ,("Target platform", "${mkGhcPlatform stdenv.hostPlatform}")
     ]
  '';

  buildMk = ''
    BuildFlavour =
    DYNAMIC_GHC_PROGRAMS = NO
    INTEGER_LIBRARY = integer-simple
    Stage1Only = YES
    HADDOCK_DOCS = NO
  '';

  mkPackage = pname: srcDir: args: (microhs.mkDerivation ({
    inherit pname;
    version = "${ghc-src.version}.0";

    inherit (ghc-src) src;
    inherit (ghc-src.meta) license;

    patches = (ghc-src.patches or []) ++ [
      ./microhs.patch
    ];

    buildTools = [ fake-ghc-pkg perl ];

    postPatch = ''
      sed -i -e '4234,4246d' -e 's/$GHC_PWD/pwd/g' configure
    '';

    preConfigure = ''
      rm configure
    '';

    # FIXME: This runs after jailbreak-cabal
    postConfigure = ''
      cd ${srcDir}
      if [ -e ${pname}.cabal.in ]; then
        sed -e 's/@ProjectVersion@/${ghc-src.version}/g' \
          -e 's/@ProjectVersionMunged@/${ghc-src.version}.0/g' \
          -e 's/@Suffix@//g' \
          -e '/exposed:/Id' \
          ${pname}.cabal.in > ${pname}.cabal
      fi
    '';
  } // args)).overrideAttrs {
    configurePlatforms = [ "build" "host" ];
  };

  ghc-boot-th = mkPackage "ghc-boot-th" "libraries/ghc-boot-th" { };

  template-haskell = mkPackage "template-haskell" "libraries/template-haskell" {
    libraryHaskellDepends = [
      ghc-boot-th
      microhs.pretty
    ];
  };

  ghc-boot = mkPackage "ghc-boot" "libraries/ghc-boot" {
    libraryHaskellDepends = [
      microhs.binary
      microhs.bytestring
      microhs.containers
      microhs.directory
      microhs.filepath
      ghc-boot-th
    ];

    # Where is this file coming from?!
    preBuild = ''
      rm GHC/LanguageExtensions/Type.hs
    '';
  };

  ghc = mkPackage "ghc" "compiler" {
    libraryHaskellDepends = [
      microhs.array
      microhs.binary
      microhs.bytestring
      microhs.containers
      microhs.deepseq
      microhs.directory
      microhs.filepath
      #microhs.hpc
      microhs.pretty
      microhs.process
      #template-haskell
      microhs.time
      microhs.transformers
      ghc-boot
      ghc-boot-th
    ];

    configureFlags = [ "-fstage1" ];

    preConfigure = ''
      echo -n "${buildMk}" > mk/build.mk
    '';

    preBuild = ''
      pushd ..
      mkdir -p compiler/stage1/build
      make -f compiler/ghc.mk compiler/stage1/{build/Config.hs,ghc_boot_platform.h}
      popd
    '';
  };

in mkPackage "ghc-bin" "ghc" {
  pname = "ghc";
  version = "${ghc-src.version}-microhs";

  isExecutable = true;

  executableHaskellDepends = [
    microhs.array
    microhs.bytestring
    microhs.directory
    microhs.process
    microhs.filepath
    microhs.transformers
    ghc-boot
    ghc
  ];

  postInstall = ''
    ln -s $CABALDIR/bin $out/bin
  '';

  inherit (ghc-src.meta) description hydraPlatforms mainProgram;
}
