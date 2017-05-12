\begin{figure}

\begin{comment}
\begin{code}
module If where

open import Data.Bool hiding (if_then_else_)
\end{code}
\end{comment}

\begin{code}
if_then_else_ : ∀ {A : Set} → Bool → A → A → A
if true  then t else f = t
if false then t else f = f
\end{code}

\caption{The \AgdaFunction{if\_then\_else\_}~function in Agda.}
\label{code:if_function}
\end{figure}
