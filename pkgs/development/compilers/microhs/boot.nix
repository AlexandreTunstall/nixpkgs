{ hugs
, microhs-src
, runtimeShell
, stdenv
, writeShellScriptBin
}:

let
  # We can't just use the cpphs Hugs provides because it's too basic
  boot-cpphs = writeShellScriptBin "cpphs" ''
    #!${runtimeShell}
    exec ${hugs}/bin/runhugs $TMP/cpphs-hugs/src/cpphs.hs "$@"
  '';

in (microhs-src.override {
  microhs-boot = boot-cpphs;
}).overrideAttrs (old: {
  version = "${old.version}-hugs";

  patches = (old.patches or []) ++ [ ./hugs.patch ];

  nativeBuildInputs = [ hugs ];

  # bin/hmhs lacks dependencies that bin/mhs has, so we need to specify those
  bootFlags = [ "targets.conf" "dist-mcabal/Paths_MicroHs.hs" "bin/hmhs" ];

  preBuild = ''
    cp ${./NoTranslate.hs} src/MicroHs/Translate.hs

    printf '\nintercalate :: [a] -> [[a]] -> [a]\nintercalate xs xss = concat (intersperse xs xss)\n' \
      >> cpphssrc/malcolm-wallace-universe/cpphs-*/Language/Preprocessor/Cpphs/HashDefine.hs
    printf '\nintercalate :: [a] -> [[a]] -> [a]\nintercalate xs xss = concat (intersperse xs xss)\n' \
      >> cpphssrc/malcolm-wallace-universe/cpphs-*/Language/Preprocessor/Cpphs/CppIfdef.hs

    mkdir -p $TMP/cpphs-hugs/src
    cp -r hugs/* cpphscompat/* cpphssrc/malcolm-wallace-universe/{polyparse-*/src,cpphs-*}/* $TMP/cpphs-hugs/src/
    find $TMP/cpphs-hugs/src -type f -name '*.hs' -exec ${hugs}/bin/cpphs-hugs --noline '{}' '-O{}.tmp' \;
    find $TMP/cpphs-hugs/src -type f -name '*.hs' -exec mv '{}.tmp' '{}' \;
    sed -i -e '66,$d' -e '/, readFileUTF8$/d' -e '/, writeFileUTF8$/d' -e 's/readFileUTF8/readFile/g' $TMP/cpphs-hugs/src/Language/Preprocessor/Cpphs/ReadFirst.hs
    rm $TMP/cpphs-hugs/src/Data/Time/Clock.hs
    sed -i -e 's/\<UTCTime t\>/UTCTime a t/g' $TMP/cpphs-hugs/src/Data/Time/Format.hs

    mkdir -p dist-mcabal
    make $makeFlags $bootFlags
    cp bin/{h,}mhs
  '';
})
