{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- The layout differential test's cases: random rectangles, ratios, stacks,
-- layouts (trees of Full, Tall, Mirror and Choose) and messages, each
-- answered by xmonad's own XMonad.Layout, written as tests/LayoutCases.bend
-- for tests/LayoutDiff.bend to run through the Bend port and compare.
--
--   ghc -i<xmonad>/src tests/gen/GenLayout.hs -o genl && ./genl SEED COUNT > tests/LayoutCases.bend
module Main (main) where

import Control.Monad (forM)
import Data.List (intercalate)
import Data.Ratio (denominator, numerator, (%))
import Data.Typeable (cast)
import Data.Word (Word32)
import Graphics.X11.Types (Window)
import Graphics.X11.Xlib.Types (Rectangle (..))
import System.Environment (getArgs)
import Test.QuickCheck
import Test.QuickCheck.Gen (unGen)
import Test.QuickCheck.Random (mkQCGen)
import XMonad.Core
import XMonad.Layout
import XMonad.StackSet (Stack (..), Workspace (..))

-- Any of the layouts below, as one type, so that Choose and Mirror can hold
-- any of them (xmonad's own Layout wrapper asks for Read, which Choose of
-- two of them lacks)
data L a = forall l. (LayoutClass l a) => L (l a)

instance Show (L a) where
  show (L l) = show l

instance LayoutClass L Window where
  runLayout (Workspace i (L l) ms) r = do
    (ws, ml) <- runLayout (Workspace i l ms) r
    pure (ws, fmap L ml)
  handleMessage (L l) m = fmap (fmap L) (handleMessage l m)
  description (L l) = description l

-- The same trees, inspectable
data T = TFull | TTall Int Rational Rational | TMirror T | TChoose CLR T T

toL :: T -> L Window
toL TFull = L Full
toL (TTall n d f) = L (Tall n d f)
toL (TMirror t) = L (Mirror (toL t))
toL (TChoose c a b) = L (Choose c (toL a) (toL b))

ofL :: L Window -> T
ofL (L l)
  | Just (Full :: Full Window) <- cast l = TFull
  | Just (Tall n d f :: Tall Window) <- cast l = TTall n d f
  | Just (Mirror x :: Mirror L Window) <- cast l = TMirror (ofL x)
  | Just (Choose c a b :: Choose L L Window) <- cast l = TChoose c (ofL a) (ofL b)
  | otherwise = error "a layout this test does not build"

data M = MShrink | MExpand | MInc Int | MNext | MFirst | MHide | MRelease | MJump String

someM :: M -> SomeMessage
someM m = case m of
  MShrink -> SomeMessage Shrink
  MExpand -> SomeMessage Expand
  MInc k -> SomeMessage (IncMasterN k)
  MNext -> SomeMessage NextLayout
  MFirst -> SomeMessage FirstLayout
  MHide -> SomeMessage Hide
  MRelease -> SomeMessage ReleaseResources
  MJump d -> SomeMessage (JumpToLayout d)

data Op
  = OTile Rational Rectangle Int Int
  | OSplitV Int Rectangle
  | OSplitH Int Rectangle
  | OSplitHBy Rational Rectangle
  | OSplitVBy Rational Rectangle
  | ORun T Rectangle (Maybe (Stack Window))
  | OMsg T M
  | ODesc T

-- Generators -----------------------------------------------------------------

ratio :: Gen Rational
ratio = frequency
  [ (6, (%) <$> choose (0, 12) <*> choose (1, 12))
  , (1, (%) <$> choose (-6, -1) <*> choose (1, 6))
  , (1, elements [0, 1, 1 % 2, 3 % 100])
  ]

rectangle :: Gen Rectangle
rectangle = do
  x <- frequency [(5, choose (0, 3000)), (1, choose (-3000, -1))]
  y <- frequency [(5, choose (0, 3000)), (1, choose (-3000, -1))]
  w <- frequency [(6, choose (0, 4000)), (1, choose (0, 12)), (1, choose (4000000000, 4294967295))]
  h <- frequency [(6, choose (0, 4000)), (1, choose (0, 12)), (1, choose (4000000000, 4294967295))]
  pure (Rectangle x y w h)

stackG :: Gen (Maybe (Stack Window))
stackG = frequency
  [ (1, pure Nothing)
  , (6, do
      f <- choose (0, 40)
      u <- choose (0, 4) >>= \k -> vectorOf k (choose (0, 40))
      d <- choose (0, 6) >>= \k -> vectorOf k (choose (0, 40))
      pure (Just (Stack f u d)))
  ]

tall :: Gen T
tall = TTall <$> frequency [(6, choose (0, 4)), (1, choose (-2, -1))] <*> ratio <*> ratio

tree :: Int -> Gen T
tree 0 = frequency [(1, pure TFull), (2, tall)]
tree d = frequency
  [ (1, pure TFull), (2, tall), (1, TMirror <$> tree (d - 1))
  , (3, TChoose <$> elements [CL, CR] <*> tree (d - 1) <*> tree (d - 1)) ]

descs :: T -> [String]
descs TFull = ["Full"]
descs (TTall {}) = ["Tall"]
descs (TMirror t) = map ("Mirror " ++) (descs t)
descs (TChoose _ a b) = descs a ++ descs b

message :: T -> Gen M
message t = frequency
  [ (2, pure MShrink), (2, pure MExpand), (2, MInc <$> choose (-3, 3)), (3, pure MNext)
  , (2, pure MFirst), (1, pure MHide), (1, pure MRelease)
  , (3, MJump <$> elements ("Nothing" : descs t)) ]

op :: Gen Op
op = frequency
  [ (3, OTile <$> ratio <*> rectangle <*> choose (-2, 5) <*> choose (0, 9))
  , (1, OSplitV <$> choose (-1, 7) <*> rectangle)
  , (1, OSplitH <$> choose (-1, 7) <*> rectangle)
  , (1, OSplitHBy <$> ratio <*> rectangle)
  , (1, OSplitVBy <$> ratio <*> rectangle)
  , (5, ORun <$> (choose (0, 3) >>= tree) <*> rectangle <*> stackG)
  , (6, do t <- choose (0, 3) >>= tree; OMsg t <$> message t)
  , (1, ODesc <$> (choose (0, 3) >>= tree))
  ]

-- The words tests/LayoutDiff.bend's show.* write -----------------------------

sList :: (a -> String) -> [a] -> String
sList f xs = "[" ++ intercalate "," (map f xs) ++ "]"

bits :: Integral a => a -> Word32
bits = fromIntegral

sRect :: Rectangle -> String
sRect (Rectangle x y w h) = "R(" ++ intercalate "," (map show [bits x, bits y, w, h]) ++ ")"

sRat :: Rational -> String
sRat r = show (numerator r) ++ "/" ++ show (denominator r)

sT :: T -> String
sT TFull = "Full"
sT (TTall n d f) = "Tall(" ++ show n ++ "," ++ sRat d ++ "," ++ sRat f ++ ")"
sT (TMirror t) = "Mirror(" ++ sT t ++ ")"
sT (TChoose c a b) = "Choose(" ++ show c ++ "," ++ sT a ++ "," ++ sT b ++ ")"

pair :: (Rectangle, Rectangle) -> String
pair (a, b) = "(" ++ sRect a ++ "," ++ sRect b ++ ")"

runX' :: X a -> IO a
runX' x = fst <$> runX undefined undefined x

answer :: Op -> IO String
answer o = case o of
  OTile f r nm n -> pure (sList sRect (tile f r nm n))
  OSplitV n r -> pure (sList sRect (splitVertically n r))
  OSplitH n r -> pure (sList sRect (splitHorizontally n r))
  OSplitHBy f r -> pure (pair (splitHorizontallyBy f r))
  OSplitVBy f r -> pure (pair (splitVerticallyBy f r))
  ORun t r s -> do
    (ws, _) <- runX' (runLayout (Workspace "w" (toL t) s) r)
    pure (sList (\(w, q) -> show w ++ ":" ++ sRect q) ws)
  OMsg t m -> do
    ml <- runX' (handleMessage (toL t) (someM m))
    pure (maybe "N" (\l -> "J(" ++ sT (ofL l) ++ ")") ml)
  ODesc t -> pure (description (toL t))

-- Bend terms -----------------------------------------------------------------

bNat :: Int -> String
bNat n = show n ++ "n"

bInt :: Integer -> String
bInt n
  | n >= 0 = "N.Int.Pos{" ++ show n ++ "n}"
  | otherwise = "N.Int.Neg{" ++ show (negate n - 1) ++ "n}"

bRat :: Rational -> String
bRat r = "N.Rat{" ++ bInt (numerator r) ++ ", " ++ show (denominator r - 1) ++ "n}"

bRect :: Rectangle -> String
bRect (Rectangle x y w h) = "L.Rectangle{" ++ intercalate ", " (map show [bits x, bits y, w, h]) ++ "}"

bList :: (a -> String) -> [a] -> String
bList _ [] = "Nil{}"
bList f xs = "[" ++ intercalate ", " (map f xs) ++ "]"

bStack :: Maybe (Stack Window) -> String
bStack Nothing = "None{}"
bStack (Just (Stack f u d)) = "Some{W.Stack{" ++ show f ++ "n, " ++ bList (\w -> show w ++ "n") u ++ ", " ++ bList (\w -> show w ++ "n") d ++ "}}"

bT :: T -> String
bT TFull = "L.Full{}"
bT (TTall n d f) = "L.Tall{" ++ bInt (fromIntegral n) ++ ", " ++ bRat d ++ ", " ++ bRat f ++ "}"
bT (TMirror t) = "L.Mirror{" ++ bT t ++ "}"
bT (TChoose c a b) = "L.Choose{L." ++ show c ++ "{}, " ++ bT a ++ ", " ++ bT b ++ "}"

bM :: M -> String
bM m = "L." ++ case m of
  MShrink -> "Shrink{}"
  MExpand -> "Expand{}"
  MInc k -> "IncMasterN{" ++ bInt (fromIntegral k) ++ "}"
  MNext -> "NextLayout{}"
  MFirst -> "FirstLayout{}"
  MHide -> "Hide{}"
  MRelease -> "ReleaseResources{}"
  MJump d -> "JumpToLayout{" ++ show d ++ "}"

bOp :: Op -> String
bOp o = "O." ++ case o of
  OTile f r nm n -> "LTile{" ++ bRat f ++ ", " ++ bRect r ++ ", " ++ bInt (fromIntegral nm) ++ ", " ++ bNat n ++ "}"
  OSplitV n r -> "LSplitV{" ++ bInt (fromIntegral n) ++ ", " ++ bRect r ++ "}"
  OSplitH n r -> "LSplitH{" ++ bInt (fromIntegral n) ++ ", " ++ bRect r ++ "}"
  OSplitHBy f r -> "LSplitHBy{" ++ bRat f ++ ", " ++ bRect r ++ "}"
  OSplitVBy f r -> "LSplitVBy{" ++ bRat f ++ ", " ++ bRect r ++ "}"
  ORun t r s -> "LRun{" ++ bT t ++ ", " ++ bRect r ++ ", " ++ bStack s ++ "}"
  OMsg t m -> "LMsg{" ++ bT t ++ ", " ++ bM m ++ "}"
  ODesc t -> "LDesc{" ++ bT t ++ "}"

main :: IO ()
main = do
  [seedS, countS] <- getArgs
  let seed = read seedS
      count = read countS :: Int
      cases = [unGen op (mkQCGen (seed + i)) 30 | i <- [1 .. count]]
  lines' <- forM cases $ \o -> do
    a <- answer o
    pure ("  O.LCase{" ++ bOp o ++ ", " ++ show a ++ "}")
  putStrLn "# Written by tests/gen/GenLayout.hs: each case an operation of"
  putStrLn "# XMonad.Layout and what xmonad answers, in tests/LayoutOps.bend's words."
  putStrLn "import Base"
  putStrLn "import ../StackSet.bend as W"
  putStrLn "import ../Num.bend as N"
  putStrLn "import ../Layout.bend as L"
  putStrLn "import ./LayoutOps.bend as O"
  putStrLn ""
  putStrLn "def cases() -> List<&2, O.LCase>:"
  putStrLn ("  [\n" ++ intercalate ",\n" (map ("  " ++) lines') ++ "\n  ]")
