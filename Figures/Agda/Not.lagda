\begin{figure}
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

\begin{figure}
\begin{verbatim}
case ru(0) of
  Not.𝔹.true -> done[] Not.𝔹.false
  Not.𝔹.false -> done[] Not.𝔹.true
\end{verbatim}
\caption{Compiled clauses of the \AgdaFunction{not} function.}
\label{code:not_cc}
\end{figure}

\begin{figure}
\begin{verbatim}
Not.not =
  λ a →
    case a of
      Not.𝔹.true → Not.𝔹.false
      Not.𝔹.false → Not.𝔹.true
\end{verbatim}
\caption{Treeless term of the \AgdaFunction{not} function.}
\label{code:not_tterm}
\end{figure}
