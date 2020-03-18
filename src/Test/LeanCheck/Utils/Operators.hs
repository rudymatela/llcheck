-- |
-- Module      : Test.LeanCheck.Utils.Operators
-- Copyright   : (c) 2015-2018 Rudy Matela
-- License     : 3-Clause BSD  (see the file LICENSE)
-- Maintainer  : Rudy Matela <rudy@matela.com.br>
--
-- This module is part of LeanCheck,
-- a simple enumerative property-based testing library.
--
-- Some operators for property-based testing.
module Test.LeanCheck.Utils.Operators
  (

  -- * Combining properties
    (==>)
  , (===), (====)
  , (&&&), (&&&&), (&&&&&)
  , (|||), (||||)

  -- * Properties of unary functions
  , idempotent
  , identity
  , neverIdentity

  -- * Properties of operators (binary functions)
  , isCommutative
  , commutative
  , associative
  , distributive
  , symmetric2

  -- * Properties of relations (binary functions returning truth values)
  , transitive
  , reflexive
  , irreflexive
  , symmetric
  , asymmetric
  , antisymmetric

  -- ** Order relations
  , equivalence
  , partialOrder
  , strictPartialOrder
  , totalOrder
  , strictTotalOrder
  , comparison

  -- * Ternary comparison operators
  , (=$), ($=)
  , (=|), (|=)

  -- * Properties for typeclass instances
  , okEq
  , okOrd
  , okEqOrd
  , okNum
  , okNumNonNegative
  )
where

-- TODO: Add examples in the haddock documentation of most functions in this
--       module.

-- TODO: review terminology in this module.  Some names aren't quite right!

-- TODO: rename commutative to isCommutative and etc...

import Test.LeanCheck ((==>))

combine :: (b -> c -> d) -> (a -> b) -> (a -> c) -> (a -> d)
combine (?) f g  =  \x -> f x ? g x

-- Uneeded, just food for thought:
-- > combine2 :: (c -> d -> e) -> (a -> b -> c) -> (a -> b -> d) -> (a -> b -> e)
-- Two possible implementations:
-- > combine2 op f g = \x y -> f x y `op` g x y
-- > combine2 = combine . combine

-- | Allows building equality properties between functions.
--
-- > prop_id_idempotent  =  id === id . id
--
-- >>> check $ id === (+0)
-- +++ OK, passed 200 tests.
--
-- >>> check $ id === id . id
-- +++ OK, passed 1 tests (exhausted).
--
-- >>> check $ id === (+1)
-- *** Failed! Falsifiable (after 1 tests):
-- 0
(===) :: Eq b => (a -> b) -> (a -> b) -> a -> Bool
(===)  =  combine (==)
infix 4 ===

-- | Allows building equality properties between two-argument functions.
--
-- >>> holds 100 $ const ==== asTypeOf
-- True
--
-- >>> holds 100 $ (+) ==== flip (+)
-- True
--
-- >>> holds 100 $ (+) ==== (*)
-- False
(====) :: Eq c => (a -> b -> c) -> (a -> b -> c) -> a -> b -> Bool
(====)  =  combine (===)
infix 4 ====

-- | And ('&&') operator over one-argument properties.
--
-- Allows building conjuntions between one-argument properties:
--
-- >>> holds 100 $ id === (+0) &&& id === (id . id)
-- True
(&&&) :: (a -> Bool) -> (a -> Bool) -> a -> Bool
(&&&)  =  combine (&&)
infixr 3 &&&

-- | And ('&&') operator over two-argument properties.
--
-- Allows building conjuntions between two-argument properties:
--
-- >>> holds 100 $ (+) ==== flip (+) &&&& (+) ==== (*)
-- False
(&&&&) :: (a -> b -> Bool) -> (a -> b -> Bool) -> a -> b -> Bool
(&&&&)  =  combine (&&&)
infixr 3 &&&&

-- | And operator over three-argument properties.
(&&&&&) :: (a -> b -> c -> Bool) -> (a -> b -> c -> Bool) -> a -> b -> c -> Bool
(&&&&&)  =  combine (&&&&)
infixr 3 &&&&&

-- | Or ('||') operator over one-argument properties.
--
-- Allows building disjunctions between one-argument properties:
--
-- >>> holds 100 $ id === (+0) ||| id === (id . id)
-- True
(|||) :: (a -> Bool) -> (a -> Bool) -> a -> Bool
(|||)  =  combine (||)
infixr 2 |||

-- | Or ('||') operator over two-argument properties.
--
-- Allows building conjuntions between two-argument properties:
--
-- >>> holds 100 $ (+) ==== flip (+) |||| (+) ==== (*)
-- True
(||||) :: (a -> b -> Bool) -> (a -> b -> Bool) -> a -> b -> Bool
(||||)  =  combine (|||)
infixr 2 ||||

{-# DEPRECATED commutative "Use isCommutative." #-}
commutative :: Eq b => (a -> a -> b) -> a -> a -> Bool
commutative  =  isCommutative

-- | Is a given operator commutative?  @x + y = y + x@
--
-- >>> check $ isCommutative (+)
-- +++ OK, passed 200 tests.
--
-- >>> import Data.List
-- >>> check $ isCommutative (union :: [Int]->[Int]->[Int])
-- *** Failed! Falsifiable (after 4 tests):
-- [] [0,0]
isCommutative :: Eq b => (a -> a -> b) -> a -> a -> Bool
isCommutative (?)  =  \x y -> x ? y == y ? x

-- | Is a given operator associative?  @x + (y + z) = (x + y) + z@
associative :: Eq a => (a -> a -> a) -> a -> a -> a -> Bool
associative (?)  =  \x y z -> x ? (y ? z) == (x ? y) ? z

-- | Does the first operator, distributes over the second?
distributive :: Eq a => (a -> a -> a) -> (a -> a -> a) -> a -> a -> a -> Bool
distributive (?) (#)  =  \x y z -> x ? (y # z) == (x ? y) # (x ? z)

-- | Are two operators flipped versions of each other?
--
-- > holds n $ (<)  `symmetric2` (>)  -:> int
-- > holds n $ (<=) `symmetric2` (>=) -:> int
--
-- > fails n $ (<)  `symmetric2` (>=) -:> int
-- > fails n $ (<=) `symmetric2` (>)  -:> int
symmetric2 :: Eq c => (a -> b -> c) -> (b -> a -> c) -> a -> b -> Bool
symmetric2 (+-) (-+)  =  \x y -> x +- y == y -+ x

-- | Is a given relation transitive?
transitive :: (a -> a -> Bool) -> a -> a -> a -> Bool
transitive (?)  =  \x y z -> x ? y && y ? z ==> x ? z

-- | An element is always related to itself.
reflexive :: (a -> a -> Bool) -> a -> Bool
reflexive (?)  =  \x -> x ? x

-- | An element is __never__ related to itself.
irreflexive :: (a -> a -> Bool) -> a -> Bool
irreflexive (?)  =  \x -> not $ x ? x

-- | Is a given relation symmetric?
-- This is a type-restricted version of 'commutative'.
symmetric :: (a -> a -> Bool) -> a -> a -> Bool
symmetric = commutative

-- | Is a given relation antisymmetric?
-- Not to be confused with "not symmetric" and "assymetric".
antisymmetric :: Eq a => (a -> a -> Bool) -> a -> a -> Bool
antisymmetric (?)  =  \x y -> x ? y && y ? x ==> x == y

-- | Is a given relation asymmetric?
-- Not to be confused with "not symmetric" and "antissymetric".
asymmetric :: (a -> a -> Bool) -> a -> a -> Bool
asymmetric (?)  =  \x y -> x ? y ==> not (y ? x)

-- | Is the given binary relation an equivalence?
--   Is the given relation reflexive, symmetric and transitive?
--
-- > > check (equivalence (==) :: Int -> Int -> Int -> Bool)
-- > +++ OK, passed 200 tests.
-- > > check (equivalence (<=) :: Int -> Int -> Int -> Bool)
-- > *** Failed! Falsifiable (after 3 tests):
-- > 0 1 0
--
-- Or, using "Test.LeanCheck.Utils.TypeBinding":
--
-- > > check $ equivalence (<=) -:> int
-- > *** Failed! Falsifiable (after 3 tests):
-- > 0 1 0
equivalence :: (a -> a -> Bool) -> a -> a -> a -> Bool
equivalence (==)  =  \x y z -> reflexive  (==) x
                            && symmetric  (==) x y
                            && transitive (==) x y z

-- | Is the given binary relation a partial order?
--   Is the given relation reflexive, antisymmetric and transitive?
partialOrder :: Eq a => (a -> a -> Bool) -> a -> a -> a -> Bool
partialOrder (<=)  =  \x y z -> reflexive     (<=) x
                             && antisymmetric (<=) x y
                             && transitive    (<=) x y z

-- | Is the given binary relation a strict partial order?
--   Is the given relation irreflexive, asymmetric and transitive?
strictPartialOrder :: (a -> a -> Bool) -> a -> a -> a -> Bool
strictPartialOrder (<)  =  \x y z -> irreflexive (<) x
                                  && asymmetric  (<) x y -- implied?
                                  && transitive  (<) x y z

-- | Is the given binary relation a total order?
totalOrder :: Eq a => (a -> a -> Bool) -> a -> a -> a -> Bool
totalOrder (<=)  =  \x y z -> (x <= y || y <= x)
                           && antisymmetric (<=) x y
                           && transitive    (<=) x y z

-- | Is the given binary relation a strict total order?
strictTotalOrder :: Eq a => (a -> a -> Bool) -> a -> a -> a -> Bool
strictTotalOrder (<)  =  \x y z -> (x /= y ==> x < y || y < x)
                                && irreflexive (<) x
                                && asymmetric  (<) x y -- implied?
                                && transitive  (<) x y z

comparison :: (a -> a -> Ordering) -> a -> a -> a -> Bool
comparison compare  =  \x y z -> equivalence (===) x y z
                              && irreflexive (<) x
                              && transitive  (<) x y z
                              && symmetric2  (<) (>) x y
  where
  x === y  =  x `compare` y == EQ
  x  <  y  =  x `compare` y == LT
  x  >  y  =  x `compare` y == GT


-- | Is the given function idempotent? @f (f x) == x@
--
-- >>> check $ idempotent abs
-- +++ OK, passed 200 tests.
--
-- >>> check $ idempotent sort
-- +++ OK, passed 200 tests.
--
-- >>> check $ idempotent negate
-- *** Failed! Falsifiable (after 2 tests):
-- 1
idempotent :: Eq a => (a -> a) -> a -> Bool
idempotent f  =  f . f === f

-- | Is the given function an identity? @f x == x@
--
-- > holds n $ identity (+0)
-- > holds n $ identity (sort :: [()])
-- > holds n $ identity (not . not)
identity :: Eq a => (a -> a) -> a -> Bool
identity f  =  f === id

-- | Is the given function never an identity? @f x /= x@
--
-- > holds n $ neverIdentity not
--
-- > fails n $ neverIdentity negate   -- yes, fails: negate 0 == 0, hah!
--
-- Note: this is not the same as not being an identity.
neverIdentity :: Eq a => (a -> a) -> a -> Bool
neverIdentity  =  (not .) . identity

okEq :: Eq a => a -> a -> a -> Bool
okEq  =  equivalence (==)

okOrd :: Ord a => a -> a -> a -> Bool
okOrd x y z  =  totalOrder (<=) x y z
             && comparison compare x y z
             && (x <= y) == ((x `compare` y) `elem` [LT,EQ])

okEqOrd :: (Eq a, Ord a) => a -> a -> a -> Bool
okEqOrd x y z  =  okEq  x y z
               && okOrd x y z
               && (x == y) == (x `compare` y == EQ) -- consistent instances

okNumNonNegative :: (Eq a, Num a) => a -> a -> a -> Bool
okNumNonNegative x y z  =  commutative (+) x y
                        && commutative (*) x y
                        && associative (+) x y z
                        && associative (*) x y z
                        && distributive (*) (+) x y z
                        && idempotent (+0) x
                        && idempotent (*1) x
                        && idempotent abs x
                        && idempotent signum x
                        && abs x * signum x == x

okNum :: (Eq a, Num a) => a -> a -> a -> Bool
okNum x y z  =  okNumNonNegative x y z
             && negate (negate x) == x
             && x - x == 0

-- | Equal under, a ternary operator with the same fixity as '=='.
--
-- > x =$ f $= y  =  f x = f y
--
-- > [1,2,3,4,5] =$  take 2    $= [1,2,4,8,16] -- > True
-- > [1,2,3,4,5] =$  take 3    $= [1,2,4,8,16] -- > False
-- >     [1,2,3] =$    sort    $= [3,2,1]      -- > True
-- >          42 =$ (`mod` 10) $= 16842        -- > True
-- >          42 =$ (`mod`  9) $= 16842        -- > False
-- >         'a' =$  isLetter  $= 'b'          -- > True
-- >         'a' =$  isLetter  $= '1'          -- > False
(=$) :: Eq b => a -> (a -> b) -> a -> Bool
(x =$ f) y  =  f x == f y
infixl 4 =$

-- | See '=$'
($=) :: (a -> Bool) -> a -> Bool
($=)  =  ($)
infixl 4 $=

-- | Check if two lists are equal for @n@ values.
--   This operator has the same fixity of '=='.
--
-- > xs =| n |= ys  =  take n xs == take n ys
--
-- > [1,2,3,4,5] =| 2 |= [1,2,4,8,16] -- > True
-- > [1,2,3,4,5] =| 3 |= [1,2,4,8,16] -- > False
(=|) :: Eq a => [a] -> Int -> [a] -> Bool
xs =| n  =  xs =$ take n
infixl 4 =|

-- | See '=|'
(|=) :: (a -> Bool) -> a -> Bool
(|=)  =  ($)
infixl 4 |=
