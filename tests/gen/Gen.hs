{-# LANGUAGE ScopedTypeVariables #-}
-- The differential test's cases: random StackSets and operations, each
-- answered by xmonad's own XMonad.StackSet, written as tests/Cases.bend
-- for tests/Diff.bend to run through the Bend port and compare.
--
--   ghc -i<xmonad>/src tests/gen/Gen.hs -o gen && ./gen SEED COUNT > tests/Cases.bend
--
-- Most sets are built as xmonad's own tests build them (tests/Instances.hs:
-- new, then windows inserted and focused through the API, so every window
-- is in one place); a quarter are raw: any workspaces, stacks and screens,
-- duplicates allowed, to check the port on what the API never builds too
-- (all but focusWindow, whose `until` need not end on those).
module Main (main) where

import Control.Exception (SomeException, evaluate, try)
import Control.Monad (forM, replicateM)
import Data.List (intercalate, nub)
import qualified Data.Map as M
import Data.Ratio (denominator, numerator, (%))
import System.Environment (getArgs)
import Test.QuickCheck
import Test.QuickCheck.Gen (unGen)
import Test.QuickCheck.Random (mkQCGen)
import XMonad.StackSet

type T = StackSet Int Int Int Int Int

applyN :: Maybe Int -> (a -> a) -> a -> a
applyN Nothing _ x = x
applyN (Just n) f x = iterate f x !! n

rat :: Gen Rational
rat = (%) <$> choose (-5, 10) <*> choose (1, 6)

rect :: Gen RationalRect
rect = RationalRect <$> rat <*> rat <*> rat <*> rat

floats :: Gen (M.Map Int RationalRect)
floats = do
  k <- choose (0, 3)
  M.fromList <$> replicateM k ((,) <$> choose (0, 33) <*> rect)

-- as xmonad's tests/Instances.hs builds one
built :: Gen T
built = do
  numWs <- choose (1, 8)
  numScreens <- choose (1, numWs)
  lay <- choose (0, 3)
  wsIdx <- choose (1, numWs)
  scrs <- vectorOf numScreens (choose (0, 9))
  wsWindows <- vectorOf numWs (choose (0, 5) >>= \k -> vectorOf k (choose (0, 30)))
  focus <- forM wsWindows $ \ws ->
    if null ws then pure Nothing else Just <$> choose (0, length ws - 1)
  let tags = [1 .. numWs]
      s0 = new lay tags scrs
      s1 = foldr (\(t, (f, ws)) s -> applyN f focusUp (foldr insertUp (view t s) ws)) s0 (zip tags (zip focus wsWindows))
  fl <- floats
  pure (view wsIdx s1) {floating = fl}

-- any shape, duplicates allowed
raw :: Gen T
raw = do
  let stk = do
        f <- choose (0, 12)
        u <- choose (0, 3) >>= \k -> vectorOf k (choose (0, 12))
        d <- choose (0, 3) >>= \k -> vectorOf k (choose (0, 12))
        pure (Stack f u d)
      ws = Workspace <$> choose (0, 6) <*> choose (0, 3) <*> oneof [pure Nothing, Just <$> stk]
      scr = Screen <$> ws <*> choose (0, 4) <*> choose (0, 9)
  c <- scr
  v <- choose (0, 3) >>= \k -> vectorOf k scr
  h <- choose (0, 4) >>= \k -> vectorOf k ws
  StackSet c v h <$> floats

data Op
  = OView Int | OGreedyView Int | OFocusUp | OFocusDown | OSwapUp | OSwapDown
  | OSwapMaster | OShiftMaster | OFocusMaster | OFocusWindow Int | OInsertUp Int
  | ODelete Int | ODelete' Int | OShift Int | OShiftWin Int Int | ORenameTag Int Int
  | OEnsureTags Int [Int] | OFloat Int RationalRect | OSink Int | OPeek | OIndex
  | OFindTag Int | OMember Int | OAllWindows | OCurrentTag | OLookupWorkspace Int
  | OTagMember Int | OWorkspaces | OScreens | OFilterCurrent Int | ONew Int [Int] [Int]

op :: Bool -> T -> Gen Op
op isRaw s = do
  let n = length (workspaces s)
      tg = choose (0, n + 2)
      win = oneof [choose (0, 33), elements (0 : allWindows s)]
      cur = elements (0 : index s)
  frequency $
    [ (3, OView <$> tg), (3, OGreedyView <$> tg), (1, pure OFocusUp), (1, pure OFocusDown)
    , (1, pure OSwapUp), (1, pure OSwapDown), (1, pure OSwapMaster), (1, pure OShiftMaster)
    , (1, pure OFocusMaster), (2, OInsertUp <$> win), (2, ODelete <$> win), (2, ODelete' <$> win)
    , (2, OShift <$> tg), (3, OShiftWin <$> tg <*> win), (2, ORenameTag <$> tg <*> tg)
    , (2, OEnsureTags <$> choose (0, 3) <*> (choose (0, 6) >>= \k -> vectorOf k (choose (0, 12))))
    , (1, OFloat <$> win <*> rect), (1, OSink <$> win), (1, pure OPeek), (1, pure OIndex)
    , (2, OFindTag <$> win), (1, OMember <$> win), (1, pure OAllWindows), (1, pure OCurrentTag)
    , (2, OLookupWorkspace <$> choose (0, 10)), (1, OTagMember <$> tg), (1, pure OWorkspaces)
    , (1, pure OScreens), (2, OFilterCurrent <$> cur)
    , (2, ONew <$> choose (0, 3) <*> (nub <$> (choose (0, 5) >>= \k -> vectorOf k (choose (0, 9))))
                  <*> (choose (0, 5) >>= \k -> vectorOf k (choose (0, 9))))
    ] ++ [ (3, OFocusWindow <$> win) | not isRaw ]

-- The words Ops.bend's show.* write ------------------------------------------

sList :: (a -> String) -> [a] -> String
sList f xs = "[" ++ intercalate "," (map f xs) ++ "]"

sMaybe :: (a -> String) -> Maybe a -> String
sMaybe _ Nothing = "N"
sMaybe f (Just x) = "J(" ++ f x ++ ")"

sBool :: Bool -> String
sBool b = if b then "T" else "F"

sStack :: Stack Int -> String
sStack (Stack f u d) = "S(" ++ show f ++ "," ++ sList show u ++ "," ++ sList show d ++ ")"

sWs :: Workspace Int Int Int -> String
sWs (Workspace t l st) = "W(" ++ show t ++ "," ++ show l ++ "," ++ sMaybe sStack st ++ ")"

sScr :: Screen Int Int Int Int Int -> String
sScr (Screen w s d) = "C(" ++ sWs w ++ "," ++ show s ++ "," ++ show d ++ ")"

sRat :: Rational -> String
sRat r = show (numerator r) ++ "/" ++ show (denominator r)

sRect :: RationalRect -> String
sRect (RationalRect a b c d) = "R(" ++ intercalate "," (map sRat [a, b, c, d]) ++ ")"

sSS :: T -> String
sSS (StackSet c v h f) =
  "SS(" ++ sScr c ++ "," ++ sList sScr v ++ "," ++ sList sWs h ++ ","
    ++ sList (\(w, r) -> show w ++ ":" ++ sRect r) (M.toList f) ++ ")"

answer :: T -> Op -> IO String
answer s o = case o of
  OView i -> ss (view i s)
  OGreedyView i -> ss (greedyView i s)
  OFocusUp -> ss (focusUp s)
  OFocusDown -> ss (focusDown s)
  OSwapUp -> ss (swapUp s)
  OSwapDown -> ss (swapDown s)
  OSwapMaster -> ss (swapMaster s)
  OShiftMaster -> ss (shiftMaster s)
  OFocusMaster -> ss (focusMaster s)
  OFocusWindow w -> ss (focusWindow w s)
  OInsertUp w -> ss (insertUp w s)
  ODelete w -> ss (delete w s)
  ODelete' w -> ss (delete' w s)
  OShift i -> ss (shift i s)
  OShiftWin i w -> ss (shiftWin i w s)
  ORenameTag a b -> ss (renameTag a b s)
  OEnsureTags l ts -> ss (ensureTags l ts s)
  OFloat w r -> ss (float w r s)
  OSink w -> ss (sink w s)
  OPeek -> pure (sMaybe show (peek s))
  OIndex -> pure (sList show (index s))
  OFindTag w -> pure (sMaybe show (findTag w s))
  OMember w -> pure (sBool (member w s))
  OAllWindows -> pure (sList show (allWindows s))
  OCurrentTag -> pure (show (currentTag s))
  OLookupWorkspace sc -> pure (sMaybe show (lookupWorkspace sc s))
  OTagMember t -> pure (sBool (tagMember t s))
  OWorkspaces -> pure (sList sWs (workspaces s))
  OScreens -> pure (sList sScr (screens s))
  OFilterCurrent w -> pure $ case stack (workspace (current s)) of
    Nothing -> "X"
    Just st -> sMaybe sStack (XMonad.StackSet.filter (/= w) st)
  ONew l ts ms -> do
    r <- try (evaluate (new l ts ms :: T))
    pure $ case r of
      Left (_ :: SomeException) -> "N"
      Right x -> "J(" ++ sSS x ++ ")"
  where
    ss x = pure (sSS x)

-- Bend terms -----------------------------------------------------------------

bNat :: Int -> String
bNat n = show n ++ "n"

bList :: (a -> String) -> [a] -> String
bList _ [] = "Nil{}"
bList f xs = "[" ++ intercalate ", " (map f xs) ++ "]"

bMaybe :: (a -> String) -> Maybe a -> String
bMaybe _ Nothing = "None{}"
bMaybe f (Just x) = "Some{" ++ f x ++ "}"

bStack :: Stack Int -> String
bStack (Stack f u d) = "W.Stack{" ++ bNat f ++ ", " ++ bList bNat u ++ ", " ++ bList bNat d ++ "}"

bWs :: Workspace Int Int Int -> String
bWs (Workspace t l st) = "W.Workspace{" ++ bNat t ++ ", " ++ bNat l ++ ", " ++ bMaybe bStack st ++ "}"

bScr :: Screen Int Int Int Int Int -> String
bScr (Screen w s d) = "W.Screen{" ++ bWs w ++ ", " ++ bNat s ++ ", " ++ bNat d ++ "}"

bInt :: Integer -> String
bInt n
  | n >= 0 = "N.Int.Pos{" ++ show n ++ "n}"
  | otherwise = "N.Int.Neg{" ++ show (negate n - 1) ++ "n}"

bRat :: Rational -> String
bRat r = "N.Rat{" ++ bInt (numerator r) ++ ", " ++ show (denominator r - 1) ++ "n}"

bRect :: RationalRect -> String
bRect (RationalRect a b c d) = "W.RationalRect{" ++ intercalate ", " (map bRat [a, b, c, d]) ++ "}"

bSS :: T -> String
bSS (StackSet c v h f) =
  "W.StackSet{" ++ bScr c ++ ", " ++ bList bScr v ++ ", " ++ bList bWs h ++ ", "
    ++ bList (\(w, r) -> "W.Float{" ++ bNat w ++ ", " ++ bRect r ++ "}") (M.toList f) ++ "}"

bOp :: Op -> String
bOp o = "O." ++ case o of
  OView i -> "OView{" ++ bNat i ++ "}"
  OGreedyView i -> "OGreedyView{" ++ bNat i ++ "}"
  OFocusUp -> "OFocusUp{}"
  OFocusDown -> "OFocusDown{}"
  OSwapUp -> "OSwapUp{}"
  OSwapDown -> "OSwapDown{}"
  OSwapMaster -> "OSwapMaster{}"
  OShiftMaster -> "OShiftMaster{}"
  OFocusMaster -> "OFocusMaster{}"
  OFocusWindow w -> "OFocusWindow{" ++ bNat w ++ "}"
  OInsertUp w -> "OInsertUp{" ++ bNat w ++ "}"
  ODelete w -> "ODelete{" ++ bNat w ++ "}"
  ODelete' w -> "ODelete_{" ++ bNat w ++ "}"
  OShift i -> "OShift{" ++ bNat i ++ "}"
  OShiftWin i w -> "OShiftWin{" ++ bNat i ++ ", " ++ bNat w ++ "}"
  ORenameTag a b -> "ORenameTag{" ++ bNat a ++ ", " ++ bNat b ++ "}"
  OEnsureTags l ts -> "OEnsureTags{" ++ bNat l ++ ", " ++ bList bNat ts ++ "}"
  OFloat w r -> "OFloat{" ++ bNat w ++ ", " ++ bRect r ++ "}"
  OSink w -> "OSink{" ++ bNat w ++ "}"
  OPeek -> "OPeek{}"
  OIndex -> "OIndex{}"
  OFindTag w -> "OFindTag{" ++ bNat w ++ "}"
  OMember w -> "OMember{" ++ bNat w ++ "}"
  OAllWindows -> "OAllWindows{}"
  OCurrentTag -> "OCurrentTag{}"
  OLookupWorkspace sc -> "OLookupWorkspace{" ++ bNat sc ++ "}"
  OTagMember t -> "OTagMember{" ++ bNat t ++ "}"
  OWorkspaces -> "OWorkspaces{}"
  OScreens -> "OScreens{}"
  OFilterCurrent w -> "OFilterCurrent{" ++ bNat w ++ "}"
  ONew l ts ms -> "ONew{" ++ bNat l ++ ", " ++ bList bNat ts ++ ", " ++ bList bNat ms ++ "}"

main :: IO ()
main = do
  [seedS, countS] <- getArgs
  let seed = read seedS
      count = read countS :: Int
      gen = do
        isRaw <- frequency [(3, pure False), (1, pure True)]
        s <- if isRaw then raw else built
        o <- op isRaw s
        pure (s, o)
      cases = [unGen gen (mkQCGen (seed + i)) 30 | i <- [1 .. count]]
  lines' <- forM cases $ \(s, o) -> do
    a <- answer s o
    pure ("  O.Case{" ++ bSS s ++ ", " ++ bOp o ++ ", " ++ show a ++ "}")
  putStrLn "# Written by tests/gen/Gen.hs: each case a set, an operation, and what"
  putStrLn "# xmonad's XMonad.StackSet answers there, in tests/Ops.bend's words."
  putStrLn "import Base"
  putStrLn "import ../StackSet.bend as W"
  putStrLn "import ../Num.bend as N"
  putStrLn "import ./Ops.bend as O"
  putStrLn ""
  putStrLn "def cases() -> List<&2, O.Case>:"
  putStrLn ("  [\n" ++ intercalate ",\n" (map ("  " ++) lines') ++ "\n  ]")
