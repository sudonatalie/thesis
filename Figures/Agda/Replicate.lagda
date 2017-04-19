\begin{figure}

\begin{comment}
\begin{code}
module Replicate where

open import Data.Nat
open import Data.Vec hiding (replicate)
\end{code}
\end{comment}

\begin{code}
replicate : ∀ {A : Set} (n : ℕ) → (x : A) → Vec A n
replicate zero    x = []
replicate (suc n) x = x ∷ replicate n x
\end{code}

\caption{The \AgdaFunction{replicate} function in Agda.}
\label{code:replicate}
\end{figure}
