\chapter{Compiler.hs (abridged)}
\label{app:compiler}

\begin{code}
{-# LANGUAGE CPP, PatternGuards #-}

module Agda.Compiler.MAlonzo.Compiler where

{-
...
-}

--   In @addAsPats xs numBound tp pat@, recurse through @tp@ to find all
--   single constructor @TCase@s and replace @PVar@s of the same scrutinee
--   with appropriate @PAsPat@s, until @TErased@ is reached.
--   @xs@ contains all necessary variables introduce by the initial call
--   in @term@, with @numBound@ indicating the number of introduced
--   of variables introduced by the caller used in @PApp@s and the top let.
addAsPats :: [HS.Name] -> Nat -> TTerm -> HS.Pat -> CC HS.Pat
addAsPats xs numBound
  tp@(TCase sc _ _ [TACon c cArity tp'])
  pat = case xs !!! (numBound - 1 - sc) of
    Just scName -> do
      erased <- lift $ getErasedConArgs c
      hConNm <- lift $ conhqn c
      let oldPat = HS.PVar scName
      let vars = take cArity $ drop numBound xs
      let newPat = HS.PAsPat scName $ HS.PApp hConNm $ map HS.PVar [ x | (x, False) <- zip vars erased ]
      let pat' = replacePats oldPat newPat pat
      addAsPats xs (numBound + cArity) tp' pat'
    Nothing -> __IMPOSSIBLE__
addAsPats _ _ TErased pat = return pat
addAsPats _ _ _ _ = __IMPOSSIBLE__ -- Guaranteed by splitPLet

--   In @replacePats old new p@, replace all instances of @old@ in @p@
--   with @new@
replacePats :: HS.Pat -> HS.Pat -> HS.Pat -> HS.Pat
replacePats old new p@(HS.PVar _) = if old == p then new else p
replacePats old new (HS.PAsPat sc p) = HS.PAsPat sc $ replacePats old new p
replacePats old new p@(HS.PApp q pats) =
  HS.PApp q $ map (replacePats old new) pats
replacePats _ _ p = __IMPOSSIBLE__ -- Guaranteed by addAsPats

--   Extract Agda term to Haskell expression.
--   Erased arguments are extracted as @()@.
--   Types are extracted as @()@.
term :: T.TTerm -> CC HS.Exp
term tm0 = asks ccGenPLet >>= \ genPLet -> case tm0 of
  {-...-}
  TLet _ (TCase 0 _ _ [TACon _ _ _])
    | genPLet
    , Just (PLet {pletNumBinders = numBinders, eTerm = TLet t1 tp}, tb) <- splitPLet tm0
    -> do
        t1' <- term t1
        intros 1 $ \[x] -> do
          intros numBinders $ \xs -> do
            tb' <- term tb
            p <- addAsPats (x:xs) 1 tp (HS.PVar x)
            return $ hsPLet p (hsCast t1') tb'
  {-...-}

{-
...
-}
\end{code}
