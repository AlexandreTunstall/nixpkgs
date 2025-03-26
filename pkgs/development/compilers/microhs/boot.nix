{ hugs
, microhs-src
, runtimeShell
, stdenv
}:

stdenv.mkDerivation {
  pname = "microhs";
  version = "${microhs-src.version}-hugs";

  # The hugs branch is unable to boot the latest version, so we patch a stable
  # version that can instead.
  inherit (microhs-src) src;

  patches = [ ./hugs.patch ];

  postUnpack = ''
    rm -r source/generated
  '';

  nativeBuildInputs = [ hugs ];

  buildFlags = [ "bin/hmhs" ];

  # cpphs-hugs isn't modern enough, so we hack mhs's version to run in hugs
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp bin/hmhs $out/bin/hmhs
    ln -s hmhs $out/bin/mhs

    mkdir -p $out/lib/cpphs-hugs/src
    cp -r hugs/* cpphscompat/* cpphssrc/malcolm-wallace-universe/{polyparse-*/src,cpphs-*}/* $out/lib/cpphs-hugs/src/
    find $out/lib/cpphs-hugs/src -type f -name '*.hs' -exec ${hugs}/bin/cpphs-hugs --noline '{}' '-O{}.tmp' \;
    find $out/lib/cpphs-hugs/src -type f -name '*.hs' -exec mv '{}.tmp' '{}' \;
    sed -i -e '66,$d' -e '/, readFileUTF8$/d' -e '/, writeFileUTF8$/d' -e 's/readFileUTF8/readFile/g' $out/lib/cpphs-hugs/src/Language/Preprocessor/Cpphs/ReadFirst.hs
    printf '\nintercalate :: [a] -> [[a]] -> [a]\nintercalate xs xss = concat (intersperse xs xss)\n' \
      >> $out/lib/cpphs-hugs/src/Language/Preprocessor/Cpphs/HashDefine.hs
    printf '\nintercalate :: [a] -> [[a]] -> [a]\nintercalate xs xss = concat (intersperse xs xss)\n' \
      >> $out/lib/cpphs-hugs/src/Language/Preprocessor/Cpphs/CppIfdef.hs
    rm $out/lib/cpphs-hugs/src/Data/Time/Clock.hs
    sed -i -e 's/\<UTCTime t\>/UTCTime a t/g' $out/lib/cpphs-hugs/src/Data/Time/Format.hs

    {
      printf '#!${runtimeShell}\n'
      printf 'exec ${hugs}/bin/runhugs %s "$@"\n' "$out/lib/cpphs-hugs/src/cpphs.hs"
    } > $out/bin/cpphs
    chmod +x $out/bin/cpphs

    runHook postInstall
  '';
}
