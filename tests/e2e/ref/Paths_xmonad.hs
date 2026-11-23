-- Cabal writes this module for xmonad's own build; Ref.hs is built from
-- xmonad's source with ghc alone, so it gets this one: xmonad's version.
module Paths_xmonad (version) where

import Data.Version (Version, makeVersion)

version :: Version
version = makeVersion [0, 18, 1]
