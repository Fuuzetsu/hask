{-# LANGUAGE CPP, KindSignatures, PolyKinds, MultiParamTypeClasses, FunctionalDependencies, ConstraintKinds, NoImplicitPrelude, TypeFamilies, TypeOperators, FlexibleContexts, FlexibleInstances, UndecidableInstances, RankNTypes, GADTs, ScopedTypeVariables, DataKinds, DefaultSignatures #-}
module Hask.Prof 
  ( Prof, ProfunctorOf, Procompose(..)
  ) where

import Hask.Category

type Prof c d = Nat (Op c) (Nat d (->))

class    (Bifunctor f, Dom f ~ Op p, Dom2 f ~ q, Cod2 f ~ (->)) => ProfunctorOf p q f
instance (Bifunctor f, Dom f ~ Op p, Dom2 f ~ q, Cod2 f ~ (->)) => ProfunctorOf p q f

data Procompose (c :: i -> i -> *) (d :: j -> j -> *) (e :: k -> k -> *)
                (p :: j -> k -> *) (q :: i -> j -> *) (a :: i) (b :: k) where
  Procompose :: Ob d x => p x b -> q a x -> Procompose c d e p q a b

instance (Category c, Category d, Category e) => Functor (Procompose c d e) where
  type Dom (Procompose c d e) = Prof d e
  type Cod (Procompose c d e) = Nat (Prof c d) (Prof c e)
  fmap = fmap' where
    fmap' :: Prof d e a b -> Nat (Prof c d) (Prof c e) (Procompose c d e a) (Procompose c d e b)
    fmap' (Nat n) = Nat $ Nat $ Nat $ \(Procompose p q) -> Procompose (runNat n p) q

instance (Category c, Category d, Category e, ProfunctorOf d e p) => Functor (Procompose c d e p) where
  type Dom (Procompose c d e p) = Prof c d
  type Cod (Procompose c d e p) = Prof c e
  fmap = fmap' where
    fmap' :: Prof c d a b -> Prof c e (Procompose c d e p a) (Procompose c d e p b)
    fmap' (Nat n) = Nat $ Nat $ \(Procompose p q) -> Procompose p (runNat n q)

instance (Category c, Category d, Category e, ProfunctorOf d e p, ProfunctorOf c d q) => Functor (Procompose c d e p q) where
  type Dom (Procompose c d e p q) = Op c
  type Cod (Procompose c d e p q) = Nat e (->)
  fmap f = case observe f of
    Dict -> Nat $ \(Procompose p q) -> Procompose p (runNat (fmap f) q)

instance (Category c, Category d, Category e, ProfunctorOf d e p, ProfunctorOf c d q, Ob c a) => Functor (Procompose c d e p q a) where
  type Dom (Procompose c d e p q a) = e
  type Cod (Procompose c d e p q a) = (->)
  fmap f (Procompose p q) = Procompose (fmap1 f p) q

-- TODO

{-
associateProcompose :: Iso (Prof c e) (Prof c e) (->)
  (Procompose c d f (Procompose d e f p q) r) (Procompose c' d' f' (Procompose d' e' f' p' q') r')
  (Procompose c e f p (Procompose c d e q r)) (Procompose c' e' f' p' (Procompose c' d' e' q' r'))
associateProcompose = dimap
  (Nat $ Nat $ \ (Procompose (Procompose a b) c) -> Procompose a (Procompose b c))
  (Nat $ Nat $ \ (Procompose a (Procompose b c)) -> Procompose (Procompose a b) c)
-}
