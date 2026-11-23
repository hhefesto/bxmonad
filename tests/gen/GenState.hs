{-# LANGUAGE ScopedTypeVariables #-}
-- The state file's differential test cases: random state files, each as
-- xmonad 0.18.1 writes one (XMonad.Operations.writeStateToFile: show of a
-- StateFile, the layouts shown), and what xmonad answers after reading it
-- (readStateFile: the whole text read, each layout by the default config's
-- Read, the default layout for one that does not read, then W.ensureTags
-- with the default workspaces), written again with no extensions; "NONE"
-- when the text does not read. Written as tests/StateCases.bend for
-- tests/StateFileDiff.bend to run through StateFile.bend's read and show.
--
--   ghc -i<xmonad>/src -itests/e2e/ref tests/gen/GenState.hs -o gen
--   ./gen SEED COUNT > tests/StateCases.bend
--
-- Most texts are as xmonad writes them; some are cut short, end in a
-- newline (which xmonad's reads leaves unread, so the file does not read),
-- or hold a layout of another shape (which falls back to the default).
-- Tags are mostly xmonad's, some words, some any characters (controls,
-- non-ASCII, quotes, backslashes, digits after an escape).
module Main (main) where

import Data.Char (chr, ord)
import Data.List (intercalate)
import qualified Data.Map as M
import Data.Maybe (fromMaybe)
import Data.Ratio ((%))
import Numeric (showHex)
import System.Environment (getArgs)
import Test.QuickCheck
import Test.QuickCheck.Gen (unGen)
import Test.QuickCheck.Random (mkQCGen)
import XMonad hiding (Position, Dimension, Window)
import qualified XMonad as X
import qualified XMonad.StackSet as W

type DL = Choose Tall (Choose (Mirror Tall) Full)

type WS = W.StackSet WorkspaceId String X.Window ScreenId ScreenDetail

gRat :: Gen Rational
gRat = frequency
  [ (6, (%) <$> choose (-5, 120) <*> choose (1, 200))
  , (1, (%) <$> choose (-100000, 100000) <*> choose (1, 99999))
  ]

gTall :: Gen (Tall a)
gTall = Tall <$> frequency [(4, choose (0, 6)), (1, choose (-3, -1)), (1, choose (100, 100000))] <*> gRat <*> gRat

gSide :: Gen CLR
gSide = elements [CL, CR]

gLayout :: Gen (DL X.Window)
gLayout = Choose <$> gSide <*> gTall <*> (Choose <$> gSide <*> (Mirror <$> gTall) <*> pure Full)

-- a layout's text: the default's shape mostly, else one that does not read
-- as it (another shape, a cut one, junk)
gLayoutText :: Gen String
gLayoutText = frequency
  [ (8, show <$> gLayout)
  , (1, show <$> gTall)
  , (1, pure "Full")
  , (1, (\l n -> take n (show l)) <$> gLayout <*> choose (0, 60))
  , (1, elements ["", "Spiral", "Choose CL Full Full", "Mirror (Mirror Full)"])
  ]

gChar :: Gen Char
gChar = frequency
  [ (6, elements (['a' .. 'z'] ++ ['0' .. '9'] ++ " _-.:/'&"))
  , (2, elements "\"\\")
  , (2, chr <$> choose (0, 31))
  , (1, pure '\DEL')
  , (2, chr <$> choose (128, 0xD7FF))
  , (1, chr <$> choose (0xE000, 0x10FFFF))
  ]

gTag :: Gen String
gTag = frequency
  [ (7, show <$> (choose (1, 12) :: Gen Int))
  , (2, elements ["web", "mail", "dev", "x y", "\955", ""])
  , (2, choose (0, 6) >>= \k -> vectorOf k gChar)
  ]

gWin :: Gen X.Window
gWin = frequency [(4, choose (1, 40)), (1, choose (0, 4294967295))]

gStack :: Gen (Maybe (W.Stack X.Window))
gStack = frequency
  [ (1, pure Nothing)
  , (3, Just <$> (W.Stack <$> gWin <*> gWins <*> gWins))
  ]
  where gWins = choose (0, 4) >>= \k -> vectorOf k gWin

gWorkspace :: Gen (W.Workspace WorkspaceId String X.Window)
gWorkspace = W.Workspace <$> gTag <*> gLayoutText <*> gStack

gPos :: Gen X.Position
gPos = frequency [(5, choose (-3000, 3000)), (1, elements [minBound, maxBound, -1, 0])]

gDim :: Gen X.Dimension
gDim = frequency [(5, choose (0, 4000)), (1, elements [maxBound, 0, 1])]

gScreen :: Gen (W.Screen WorkspaceId String X.Window ScreenId ScreenDetail)
gScreen = W.Screen <$> gWorkspace <*> (S <$> choose (0, 4)) <*> (SD <$> (Rectangle <$> gPos <*> gPos <*> gDim <*> gDim))

gFloats :: Gen (M.Map X.Window W.RationalRect)
gFloats = do
  k <- choose (0, 3)
  M.fromList <$> vectorOf k ((,) <$> gWin <*> (W.RationalRect <$> gRat <*> gRat <*> gRat <*> gRat))

gWS :: Gen WS
gWS = do
  c <- gScreen
  v <- choose (0, 2) >>= \k -> vectorOf k gScreen
  h <- choose (0, 10) >>= \k -> vectorOf k gWorkspace
  W.StackSet c v h <$> gFloats

gExt :: Gen [(String, String)]
gExt = frequency
  [ (6, pure [])
  , (1, choose (1, 2) >>= \k -> vectorOf k ((,) <$> (choose (0, 8) >>= \n -> vectorOf n gChar) <*> (choose (0, 12) >>= \n -> vectorOf n gChar)))
  ]

-- a state file's text, mostly as xmonad writes it
gText :: Gen String
gText = do
  t <- show <$> (StateFile <$> gWS <*> gExt)
  frequency
    [ (16, pure t)
    , (2, (\n -> take n t) <$> choose (0, length t - 1))
    , (1, pure (t ++ "\n"))
    , (1, pure (" " ++ t))
    ]

maybeRead :: (String -> [(a, String)]) -> String -> Maybe a
maybeRead r s = case r s of
  [(x, "")] -> Just x
  _ -> Nothing

-- what xmonad writes again after reading the text (no extensions)
expect :: String -> String
expect t = case maybeRead reads t of
  Nothing -> "NONE"
  Just (sf :: StateFile) ->
    let cfg = def :: XConfig DL
        lay = Layout (layoutHook cfg) :: Layout X.Window
        ws = W.ensureTags lay (X.workspaces cfg) (W.mapLayout (fromMaybe lay . maybeRead (readsLayout lay)) (sfWins sf))
     in show (StateFile (W.mapLayout show ws) [])

-- a Bend string literal: printable ASCII as itself, " and \ escaped,
-- anything else as \u{hex}
bStr :: String -> String
bStr s = "\"" ++ concatMap esc s ++ "\""
  where
    esc '"' = "\\\""
    esc '\\' = "\\\\"
    esc c
      | ord c >= 32 && ord c < 127 = [c]
      | otherwise = "\\u{" ++ showHex (ord c) "" ++ "}"

main :: IO ()
main = do
  [seedS, countS] <- getArgs
  let seed = read seedS
      count = read countS :: Int
      texts = [unGen gText (mkQCGen (seed + i)) 30 | i <- [1 .. count]]
      line t = "    Case{" ++ bStr t ++ ", " ++ bStr (expect t) ++ "}"
  putStrLn "# Written by tests/gen/GenState.hs: each case a state file's text and"
  putStrLn "# what xmonad 0.18.1 writes again after reading it (NONE: it does not read)."
  putStrLn "import Base"
  putStrLn ""
  putStrLn "type Case is Data:"
  putStrLn "  Case{text: String, want: String}"
  putStrLn ""
  putStrLn "def cases() -> List<&2, Case>:"
  putStrLn ("  [\n" ++ intercalate ",\n" (map line texts) ++ "\n  ]")
