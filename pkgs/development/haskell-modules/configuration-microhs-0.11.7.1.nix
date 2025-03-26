{ pkgs, haskellLib }:

with haskellLib;

let
  inherit (pkgs) lib;

in

self: super:
{
  # Disable MicroHs core libraries
  array = null;
  base = null;
  bytestring = null;
  deepseq = null;
  directory = null;
  #hashable = null;
  process = null;
  text = null;

  # hackage-packages does not include GHC core libraries
  #array = self.array_0_5_8_0;
  binary = appendPatch patches/microhs-binary.patch self.binary_0_8_9_2;
  #bytestring = appendPatches [
  #  (pkgs.fetchpatch {
  #    url = "https://github.com/haskell/bytestring/commit/793bccce629a86e13dc45461505e68e8b1b686c4.patch";
  #    name = "bytestring-simplify-cabal.patch";
  #    includes = [ "bytestring.cabal" ];
  #    hash = "sha256-/FSvjr7Zh1zHIsOCuPfL37NobBsX4Bulg8MHW0gLV7A=";
  #  })
  #  patches/microhs-bytestring.patch
  #] (enableCabalFlag "pure-haskell" (overrideCabal {
  #  revision = null;
  #  editedCabalFile = null;
  #} self.bytestring_0_12_1_0));
  Cabal = self.Cabal_3_14_0_0;
  Cabal-syntax = self.Cabal-syntax_3_14_0_0;
  containers = appendPatches [
    (pkgs.fetchpatch {
      url = "https://github.com/haskell/containers/commit/6a6c007dc699aa0b354285a39420977efaf48328.patch";
      name = "refactor-intset-bitmasks.patch";
      relative = "containers";
      hash = "sha256-Z6zGDA9oyBKoPue6wWIX5iTeqURvY46SX1RGcXMB2Og=";
    })
    (pkgs.fetchpatch {
      url = "https://github.com/haskell/containers/commit/24b0b3a5810482e97a12529d33dd406f3a4c501c.patch";
      name = "microhs-fixes.patch";
      relative = "containers";
      excludes = [ "changelog.md" ];
      hash = "sha256-YphTuOsV6D/nWY8Rl9dHMex11qxN50bWuXmPqzHycEg=";
    })
  ] self.containers_0_7;
  #deepseq = self.deepseq_1_5_1_0;
  #directory = self.directory_1_3_9_0;
  exceptions = self.exceptions_0_10_8;
  filepath = self.filepath_1_5_3_0;
  ghc-bignum = null;
  ghc-boot-th = null;
  ghc-compact = null;
  ghc-heap = null;
  ghc-prim = null;
  ghci = null;
  haskeline = self.haskeline_0_8_2_1;
  hpc = self.hpc_0_7_0_2;
  integer-gmp = self.integer-gmp_1_1;
  libiserv = self.libiserv_9_6_6;
  mtl = appendPatch (pkgs.fetchpatch {
    url = "https://github.com/haskell/mtl/commit/f2b6d233f3ab6595fd4a9db7e4f446e21e937d8c.patch";
    name = "revert-polykinded-cont.patch";
    includes = [ "Control/Monad/Cont/Class.hs" ];
    revert = true;
    hash = "sha256-ZhH4Qkil1lHhqSmnwiUw5caOPyvX9uhHQvsovoI74Q4=";
  }) self.mtl_2_3_1;
  parsec = self.parsec_3_1_17_0;
  pretty = appendPatch patches/microhs-pretty.patch self.pretty_1_1_3_6;
  #process = self.process_1_6_25_0;
  rts = null;
  #stm = appendPatch patches/microhs-stm.patch self.stm_2_5_3_1;
  stm = null;
  system-cxx-std-lib = null;
  template-haskell = null;
  terminfo = self.terminfo_0_4_1_6;
  #text = self.text_2_0_2;
  time = appendPatches [
    (pkgs.fetchpatch {
      url = "https://github.com/haskell/time/commit/2763822bafe092b4c3ad951fe588d149dafd1346.patch";
      name = "update-version-bounds.patch";
      hash = "sha256-RnASPIz2nj2YsFFWpePoprtMsm/Y8FJMJGEbQXPdGaM=";
    })
    (pkgs.fetchpatch {
      url = "https://github.com/haskell/time/commit/fdea1ed065dcec5ede4c30c3c87e2659fe8a8bf3.patch";
      name = "instance-parsetime-dayofweek.patch";
      hash = "sha256-+2aPTKcimyuPWPhzV3sPPFJ3SwE/IOU97iaLX2vnPys=";
    })
    (pkgs.fetchpatch {
      url = "https://github.com/haskell/time/commit/40671a8c7217b8cafb44682572c95a47d988cd59.patch";
      name = "microhs-fixes.patch";
      hash = "sha256-/No6ggpO4DQ1WLKIRff6CC6C2vx/H0ZdT0yADqqJmVk=";
    })
    (pkgs.fetchpatch {
      url = "https://github.com/haskell/time/commit/e7bec4369f0a04cb3d92dd3f84fe22dd7f8bcfbd.patch";
      name = "microhs-fixes-2.patch";
      hash = "sha256-W0xtXmDDP7ogt/uTtsiEP3EVxg8m3vtYnxrbaFoAohA=";
    })
    (pkgs.fetchpatch {
      url = "https://github.com/haskell/time/commit/d9a99d52e3bd2219259a239ee05b698f2cdb25d9.patch";
      name = "microhs-fixes-3.patch";
      hash = "sha256-KtTlZV7Xy+S3v0YORYnADo01WdSaPFJJQ4SfCPFF7hY=";
    })
  ] (overrideCabal {
    # The revision is awkward to patch due to DOS line endings.
    editedCabalFile = null;
    revision = null;
  } self.time_1_14);
  transformers = self.transformers_0_6_1_2;
  unix = self.unix_2_8_5_1;
  xhtml = self.xhtml_3000_3_0_0;
}
