-- The interactive interpreter relies on having primitives available.
-- When booting from an older version, this causes the compiler to fail to
-- build, so in those cases we replace MicroHs.Translate with this module.
module MicroHs.Translate where

import qualified Prelude(); import MHSPrelude
-- Both PrimTable and Unsafe.Coerce need to be imported for AnyType
import PrimTable
import Unsafe.Coerce

import MicroHs.Desugar (LDef)
import MicroHs.Ident (Ident)

translateAndRun :: (Ident, [LDef]) -> IO ()
translateAndRun = notSupported

translate :: (Ident, [LDef]) -> AnyType
translate = notSupported

notSupported :: a
notSupported = error "the interpreter is not supported in stage 1 builds"
