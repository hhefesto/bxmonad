-- A test client for the end-to-end comparison (tests/e2e.sh): one window,
-- named by its first argument, mapped, and kept until it is told to go.
--
--   client NAME [fixed W H] [transient PARENT]
--
-- fixed: WM_NORMAL_HINTS with min = max = W x H (xmonad floats it).
-- transient: WM_TRANSIENT_FOR the window named PARENT (xmonad floats it).
-- It takes WM_DELETE_WINDOW (xmonad's kill closes it). SIGUSR1 unmaps the
-- window (a client withdrawing it), SIGUSR2 destroys it and exits.
module Main (main) where

import Control.Concurrent (threadDelay)
import Control.Monad (forM, when)
import Data.IORef
import Data.Maybe (catMaybes, listToMaybe)
import Graphics.X11.Xlib
import Graphics.X11.Xlib.Extras
import System.Environment (getArgs)
import System.Exit (exitSuccess)
import System.Posix.Signals

data Opts = Opts { oName :: String, oFixed :: Maybe (Int, Int), oParent :: Maybe String }

parse :: [String] -> Opts
parse (n : rest) = go rest (Opts n Nothing Nothing)
  where
    go ("fixed" : w : h : xs) o = go xs o { oFixed = Just (read w, read h) }
    go ("transient" : p : xs) o = go xs o { oParent = Just p }
    go _ o = o
parse [] = error "client NAME [fixed W H] [transient PARENT]"

byName :: Display -> String -> IO (Maybe Window)
byName d n = do
  (_, _, ws) <- queryTree d (defaultRootWindow d)
  hits <- forM ws $ \w -> do
    m <- fetchName d w
    return (if m == Just n then Just w else Nothing)
  return (listToMaybe (catMaybes hits))

main :: IO ()
main = do
  o <- parse <$> getArgs
  d <- openDisplay ""
  let s = defaultScreen d
  w <- createSimpleWindow d (defaultRootWindow d) 10 20 400 300 0 (blackPixel d s) (whitePixel d s)
  storeName d w (oName o)
  del <- internAtom d "WM_DELETE_WINDOW" False
  setWMProtocols d w [del]
  case oFixed o of
    Just (fw, fh) -> setWMNormalHints d w SizeHints
      { sh_min_size = Just (fromIntegral fw, fromIntegral fh)
      , sh_max_size = Just (fromIntegral fw, fromIntegral fh)
      , sh_resize_inc = Nothing, sh_aspect = Nothing, sh_base_size = Nothing
      , sh_win_gravity = Nothing }
    Nothing -> return ()
  case oParent o of
    Just p -> byName d p >>= maybe (return ()) (\pw -> changeProperty32 d w wM_TRANSIENT_FOR wINDOW propModeReplace [fromIntegral pw])
    Nothing -> return ()
  selectInput d w structureNotifyMask
  mapWindow d w
  sync d False
  todo <- newIORef (0 :: Int)
  _ <- installHandler sigUSR1 (Catch (writeIORef todo 1)) Nothing
  _ <- installHandler sigUSR2 (Catch (writeIORef todo 2)) Nothing
  allocaXEvent (run d w del todo)

run :: Display -> Window -> Atom -> IORef Int -> XEventPtr -> IO ()
run d w del todo e = do
  t <- readIORef todo
  when (t == 1) $ writeIORef todo 0 >> unmapWindow d w >> sync d False
  when (t == 2) $ destroyWindow d w >> sync d False >> exitSuccess
  n <- pending d
  if n == 0 then threadDelay 5000 >> run d w del todo e else do
    nextEvent d e
    ev <- getEvent e
    case ev of
      ClientMessageEvent { ev_data = (a : _) } | fromIntegral a == del ->
        destroyWindow d w >> sync d False >> exitSuccess
      _ -> return ()
    run d w del todo e
