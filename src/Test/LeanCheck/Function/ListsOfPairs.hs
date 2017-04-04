-- |
-- Module      : Test.LeanCheck.Function.ListsOfPairs
-- Copyright   : (c) 2015-2017 Rudy Matela
-- License     : 3-Clause BSD  (see the file LICENSE)
-- Maintainer  : Rudy Matela <rudy@matela.com.br>
--
-- This module is part of LeanCheck,
-- a simple enumerative property-based testing library.
--
-- This module exports a 'Listable' instance for function enumeration
-- via lists of pairs.
--
-- This module considers functions as a finite list of exceptional input-output
-- cases to a default value (list of pairs of arguments and results).
module Test.LeanCheck.Function.ListsOfPairs
  ( functionPairs
  , associations
  )
where

import Test.LeanCheck
import Test.LeanCheck.Tiers
import Data.Maybe (fromMaybe)

instance (Eq a, Listable a, Listable b) => Listable (a -> b) where
  tiers = functions tiers tiers


functions :: Eq a => [[a]] -> [[b]] -> [[a->b]]
functions xss yss =
  concatMapT
    (\(r,yss) -> mapT (const r `mutate`) (functionPairs xss yss))
    (choices yss)


mutate :: Eq a => (a -> b) -> [(a,b)] -> (a -> b)
mutate f ms = foldr mut f ms
  where
  mut (x',fx') f x = if x == x' then fx' else f x


-- | Given a list of domain values, and tiers of codomain values,
-- return tiers of lists of ordered pairs of domain and codomain values.
--
-- Technically: tiers of left-total functional relations.
associations :: [a] -> [[b]] -> [[ [(a,b)] ]]
associations xs sbs = zip xs `mapT` products (const sbs `map` xs)

-- | Given tiers of input values and tiers of output values,
-- return tiers with all possible lists of input-output pairs.
-- Those represent functional relations.
functionPairs :: [[a]] -> [[b]] -> [[[(a,b)]]]
functionPairs xss yss = concatMapT (`associations` yss) (incompleteSetsOf xss)

-- | Returns tiers of sets excluding the universe set.
--
-- > incompleteSetsOf (tiers :: [[Bool]])  =  [[],[[False],[True]],[]]
-- > incompleteSetsOf (tiers :: [[()]])    =  [[]]
incompleteSetsOf :: [[a]] -> [[[a]]]
incompleteSetsOf xss
  | finite xs = setsOf xss `suchThat` (\xs' -> length xs' < length xs)
  | otherwise = setsOf xss
  where
  xs = concat xss
  -- A list with more than 12 elements is considered infinite.
  -- alas, if only we had lazy natural numbers!
  finite (_:_:_:_: _:_:_:_: _:_:_:_: _) = False
  finite _                              = True
