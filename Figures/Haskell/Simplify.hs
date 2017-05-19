{-# LANGUAGE CPP #-}
module Agda.Compiler.Treeless.Simplify (simplifyTTerm) where

{-
...
-}

simplifyTTerm :: TTerm -> TCM TTerm
simplifyTTerm t = do
  {-...-}
  return $ runS $ simplify kit t

addRewrite :: TTerm -> TTerm -> S a -> S a
addRewrite lhs rhs = local $ \ env -> env { envRewrite = (lhs, rhs) : envRewrite env }

bindVar :: Int -> TTerm -> S a -> S a
bindVar x u = onSubst (inplaceS x u `composeS`)

rewrite :: TTerm -> S TTerm
rewrite t = do
  rules <- asks envRewrite
  case [ rhs | (lhs, rhs) <- rules, equalTerms t lhs ] of
    rhs : _ -> pure rhs
    []      -> pure t

simplify :: FunctionKit -> TTerm -> S TTerm
simplify FunctionKit{..} = simpl
  where
    simpl = rewrite' >=> unchainCase >=> \ t -> case t of
      {-...-}
      TCase x t d bs -> do
        v <- lookupVar x
        let (lets, u) = tLetView v
        case u of
          {-...-}
          _ -> do
            d  <- simpl d
            bs <- traverse (simplAlt x) bs
            tCase x t d bs
            
      {-...-}
    rewrite' t = rewrite =<< simplPrim t

    simplAlt x (TACon c a b) = TACon c a <$> underLams a (maybeAddRewrite (x + a) conTerm $ simpl b)
      where conTerm = mkTApp (TCon c) [TVar i | i <- reverse $ take a [0..]]
    simplAlt x (TALit l b)   = TALit l   <$> maybeAddRewrite x (TLit l) (simpl b)
    simplAlt x (TAGuard g b) = TAGuard   <$> simpl g <*> simpl b

    -- If x is already bound we add a rewrite, otherwise we bind x to rhs.
    maybeAddRewrite x rhs cont = do
      v <- lookupVar x
      case v of
        TVar y | x == y -> bindVar x rhs $ cont
        _ -> addRewrite v rhs cont
