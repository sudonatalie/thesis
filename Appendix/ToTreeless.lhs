\chapter{ToTreeless.hs (abridged)}
\label{app:to_treeless}

The abridged code listing below for the the |Agda.Compiler.ToTreeless| module
documents our projection inlining optimisation. This optimisation replaces every
call to a function that is a proper projection with its function body. The
transformation occurs during the translation to |Treeless| syntax.

\begin{code}
{-# LANGUAGE CPP #-}

module Agda.Compiler.ToTreeless
  ( toTreeless
  , closedTermToTreeless
  ) where
\end{code}

|closedTermToTreeless| is called to transform the Agda internal syntax to
|TTerm|s. It calls |substTerm|, which we show a segment of below indicating the
point at which |maybeInlineDef| is called.

\begin{code}
closedTermToTreeless :: I.Term -> TCM C.TTerm
closedTermToTreeless t = do
  substTerm [] t `runReaderT` initCCEnv

substTerm :: ProjInfo -> I.Term -> CC C.TTerm
substTerm inlinedAncestors term = normaliseStatic term >>= \ term ->
  case I.ignoreSharing $ I.unSpine term of
    {-...-}
    I.Def q es -> do
      let args = fromMaybe __IMPOSSIBLE__ $ I.allApplyElims es
      maybeInlineDef inlinedAncestors q args
    {-...-}
\end{code}

We create the datatype |ProjInfo| for maintaining an environment of previously inlined definitions.

\begin{code}
type ProjInfo = [(I.QName, (I.Args, Definition))]
\end{code}

By modifying |maybeInlineDef| with an additional guard for |isProperProjection fun && doInlineProj|, we call the existing |doinline| function, adapted to account for the already inlined ancestors environment.

\begin{code}
maybeInlineDef :: ProjInfo -> I.QName -> I.Args -> CC C.TTerm
maybeInlineDef inlinedAncestors q vs =
  ifM (lift $ alwaysInline q) (doinline inlinedAncestors) $ do
    lift $ cacheTreeless q
    def <- lift $ getConstInfo q
    doInlineProj <- optInlineProj <$> lift commandLineOptions
    case theDef def of
      fun@Function{}
        | fun ^. funInline -> doinline []
        | isProperProjection fun && doInlineProj
        -> do
            lift $ reportSDoc "treeless.inline" 20 $
              text "-- inlining projection" $$ prettyPure (defName def)
            doinline inlinedAncestors
        | otherwise -> defaultCase
      _ -> C.mkTApp (C.TDef C.TDefDefault q) <$> substArgs inlinedAncestors vs
  where
    updatedAncestors = do
      def <- lift $ getConstInfo q
      return $ (q, (vs, def)) : inlinedAncestors
    doinline inlinedAncestors = do
      ancestors <- updatedAncestors
      case (q `lookup` inlinedAncestors) of
        Nothing -> C.mkTApp <$> inline q <*> substArgs ancestors vs
        Just _ -> defaultCase
    inline :: QName -> CC C.TTerm
    inline q = lift $ toTreeless' q
    defaultCase = do
            _ <- lift $ toTreeless' q
            used <- lift $ getCompiledArgUse q
            let substUsed False _   = pure C.TErased
                substUsed True  arg = substArg inlinedAncestors arg
            C.mkTApp (C.TDef C.TDefDefault q) <$>
              sequence [ substUsed u arg | (arg, u) <- zip vs $ used ++ repeat True ]

substArgs :: ProjInfo -> [Arg I.Term] -> CC [C.TTerm]
substArgs = traverse . substArg

substArg :: ProjInfo -> Arg I.Term -> CC C.TTerm
substArg inlinedAncestors x | erasable x     = return C.TErased
                            | otherwise      = substTerm inlinedAncestors (unArg x)
\end{code}
