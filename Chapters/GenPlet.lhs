\chapter{Generating Pattern Lets}
\label{cha:logical_plet}

\section{Usage}

We added the options:

\begin{verbatim}
--abstract-plet                             abstract pattern lets in generated code
--ghc-generate-pattern-let                  make the GHC backend generate pattern lets
\end{verbatim}

to our Agda branch which, when enabled together, will generate pattern lets in the GHC backend during compilation.

\section{Logical Representation}

We can avoid generating certain trivial case expressions by identifying let expressions with the following attributes:
\begin{itemize}
  \item the body of the |let| expression is a |case| expression;
  \item the case expression is scrutinising the variable just bound by the enclosing |let|;
  \item only one case alternative exists, a constructor alternative; and
  \item the default case is marked as \textit{unreachable}.
\end{itemize}

Figure~\ref{fig:plet_rule} shows the rule for generating an optimised Haskell expression given a treeless expression with the above properties.

\begin{figure}[h]
\centering
\begin{subfigure}{.47\textwidth}
\begin{spec}
let x = e
in case x of
  d v0...vn -> t
  otherwise -> u
\end{spec}
where |unreachable(u) == true|.
\end{subfigure}
{\large$\to$}
\begin{subfigure}{.47\textwidth}
\begin{spec}
let x@(d v0...vn) = e
in t
\end{spec}
\end{subfigure}
\caption{Generating pattern lets rule.}
\label{fig:plet_rule}
\end{figure}

Note that branches may be marked |unreachable| if they are absurd branches or just to fill in missing case defaults which cannot be reached.

It is worth noting that this optimisation changes the evaluation sequence of subexpressions and, with Haskell semantics, could amount to the different between a terminating and non-terminating expression. However, because we're operating on Haskell generated from an Agda program that has already been checked for termination, this semantics change is less dangerous.

Our treeless syntax does not support pattern matching, but when these cases are identified before transforming into Haskell expressions, we can replace them with ``pattern lets'', removing an unnecessary case expression, and immediately binding the appropriate constructor parameters in the enclosing |let| expression.

These generated pattern lets have two-fold benefits. Firstly, their use reduces the amount of case analysis required in execution, which saves both the time and space needed to run. Secondly, it creates significant opportunities for increasing sharing of expression evaluations which could not have been found when they were |case| expressions. This leads us to our next optimisation, pattern let floating, discussed in Section~\ref{cha:plet-floating}.

\section{Implementation}

The |Agda.Compiler.MAlonzo.Compiler| module is responsible for transforming Agda treeless terms into Haskell expressions. In the primary function for this compilation, we introduced a new alternative that matches on terms with potential to be transformed into pattern lets. In order to be a suitable candidate for this optimisation, a |let| expression must exhibit the properties described in section~\ref{cha:logical_plet}. Because these Agda terms used de Bruijn indexed variables, that means the case expression should be scrutinising the 0 (most recently bound) variable, and the requirements can thus be represented with a pattern matching expression |TLet _ (TCase 0 _ _ [TACon _ _ _])|, followed by a check that the default branch is unreachable.

For a complete listing of our implementation of the pattern let generating optimisation, refer to Appendix~\ref{app:compiler}.

\section{Application}

Triangle3sPB gives us an sample usage of mathematical pullbacks, by constructing triangle-shaped graphs and products of those graphs, as an example. These types of computations are relevant and important in many graph-rewriting calculations and can benefit from our optimisations.

When we compile this module once without @--ghc-generate-pattern-let@ on, and once again with @--ghc-generate-pattern-let@ enabled, a unified diff of the two generated Haskell files gives us what is shown in Figure~\ref{fig:Triangle_genplet}. Both times, the module was compiled with @--inline-proj@.

\begin{figure}[h]
    \centering
    \lstinputlisting[style=diff]{Figures/Triangle_genplet.diff}
    \caption{Unified difference of the \AgdaModule{Triangle3sPB}~module compiled without and then with @--ghc-generate-pattern-let@.}
    \label{fig:Triangle_genplet}
\end{figure}

As is shown by this difference, the case analysis on |v0| is no longer required and instead the constructor parameters are immediately bound in the enclosing |let| expression.
