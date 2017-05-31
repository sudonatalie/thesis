\begin{figure}[h]
\begin{code}
module Sharing where

data ℕ : Set where
  zero : ℕ
  suc : ℕ → ℕ

_+_ : ℕ → ℕ → ℕ
zero + n = n
suc m + n = suc (m + n)

one = suc zero

four = let two = one + one
       in two + two
\end{code}
\caption{Simple Agda example where sharing is ``lost''.}
\label{code:sharing_agda}
\end{figure}
