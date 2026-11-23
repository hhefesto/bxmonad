-- The reference for the end-to-end comparison: xmonad 0.18.1 itself, with
-- its default configuration (XMonad.Config's def), as `xmonad` with no
-- config file runs it. It is launched directly (XMonad.Main.launch) with
-- directories of its own (argument 1), so it never reads or recompiles the
-- user's ~/.config/xmonad.
module Main (main) where

import System.Environment (getArgs)
import XMonad
import XMonad.Main (launch)

main :: IO ()
main = do
  [dir] <- getArgs
  launch def Directories { dataDir = dir, cfgDir = dir, cacheDir = dir }
