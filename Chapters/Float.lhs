\chapter{Pattern Let Floating}
\label{cha:plet-floating}

In this chapter we present our pattern let floating optimisation. In Section~\ref{sec:float_usage} we give usage instructions. In Section~\ref{sec:float_logical} we show a logical representation of the transformation. In Section~\ref{sec:float_implement} we provide some implementation details pertaining to the optimisation.
Lastly, in Section~\ref{sec:float_app} we apply pattern let floating to a sample program and examine the results.

\section{Usage}
\label{sec:float_usage}

We added the option:

\begin{verbatim}
--abstract-plet       abstract pattern lets in generated code
\end{verbatim}
which splits generated function definitions into two functions,
the first containing only the top-level pattern bindings and a call to the second, and the second containing only the original body inside those pattern bindings, dependent on the additional variables bound in those patterns.

We also added:

\begin{verbatim}
--float-plet          float pattern lets to remove duplication
\end{verbatim}

to our Agda branch which, when enabled, will float the pattern lets up through the abstract syntax tree to join with other bindings for the same expression.

In combination with our option:
\begin{verbatim}
--cross-call-float          float pattern bindings across function calls
\end{verbatim}

that is currently under development,
bindings can also be shared across function calls.

\section{Logical Representation}
\label{sec:float_logical}

Figure~\ref{fig:float_example} shows an example of floating pattern lets to a join point to increase sharing.

\begin{figure}[h]
\centering
\begin{subfigure}{.47\textwidth}
\begin{spec}
f  (let x@(d v0...vn) =  e in t1)
   (let x@(d v0...vn) =  e in t2)
\end{spec}
\end{subfigure}
{$\longrightarrow$}
\begin{subfigure}{.47\textwidth}
\begin{spec}
let x@(d v0...vn) = e
in f t1 t2
\end{spec}
\end{subfigure}
\caption{Floating pattern lets example.}
\label{fig:float_example}
\end{figure}

Pattern let floating combines the benefits of pattern lets, described in
Chapter~\ref{cha:gen_plet}, with the benefits of floating described in
Section~\ref{sec:let_floating}. We take inspiration from \citet{jones1996}'s
``Full laziness'' transformation in GHC and apply it to the code generated by
the Agda compiler backend. In our pattern let floating optimisation, we float
the pattern lets as far upwards in an expression tree if and until they can be
joined with another floated pattern let on the same expression.  By doing so, we
avoid re-computing the same expression when it is used in multiple
subexpressions.

\section{Implementation}
\label{sec:float_implement}

There are a couple of implementation-specific details of interest when implementing pattern let floating. Firstly, in order to float pattern lets, we first convert the |TTerm|s into a variant data type using named variables for ease of expression manipulation. Then the entire expression tree is recursed over, floating all $\lambda$ bindings to the top of the expression and accumulating a list of variables in each definition is accumulated.

The |floatPatterns| function will only float pattern lets which occur in multiple branches, and they are floated to the least join point of those branches.

Further, it is worth noting that pattern let occurrences are duplicated at join
points, indicating that matching pattern lets have ``met'' there. These matching
patterns are then unified and later simplified away with the |squashFloatings|
function. Patterns must have right-hand sides that are equivalent (up to
$\alpha$-conversion) in order to be considered matching.

%{
%format RHS = "\hbox{$\langle\kern-0.4ex\langle$\textit{rhs}$\rangle\kern-0.4ex\rangle$}"
For example, if the following two let bindings are found in separate branches
of the expression tree:

|let a@(b@(c,d),e) = RHS in t1|\\
|let a@(b, c@(d,e)) = RHS in t2|

they will meet at the least join point of their two branches, and be unified
into

\begin{spec}
let f@(g@(h,i),j@(k,l)) = RHS in
   ...t1[a := f, b := g, c := h, d := i, e := j]...
   ...t2[a := f, b := g, c := j, d := k, e := l]...
\end{spec}
%}

We are currently working on further expanding the pattern let floating optimisation such that they can not only be floated up expressions, but also across function calls. By floating pattern lets across function calls, we can avoid even more duplicated computation through sharing.

This feature is implemented by splitting the pattern lets at the root of functions into separate pattern lets and a body. By creating secondary functions that take the variables bound by pattern lets and make them explicit arguments to a separate function, we can abstract the patterns across function calls.

\section{Application}
\label{sec:float_app}

The @--abstract-plet@ feature is necessary to split functions into two, with the let-bound variables abstracted out into function arguments of the second function. An example of this is shown in Figure~\ref{fig:pullback_abstract}. This abstraction is what allows cross-call floating to occur.

\begin{figure}[h]
\centering
\lstinputlisting[style=diff]{Figures/Pullback_abstract.diff}
\caption{Unified difference of the \AgdaModule{Pullback}~module compiled without and then with @--abstract-plet@.}
\label{fig:pullback_abstract}
\end{figure}

\newpage

As readers may have noticed inspecting Figure~\ref{fig:Triangle_genplet} in the preceding chapter, there are 4 pattern let bindings for the same \texttt{v2} variable within the \texttt{d4788} function. This is a perfect opportunity for floating pattern lets, to create sharing where there formerly was none.
Figure~\ref{fig:Triangle_float} shows the result of applying @--float-plet@ to this compilation, resulting in the \texttt{v2} bindings floating above the shared function call.

\begin{figure}[h]
\centering
\lstinputlisting[style=diff]{Figures/Triangle_float.diff}
\caption{Unified difference of the \AgdaModule{Triangle3sPB}~module compiled without and then with @--float-plet@.}
\label{fig:Triangle_float}
\end{figure}

\newpage

In Figure~\ref{fig:pullback_cross} we can see the result of cross-call floating on the \AgdaModule{Pullback} module.
Notice that without cross-call floating, a single call to \texttt{du78} would result in two unshared calls to \texttt{du58}, one via \texttt{du60} and one via \texttt{du70}. With cross-call floating, \texttt{du78} calls \texttt{du58} only once, then passes the results via the additional parameters to \texttt{dv78}, which in turn shares the values with both \texttt{dv60} and \texttt{dv70}.

\begin{figure}[h]
\centering
\lstinputlisting[style=diff]{Figures/Pullback_cross.diff}
\caption{Unified difference of the \AgdaModule{Pullback}~module compiled without and then with @--cross-call@.}
\label{fig:pullback_cross}
\end{figure}
