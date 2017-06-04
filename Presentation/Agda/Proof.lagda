\begin{comment}
\begin{code}
module Proof where

open import Data.Nat
open import Relation.Binary.PropositionalEquality
open import RATH.Data.Product
open import RATH.PropositionalEquality
\end{code}
\end{comment}

\begin{code}
proof =
  ≡-begin
    zero
  ≡⟨ ≡-refl ⟩
    zero
  ≡∎
\end{code}
