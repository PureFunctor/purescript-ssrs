module Benchmark.Common where

import Prelude

import Control.Monad.Rec.Class (Step(..), tailRecM)
import Data.Bifunctor (class Bifunctor)
import Dissect.Generic (type (:*:), type (:+:), Const(..), Id(..), Product(..), Sum(..))
import Data.Functor.Mu (Mu(..))
import Data.Tuple (Tuple(..))
import Dissect.Class (class Dissect, yield, return)
import Test.QuickCheck.Gen (Gen, chooseInt)

data ListF a n = Nil | Cons a n

_Nil ∷ ∀ a. Mu (ListF a)
_Nil = In Nil

_Cons ∷ ∀ a. a → Mu (ListF a) → Mu (ListF a)
_Cons a n = In (Cons a n)

derive instance Functor (ListF a)

data TreeF a n = Leaf a | Fork n n

_Leaf ∷ ∀ a. a → Mu (TreeF a)
_Leaf a = In (Leaf a)

_Fork ∷ ∀ a. Mu (TreeF a) → Mu (TreeF a) → Mu (TreeF a)
_Fork a b = In (Fork a b)

derive instance Functor (TreeF n)

data ListF_2 ∷ Type → Type → Type → Type
data ListF_2 a n m = Cons_2 a

instance Bifunctor (ListF_2 a) where
  bimap _ _ (Cons_2 a) = Cons_2 a

data TreeF_2 ∷ Type → Type → Type → Type
data TreeF_2 a n m
  = ForkR m
  | ForkL n

instance Bifunctor (TreeF_2 a) where
  bimap f g = case _ of
    ForkR m → ForkR (g m)
    ForkL n → ForkL (f n)

instance Dissect (ListF a) (ListF_2 a) where
  init Nil = return Nil
  init (Cons a n) = yield n (Cons_2 a)
  next (Cons_2 a) c = return (Cons a c)

instance Dissect (TreeF a) (TreeF_2 a) where
  init (Leaf a) = return (Leaf a)
  init (Fork n m) = yield n (ForkR m)
  next w c = case w of
    ForkR m -> yield m (ForkL c)
    ForkL n -> return (Fork n c)

type ListP a = Const Unit :+: (Const a :*: Id)

_NilP ∷ ∀ a. Mu (ListP a)
_NilP = In (SumL (Const unit))

_ConsP ∷ ∀ a. a → Mu (ListP a) → Mu (ListP a)
_ConsP a n = In (SumR (Product (Const a) (Id n)))

type TreeP a = Const a :+: (Id :*: Id)

_LeafP ∷ ∀ a. a → Mu (TreeP a)
_LeafP a = In (SumL (Const a))

_ForkP ∷ ∀ a. Mu (TreeP a) → Mu (TreeP a) → Mu (TreeP a)
_ForkP a b = In (SumR (Product (Id a) (Id b)))

listOf_ ∷ ∀ r a. r → (a → r → r) → Int → Gen a → Gen r
listOf_ nil cons n g
  | n <= 0 = pure nil
  | otherwise = tailRecM go (Tuple nil n)
      where
      go (Tuple a 0) = pure (Done a)
      go (Tuple a c) = g <#> \x → Loop (Tuple (cons x a) (c - 1))

listOf ∷ ∀ a. Int → Gen a → Gen (Mu (ListF a))
listOf = listOf_ _Nil _Cons

polyListOf ∷ ∀ a. Int → Gen a → Gen (Mu (ListP a))
polyListOf = listOf_ _NilP _ConsP

treeOf ∷ ∀ a. Int → Gen a → Gen (Mu (TreeF a))
treeOf n g
  | n <= 0 = g <#> \x → _Leaf x
  | otherwise = g >>= \x → tailRecM go (Tuple (_Leaf x) n)
      where
      go (Tuple a 0) = pure (Done a)
      go (Tuple a c) = do
        l ← chooseInt 0 3
        r ← chooseInt 0 3

        l' ←
          if l == 0 then g <#> \x → _Leaf x
          else pure (_Fork a a)

        r' ←
          if r == 0 then g <#> \x → _Leaf x
          else pure (_Fork a a)

        pure $ Loop (Tuple (_Fork l' r') (c - 1))
