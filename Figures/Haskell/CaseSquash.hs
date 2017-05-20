{-# LANGUAGE CPP, PatternGuards #-}

module Agda.Compiler.Treeless.CaseSquash (squashCases) where

import Agda.Syntax.Abstract.Name (QName)
import Agda.Syntax.Treeless

import Agda.TypeChecking.Substitute
import Agda.TypeChecking.Monad as TCM

import Agda.Compiler.Treeless.Subst

#include "undefined.h"
import Agda.Utils.Impossible

-- | Eliminates case expressions where the scrutinee has already
-- been matched on by an enclosing parent case expression.
squashCases :: QName -> TTerm -> TCM TTerm
squashCases q body = return $ dedupTerm [] body

-- | Case scrutinee (de Bruijn index) with alternative match
--   for that expression, made up of qualified name of constructor
--   and a list of its arguments (also as de Bruijn indices)
type CaseMatch = (Int, (QName, [Int]))

-- | Environment containing 'CaseMatch'es in scope.
type Env = [CaseMatch]

-- | Recurse through 'TTerm's, accumulting environment of case alternatives
--   matched and replacing repeated cases.
--   De Bruijn indices in environment should be appropriatedly shifted as
--   terms are traversed.
dedupTerm :: Env -> TTerm -> TTerm
-- Increment indices in scope to account for newly bound variable
dedupTerm env (TLam tt) = TLam (dedupTerm (shiftIndices (+1) <$> env) tt)
dedupTerm env (TLet tt1 tt2) = TLet (dedupTerm env tt1) (dedupTerm (shiftIndices (+1) <$> env) tt2)
-- Check if scrutinee is already in scope
dedupTerm env body@(TCase sc t def alts) = case lookup sc env of
  -- If in scope with match then substitute body
  Just match -> caseReplacement match body
  -- Otherwise add to scope in alt branches
  Nothing -> TCase sc t
    (dedupTerm env def)
    (map (dedupAlt sc env) alts)
-- Continue traversing nested terms in applications
dedupTerm env (TApp tt args) = TApp (dedupTerm env tt) (map (dedupTerm env) args)
dedupTerm env body = body

-- | Find the alternative with matching name and replace case term with its body
--   (after necessary substitutions), if it exists.
caseReplacement :: (QName, [Int]) -> TTerm -> TTerm
caseReplacement (name, args) tt@(TCase _ _ _ alts)
  | Just (TACon _ ar body) <- lookupTACon name alts
  = varReplace [ar-1,ar-2..0] args body
caseReplacement _ tt = tt

-- | Lookup 'TACon' in list of 'TAlt's by qualified name
lookupTACon :: QName -> [TAlt] -> Maybe TAlt
lookupTACon match ((alt@(TACon name ar body)):alts) | match == name = Just alt
lookupTACon match (_:alts) = lookupTACon match alts
lookupTACon _ [] = Nothing

-- | Introduce new constructor matches into environment scope
dedupAlt :: Int -> Env -> TAlt -> TAlt
dedupAlt sc env (TACon name ar body) =
  let env' = (sc + ar, (name, [ar-1,ar-2..0])):(shiftIndices (+ar) <$> env)
  in TACon name ar (dedupTerm env' body)
dedupAlt sc env (TAGuard guard body) = TAGuard guard (dedupTerm env body)
dedupAlt sc env (TALit lit body) = TALit lit (dedupTerm env body)

-- | Shift all de Bruijn indices in a case match according to provided
--   function on integers
shiftIndices :: (Int -> Int) -> CaseMatch -> CaseMatch
shiftIndices f (sc, (name, vars)) = (f sc, (name, map f vars))

-- | Substitute list of current de Bruijn indices for list of new indices
--   in a term
varReplace :: [Int] -> [Int] -> TTerm -> TTerm
varReplace (from:froms) (to:tos) = varReplace froms tos . subst from (TVar to)
varReplace [] [] = id
varReplace _ _ = __IMPOSSIBLE__
