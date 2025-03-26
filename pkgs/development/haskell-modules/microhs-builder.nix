{ buildHaskellPackages
, fetchurl
, ghc
, jailbreak-cabal
, lib
, stdenv
, wrapMhs
}:

let
  # make-package-set always names the compiler ghc
  compiler = ghc;
  nativeCompiler = buildHaskellPackages.ghc;

  isCross = stdenv.buildPlatform != stdenv.hostPlatform;

in
{ pname
, dontStrip ? false
, version, revision ? null
, sha256 ? null
, src ? fetchurl { url = "mirror://hackage/${pname}-${version}.tar.gz"; inherit sha256; }
, sourceRoot ? null
, setSourceRoot ? null
, buildDepends ? [], setupHaskellDepends ? [], libraryHaskellDepends ? [], executableHaskellDepends ? []
, buildTarget ? ""
, buildTools ? [], libraryToolDepends ? [], executableToolDepends ? [], testToolDepends ? [], benchmarkToolDepends ? []
, configureFlags ? []
, buildFlags ? []
, haddockFlags ? []
, description ? null
, doCheck ? !isCross
, doBenchmark ? false
, doHoogle ? true
, doHaddockQuickjump ? doHoogle
, doInstallIntermediates ? false
, editedCabalFile ? null
, enableLibraryProfiling ? false
, enableExecutableProfiling ? false
, profilingDetail ? "exported-functions"
# TODO enable shared libs for cross-compiling
, enableSharedExecutables ? false
, enableSharedLibraries ? !stdenv.hostPlatform.isStatic && (ghc.enableShared or false)
, enableDeadCodeElimination ? (!stdenv.hostPlatform.isDarwin)  # TODO: use -dead_strip for darwin
# Disabling this for ghcjs prevents this crash: https://gitlab.haskell.org/ghc/ghc/-/issues/23235
, enableStaticLibraries ? !(stdenv.hostPlatform.isWindows || stdenv.hostPlatform.isWasm || stdenv.hostPlatform.isGhcjs)
, enableHsc2hsViaAsm ? stdenv.hostPlatform.isWindows
, extraLibraries ? [], librarySystemDepends ? [], executableSystemDepends ? []
# On macOS, statically linking against system frameworks is not supported;
# see https://developer.apple.com/library/content/qa/qa1118/_index.html
# They must be propagated to the environment of any executable linking with the library
, libraryFrameworkDepends ? [], executableFrameworkDepends ? []
, homepage ? "https://hackage.haskell.org/package/${pname}"
, platforms ? with lib.platforms; all # GHC can cross-compile
, badPlatforms ? lib.platforms.none
, hydraPlatforms ? null
, hyperlinkSource ? !(ghc.isMhs or false)
, isExecutable ? false, isLibrary ? !isExecutable
, jailbreak ? false
, license
, enableParallelBuilding ? true
, maintainers ? null
, changelog ? null
, mainProgram ? null
, doCoverage ? false
, doHaddock ? !(ghc.isHaLVM or false) && (ghc.hasHaddock or true)
, doHaddockInterfaces ? doHaddock && lib.versionAtLeast ghc.version "9.0.1"
, passthru ? {}
, pkg-configDepends ? [], libraryPkgconfigDepends ? [], executablePkgconfigDepends ? [], testPkgconfigDepends ? [], benchmarkPkgconfigDepends ? []
, testDepends ? [], testHaskellDepends ? [], testSystemDepends ? [], testFrameworkDepends ? []
, benchmarkDepends ? [], benchmarkHaskellDepends ? [], benchmarkSystemDepends ? [], benchmarkFrameworkDepends ? []
, # testTarget is deprecated starting with 25.05. Use testTargets instead.
  testTarget ? lib.concatStringsSep " " testTargets
, testTargets ? [], testFlags ? []
, broken ? false
, preCompileBuildDriver ? null, postCompileBuildDriver ? null
, preUnpack ? null, postUnpack ? null
, patches ? null, patchPhase ? null, prePatch ? "", postPatch ? ""
, preConfigure ? null, postConfigure ? null
, preBuild ? null, postBuild ? null
, preHaddock ? null, postHaddock ? null
, installPhase ? null, preInstall ? null, postInstall ? null
, checkPhase ? null, preCheck ? null, postCheck ? null
, preFixup ? null, postFixup ? null
, shellHook ? ""
, coreSetup ? false # Use only core packages to build Setup.hs.
, useCpphs ? false
, hardeningDisable ? null
, enableSeparateBinOutput ? false
, enableSeparateDataOutput ? false
, enableSeparateDocOutput ? doHaddock
, enableSeparateIntermediatesOutput ? false
, # Don't fail at configure time if there are multiple versions of the
  # same package in the (recursive) dependencies of the package being
  # built. Will delay failures, if any, to compile time.
  allowInconsistentDependencies ? false
, maxBuildCores ? 16 # more cores usually don't improve performance: https://ghc.haskell.org/trac/ghc/ticket/9221
, # If set to true, this builds a pre-linked .o file for this Haskell library.
  # This can make it slightly faster to load this library into GHCi, but takes
  # extra disk space and compile time.
  enableLibraryForGhci ? false
  # Set this to a previous build of this same package to reuse the intermediate
  # build products from that prior build as a starting point for accelerating
  # this build
, previousIntermediates ? null
  # References to these store paths are forbidden in the produced output.
, disallowedRequisites ? []
  # Whether to allow the produced output to refer to `ghc`.
  #
  # This is used by `haskell.lib.justStaticExecutables` to help prevent static
  # Haskell binaries from having erroneous dependencies on GHC.
  #
  # See https://nixos.org/manual/nixpkgs/unstable/#haskell-packaging-helpers
  # or its source doc/languages-frameworks/haskell.section.md
, disallowGhcReference ? false
, # Cabal 3.8 which is shipped by default for GHC >= 9.3 always calls
  # `pkg-config --libs --static` as part of the configure step. This requires
  # Requires.private dependencies of pkg-config dependencies to be present in
  # PKG_CONFIG_PATH which is normally not the case in nixpkgs (except in pkgsStatic).
  # Since there is no patch or upstream patch yet, we replicate the automatic
  # propagation of dependencies in pkgsStatic for allPkgConfigDepends for
  # GHC >= 9.3 by default. This option allows overriding this behavior manually
  # if mismatching Cabal and GHC versions are used.
  # See also <https://github.com/haskell/cabal/issues/8455>.
  __propagatePkgConfigDepends ? lib.versionAtLeast ghc.version "9.3"
, # Propagation can easily lead to the argv limit being exceeded in linker or C
  # compiler invocations. To work around this we can only propagate derivations
  # that are known to provide pkg-config modules, as indicated by the presence
  # of `meta.pkgConfigModules`. This option defaults to false for now, since
  # this metadata is far from complete in nixpkgs.
  __onlyPropagateKnownPkgConfigModules ? false
} @ args:

assert editedCabalFile != null -> revision != null;

let
  propagatedBuildInputs = buildDepends ++ libraryHaskellDepends ++ executableHaskellDepends ++ libraryFrameworkDepends;

  newCabalFileUrl = "mirror://hackage/${pname}-${version}/revision/${revision}.cabal";
  newCabalFile = fetchurl {
    url = newCabalFileUrl;
    sha256 = editedCabalFile;
    name = "${pname}-${version}-r${revision}.cabal";
  };

  defaultSetupHs = builtins.toFile "Setup.hs" ''
    import Distribution.Simple
    main = defaultMain
  '';

  nativeCompilerWithPkgs = wrapMhs {
    microhs = nativeCompiler;
    # FIXME: Filter out non-Haskell packages
    packages = propagatedBuildInputs;
  };

in stdenv.mkDerivation {
  inherit pname version;

  pos = builtins.unsafeGetAttrPos "pname" args;

  prePhases = ["setupCompilerEnvironmentPhase"];
  preConfigurePhases = ["compileBuildDriverPhase"];
  preInstallPhases = ["haddockPhase"];

  inherit src patches;

  depsBuildBuild = [ nativeCompilerWithPkgs ];
  buildInputs = lib.optionals (!isLibrary) propagatedBuildInputs;
  propagatedBuildInputs = lib.optionals isLibrary propagatedBuildInputs;

  prePatch = lib.optionalString (editedCabalFile != null) ''
    echo "Replace Cabal file with edited version from ${newCabalFileUrl}."
    cp ${newCabalFile} ${pname}.cabal
  '' + prePatch;

  postPatch = lib.optionalString jailbreak ''
    echo "Run jailbreak-cabal to lift version restrictions on build inputs."
    ${jailbreak-cabal}/bin/jailbreak-cabal ${pname}.cabal
  '' + postPatch;

  setupCompilerEnvironmentPhase = ''
    runHook preSetupCompilerEnvironment

    echo "Build with ${nativeCompilerWithPkgs}."
    export CABALDIR=$out/lib/mcabal
    export MHSDIR=$CABALDIR/${compiler.haskellCompilerName}
    mkdir -p $MHSDIR

    for p in "${compiler}" "''${pkgsHostHost[@]}" "''${pkgsHostTarget[@]}"; do
      cp -rs --update=none --no-preserve=mode $p/lib/mcabal/${compiler.haskellCompilerName}/* $MHSDIR/
    done
    find $CABALDIR/${compiler.haskellCompilerName} -type d -exec chmod u+w '{}' +

    runHook postSetupCompilerEnvironment
  '';

  compileBuildDriverPhase = ''
    runHook preCompileBuildDriver

    runHook postCompileBuildDriver
  '';

  buildPhase = ''
    runHook preBuild

    echo "Skipping buildPhase because MicroCabal always builds on install"

    runHook postBuild
  '';

  inherit doCheck;

  checkPhase = ''
    runHook preCheck

    echo "Skipping checkPhase because MicroCabal doesn't support test suites"

    runHook postCheck
  '';

  haddockPhase = ''
    runHook preHaddock

    echo "Skipping haddockPhase because MicroCabal doesn't support Haddock"

    runHook postHaddock
  '';

  # FIXME: How to use 'mcabal install' for libraries to properly get data files & co.?
  installPhase = ''
    runHook preInstall

    mcabal -v ${lib.concatStringsSep " " configureFlags} install
    mkdir -p $out/bin
    find "$CABALDIR/bin" -type f -exec ln -s '{}' "$out/bin/" \; || true

    runHook postInstall
  '';
}
