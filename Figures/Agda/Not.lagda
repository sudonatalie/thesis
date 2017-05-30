\begin{figure}[h!]
\begin{code}
module Not where

data 𝔹 : Set where
  true : 𝔹
  false : 𝔹

not : 𝔹 → 𝔹
not true = false
not false = true
\end{code}

\caption{Simple boolean data type and negation function in Agda.}
\label{code:not_agda}
\end{figure}
