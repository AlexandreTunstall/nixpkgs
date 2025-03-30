{ version
, mcabalVersion ? version
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
    patches/install-cabaldir.patch
    patches/cpphs-fixes.patch
    patches/fix-multiple-version.patch
    patches/lib/0001-Add-ioError-and-IOException.patch
    (if lib.versionOlder version "0.12"
      then patches/lib/0002-0.11-Add-mask-and-uninterruptibleMask.patch
      else patches/lib/0002-Add-mask-and-uninterruptibleMask.patch)
    patches/lib/0003-Add-assert.patch
    patches/lib/0004-Add-strict-fmap.patch
    patches/lib/0005-Add-Control.Monad.ST.Unsafe.patch
    (if lib.versionOlder version "0.12.0.1"
      then patches/lib/0006-0.11-Add-accursedUnutterablePerformIO.patch
      else patches/lib/0006-Add-accursedUnutterablePerformIO.patch)
    patches/lib/0007-Add-Data.ByteString.Lazy.patch
    patches/lib/0008-Add-Data.ByteString.Lazy.Internal.patch
    patches/lib/0009-Add-Data.ByteString.Short.patch
    patches/lib/0010-Add-Data.ByteString.Unsafe.patch
    patches/lib/0011-Add-Data.ByteString.Builder.patch
    patches/lib/0012-Add-Data.ByteString.Builder.Prim.patch
    patches/lib/0013-Add-Data.ByteString.Builder.Extra.patch
    patches/lib/0014-Add-WrappedMonoid.patch
    patches/lib/0015-Add-GHC.Float.patch
    patches/lib/0016-Add-userError-to-Prelude.patch
    (if lib.versionOlder version "0.12"
      then patches/lib/0017-0.11-Add-withBinaryFile.patch
      else patches/lib/0017-Add-withBinaryFile.patch)
    patches/lib/0018-Add-Bifunctor-tuple-instances.patch
    patches/lib/0019-Use-Foldable-versions-for-Data.List-functions.patch
    patches/lib/0020-Move-getAlt-into-the-Alt-definition.patch
    patches/lib/0021-Remove-Char8-newtype-and-add-Char8-pack.patch
    patches/lib/0022-Add-openBinaryTempFileWithDefaultPermissions.patch
    patches/lib/0023-Add-renameFile.patch
    patches/lib/0024-Add-unsafeDupablePerformIO.patch
    patches/lib/0025-Add-atomicModifyIORef.patch
    patches/lib/0026-Add-atomicWriteIORef.patch
  ] ++ lib.optionals (lib.versionAtLeast version "0.12.2.0") [
    patches/lib/0027-Add-fromForeignPtr.patch
  ] ++ lib.optionals (lib.versionAtLeast version "0.11.7.2") [
    (fetchpatch {
      name = "fix-mcabal-build.patch";
      url = "https://github.com/augustss/MicroHs/commit/4fd6d0415b7a3dd36f54a8600c3fd714baa3f05b.patch";
      revert = true;
      hash = "sha256-PyqFdAO2PGyse8KTDTKNwGM58ocdGTPXR9/Ni8Jpips=";
    })
  ] ++ lib.optionals (lib.versionOlder version "0.12") [
    patches/microcabal-parser-leniency.patch
  ] ++ lib.optionals (version == "0.12.0.0") [
    patches/remove-unicode-char-refs.patch
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
    haskellCompilerName = "mhs-${mcabalVersion}";
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
