\begin{code}
module Composer {A : Set} (f : A → A) where
  twice : A → A
  twice x = f (f x)

  thrice : A → A
  thrice x = f (f (f x))
\end{code}
