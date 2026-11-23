-- What the end-to-end comparison (tests/e2e.sh) looks at: every top-level
-- window whose name starts with "t", bottom to top in X's stacking order,
-- with its map state, place, border width and WM_STATE, then the name of
-- the window with the input focus. Window ids differ between runs, so only
-- names are printed.
module Main (main) where

import Control.Monad (forM_)
import Data.List (isPrefixOf)
import Graphics.X11.Xlib
import Graphics.X11.Xlib.Extras

main :: IO ()
main = do
  d <- openDisplay ""
  sync d False
  st <- internAtom d "WM_STATE" False
  (_, _, ws) <- queryTree d (defaultRootWindow d)
  forM_ ws $ \w -> do
    m <- fetchName d w
    case m of
      Just n | "t" `isPrefixOf` n -> do
        wa <- getWindowAttributes d w
        p <- getWindowProperty32 d st w
        putStrLn $ unwords
          [ n, mapState (wa_map_state wa)
          , show (wa_x wa) ++ "," ++ show (wa_y wa)
          , show (wa_width wa) ++ "x" ++ show (wa_height wa)
          , "bw" ++ show (wa_border_width wa)
          , "state" ++ maybe "-" (show . take 1) p ]
      _ -> return ()
  (f, _) <- getInputFocus d
  fn <- if f == 0 || f == 1 then return Nothing else fetchName d f
  putStrLn ("focus " ++ maybe (if f == defaultRootWindow d then "root" else show (min f 2)) id fn)
  where
    mapState s | s == waIsViewable = "viewable"
               | s == waIsUnmapped = "unmapped"
               | otherwise = "unviewable"
