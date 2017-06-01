\begin{spec}
t  ::=  x                          -- variable
   |  d                            -- function or datatype name
   |  t t*                         -- application
   |  \ x -> t                     -- lambda abstraction
   |  l                            -- literal
   |  let x = t in t               -- let
   |  case x of a* otherwise -> t  -- case

a  ::=  d v1...vn -> t             -- constructor alternative
   |  l -> t                       -- literal alternative
\end{spec}
