\begin{figure}
\begin{code}
module Example1 where

data ℕ : Set where
  zero : ℕ
  suc : ℕ → ℕ

record Pair (A : Set) (B : Set) : Set where
  constructor _,_
  field
    fst : A
    snd : B

open Pair

f : Pair (ℕ → ℕ) ℕ → ℕ
f z = fst z (snd z)
\end{code}

\caption{A simple record projection in Agda.}
\label{code:example1_agda}
\end{figure}
