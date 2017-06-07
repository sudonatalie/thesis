\chapter{Case Squash.hs}
\label{app:case_squash}

The following is a listing for our case squashing optimisation, which we
developed as a separate module, |Agda.Compiler.Treeless.CaseSquash|. The
|squashCases| function in this module removes repeated case expressions that are
nested and match on the same variable. It is called as part of the pipeline of
|ToTreeless| optimisations in the separate Agda compiler branch we maintain for
this project, which does not include the later implemented case squashing
simplification now present in the Agda stable branches.

\begin{code}
{-# LANGUAGE CPP, PatternGuards #-}

module Agda.Compiler.Treeless.CaseSquash (squashCases) where

import Agda.Syntax.Abstract.Name (QName)
import Agda.Syntax.Treeless

import Agda.TypeChecking.Substitute
import Agda.TypeChecking.Monad as TCM

import Agda.Compiler.Treeless.Subst

#include "undefined.h"
import Agda.Utils.Impossible
\end{code}

Eliminates case expressions where the scrutinee has already
been matched on by an enclosing parent case expression.

\begin{code}
squashCases :: QName -> TTerm -> TCM TTerm
squashCases q body = return $ dedupTerm [] body
\end{code}

Case scrutinee (De Bruijn index) with alternative match
for that expression, made up of qualified name of constructor
and a list of its arguments (also as De Bruijn indices)

\begin{code}
type CaseMatch = (Int, (QName, [Int]))
\end{code}

Environment containing |CaseMatch|es in scope.

\begin{code}
type Env = [CaseMatch]
\end{code}

Recurse through |TTerm|s, accumulting environment of case alternatives
matched and replacing repeated cases.
De Bruijn indices in environment should be appropriatedly shifted as
terms are traversed.

\begin{code}
dedupTerm :: Env -> TTerm -> TTerm
-- Increment indices in scope to account for newly bound variable
dedupTerm env (TLam tt) = TLam (dedupTerm (shiftIndices (+1) <$> env) tt)
dedupTerm env (TLet tt1 tt2) = TLet (dedupTerm env tt1)
  (dedupTerm (shiftIndices (+1) <$> env) tt2)
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
\end{code}

Find the alternative with matching name and replace case term with its body
(after necessary substitutions), if it exists.

\begin{code}
caseReplacement :: (QName, [Int]) -> TTerm -> TTerm
caseReplacement (name, args) tt@(TCase _ _ _ alts)
  | Just (TACon _ ar body) <- lookupTACon name alts
  = varReplace [ar-1,ar-2..0] args body
caseReplacement _ tt = tt
\end{code}

Lookup |TACon| in list of |TAlt|s by qualified name

\begin{code}
lookupTACon :: QName -> [TAlt] -> Maybe TAlt
lookupTACon match ((alt@(TACon name ar body)):alts) | match == name = Just alt
lookupTACon match (_:alts) = lookupTACon match alts
lookupTACon _ [] = Nothing
\end{code}

Introduce new constructor matches into environment scope

\begin{code}
dedupAlt :: Int -> Env -> TAlt -> TAlt
dedupAlt sc env (TACon name ar body) =
  let env' = (sc + ar, (name, [ar-1,ar-2..0])):(shiftIndices (+ar) <$> env)
  in TACon name ar (dedupTerm env' body)
dedupAlt sc env (TAGuard guard body) = TAGuard guard (dedupTerm env body)
dedupAlt sc env (TALit lit body) = TALit lit (dedupTerm env body)
\end{code}

Shift all De Bruijn indices in a case match according to provided
function on integers

\begin{code}
shiftIndices :: (Int -> Int) -> CaseMatch -> CaseMatch
shiftIndices f (sc, (name, vars)) = (f sc, (name, map f vars))
\end{code}

Substitute list of current De Bruijn indices for list of new indices
in a term

\begin{code}
varReplace :: [Int] -> [Int] -> TTerm -> TTerm
varReplace (from:froms) (to:tos) = varReplace froms tos . subst from (TVar to)
varReplace [] [] = id
varReplace _ _ = __IMPOSSIBLE__
\end{code}
