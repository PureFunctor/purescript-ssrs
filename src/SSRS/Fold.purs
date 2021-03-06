module SSRS.Fold where

import Prelude

import Control.Comonad.Cofree (Cofree, head, mkCofree, (:<))
import Control.Monad.Rec.Class (class MonadRec, Step(..), tailRecM2)
import Data.Functor.Mu (Mu(..))
import Data.List (List(..), (:))
import Data.Tuple (Tuple(..), fst, snd, swap)
import Data.Variant as Variant
import Dissect.Class (class Dissect, Result(..), init, next)
import SSRS.Algebra (Algebra, AlgebraM, GAlgebra, GAlgebraM)
import SSRS.Transform (Transform, TransformM)
import Safe.Coerce (class Coercible, coerce)

foreign import unsafeCata
  ∷ ∀ p q v
  . (p (Mu p) → Result p q v (Mu p))
  → (q v (Mu p) → v → Result p q v (Mu p))
  → Algebra p v
  → Mu p
  → v

cata ∷ ∀ p q v. Dissect p q ⇒ Algebra p v → Mu p → v
cata =
  let
    init' ∷ p (Mu p) → Result p q v (Mu p)
    init' = init

    next' ∷ q v (Mu p) → v → Result p q v (Mu p)
    next' = next
  in
    unsafeCata init' next'

cataM ∷ ∀ m p q v. MonadRec m ⇒ Dissect p q ⇒ AlgebraM m p v → Mu p → m v
cataM algebraM (In pt) = tailRecM2 go (init pt) Nil
  where
  go ∷ Result p q v (Mu p) → List (q v (Mu p)) → m (Step _ v)
  go (Result index) stack = index # Variant.match
    { yield: \{ j: In pt', qcj: pd } →
        pure (Loop { a: init pt', b: pd : stack })
    , return: \pv →
        case stack of
          pd : stk → do
            pv' ← algebraM pv
            pure (Loop { a: next pd pv', b: stk })
          Nil →
            Done <$> algebraM pv
    }

transCata
  ∷ ∀ p p' q q'
  . Dissect p p'
  ⇒ Dissect q q'
  ⇒ Transform (Mu q) p q -- p (Mu q) -> q (Mu q)
  → Mu p
  → Mu q
transCata t = cata (coerce t ∷ p (Mu q) → Mu q)

transCataM
  ∷ ∀ m p p' q q'
  . MonadRec m
  ⇒ Coercible (m (q (Mu q))) (m (Mu q))
  ⇒ Dissect p p'
  ⇒ Dissect q q'
  ⇒ TransformM m (Mu q) p q -- p (Mu q) -> m (q (Mu q))
  → Mu p
  → m (Mu q)
transCataM t = cataM (coerce t ∷ p (Mu q) → m (Mu q))

transCataT
  ∷ ∀ p q
  . Dissect p q
  ⇒ (Mu p → Mu p)
  → Mu p
  → Mu p
transCataT t = cata (coerce t ∷ p (Mu p) → Mu p)

transCataTM
  ∷ ∀ m p q
  . MonadRec m
  ⇒ Dissect p q
  ⇒ (Mu p → m (Mu p))
  → Mu p
  → m (Mu p)
transCataTM t = cataM (coerce t ∷ p (Mu p) → m (Mu p))

prepro ∷ ∀ p q v. Dissect p q ⇒ (p ~> p) → Algebra p v → Mu p → v
prepro pre algebra = cata (algebra <<< pre)

para ∷ ∀ p q v. Dissect p q ⇒ GAlgebra (Tuple (Mu p)) p v → Mu p → v
para gAlgebra = snd <<< cata algebra
  where
  algebra ∷ p (Tuple (Mu p) v) → Tuple (Mu p) v
  algebra n = Tuple (In (map fst n)) (gAlgebra n)

paraM ∷ ∀ m p q v. MonadRec m ⇒ Dissect p q ⇒ GAlgebraM (Tuple (Mu p)) m p v → Mu p → m v
paraM gAlgebraM = map snd <<< cataM algebraM
  where
  algebraM ∷ p (Tuple (Mu p) v) → m (Tuple (Mu p) v)
  algebraM n = Tuple (In (map fst n)) <$> gAlgebraM n

histo ∷ ∀ p q v. Dissect p q ⇒ GAlgebra (Cofree p) p v → Mu p → v
histo gAlgebra = head <<< cata algebra
  where
  algebra ∷ p (Cofree p v) → Cofree p v
  algebra n = gAlgebra n :< n

histoM ∷ ∀ m p q v. MonadRec m ⇒ Dissect p q ⇒ GAlgebraM (Cofree p) m p v → Mu p → m v
histoM gAlgebraM = map head <<< cataM algebraM
  where
  algebraM ∷ p (Cofree p v) → m (Cofree p v)
  algebraM n = mkCofree <$> gAlgebraM n <*> pure n

zygo ∷ ∀ p q v w. Dissect p q ⇒ Algebra p w → GAlgebra (Tuple w) p v → Mu p → v
zygo algebra gAlgebra = fst <<< cata zAlgebra
  where
  zAlgebra ∷ p (Tuple v w) → Tuple v w
  zAlgebra n = Tuple (gAlgebra (map swap n)) (algebra (map snd n))

zygoM
  ∷ ∀ m p q v w. MonadRec m ⇒ Dissect p q ⇒ AlgebraM m p w → GAlgebraM (Tuple w) m p v → Mu p → m v
zygoM algebraM gAlgebraM = map fst <<< cataM zAlgebraM
  where
  zAlgebraM ∷ p (Tuple v w) → m (Tuple v w)
  zAlgebraM n = Tuple <$> gAlgebraM (map swap n) <*> algebraM (map snd n)

mutu ∷ ∀ p q v w. Dissect p q ⇒ GAlgebra (Tuple v) p w → GAlgebra (Tuple w) p v → Mu p → v
mutu gAlgebraV gAlgebraW = fst <<< cata algebra
  where
  algebra ∷ p (Tuple v w) → Tuple v w
  algebra n = Tuple (gAlgebraW (map swap n)) (gAlgebraV n)

mutuM
  ∷ ∀ m p q v w
  . MonadRec m
  ⇒ Dissect p q
  ⇒ GAlgebraM (Tuple v) m p w
  → GAlgebraM (Tuple w) m p v
  → Mu p
  → m v
mutuM gAlgebraVM gAlgebraWM = map fst <<< cataM algebraM
  where
  algebraM ∷ p (Tuple v w) → m (Tuple v w)
  algebraM n = Tuple <$> gAlgebraWM (map swap n) <*> gAlgebraVM n
