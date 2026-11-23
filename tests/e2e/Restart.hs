-- Asks the window manager on $DISPLAY to restart, as `xmonad --restart`
-- does (XMonad.Operations.sendRestart: an XMONAD_RESTART ClientMessage to
-- the root).
module Main (main) where

import Graphics.X11.Xlib
import Graphics.X11.Xlib.Extras

main :: IO ()
main = do
  dpy <- openDisplay ""
  rw <- rootWindow dpy (defaultScreen dpy)
  xmonad_restart <- internAtom dpy "XMONAD_RESTART" False
  allocaXEvent $ \e -> do
    setEventType e clientMessage
    setClientMessageEvent' e rw xmonad_restart 32 []
    sendEvent dpy rw False structureNotifyMask e
  sync dpy False
