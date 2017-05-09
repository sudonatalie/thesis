\begin{figure}
\begin{code}
module Inline1 where

open import Data.Nat
open import Data.Nat.Show

open import IO

record Pair (A : Set) (B : Set) : Set where
  constructor _,_
  field
    fst : A
    snd : B

p : Pair ℕ ℕ
p = 0 , 1

main = run (putStrLn (show (Pair.snd p)))
\end{code}

\caption{A simple record projection in Agda.}
\label{code:inline1}
\end{figure}
