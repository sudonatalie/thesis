\chapter{Inlining Projections}
\label{cha:inline_proj}

\edcomm{WK}{You never write two headings immediately after each other.
An overview of this chapter is missing here. This could even incorporate 4.1.}

\section{Usage}

We added the option:

\begin{verbatim}
--inline-proj                               inline proper projections
\end{verbatim}

to our Agda branch which, when enabled, will replace every call to a function that is a proper projection with its function body.

\section{Logical Representation}

The logical representation of inlining is fairly straightforward.
We recurse through the treeless representation of an Agda module.
For every application of a function or datatype to a list of arguments,
that is $d~t^*$ \ecomm{WK}{Change $t*$ to $t_1\ \ldots\ t_n$?},
where $d$ is the name of a function or datatype,
and $t$s are treeless terms,
we replace $d~t^*$
with the function or datatype definition corresponding to $d$
and substitute in the $t^*$ arguments.

\section{Implementation}

It is worth noting that the only projections which we identify and inline are ``proper projections'', that is, we do not include projection-like functions, or record field values, i.e. projections applied to an argument.

The only major complication in implementing the projection inlining optimisation is accounting for the potential for recursive inlining to loop, resulting in non-termination of compilation. Therefore, when inlining projections, we maintain an environment of previously inlined projections and avoid inlining the same projection more than one level deep.

For a complete listing of our implementation of the projection inlining optimisation, refer to Appendix~\ref{app:to_treeless}. The |Agda.Compiler.ToTreeless| module is responsible for converting Agda's internal syntax to the treeless syntax. It is during this translation that other manual forms of definition inlining are performed, so we introduce our optimisation as an additional guard on translating internal |Def|s, which checks whether the definition is a projection, and performs inlining if it  is.

\section{Application}

RATH-Agda is a basic category and allegory theory library developed by \citet{Kahl-2017_RATH-Agda-2.2}. It includes theories relating to semigroupoids, division allegories, typed Kleene algebras and monoidal categories, among other topics. The RATH-Agda repository also provides a set of test cases in a \AgdaModule{Main} module, which can be used to test a variety of typical uses of the library's functions.

\subsection{Before}

In profiling the runtime of this \AgdaModule{Main} module, we found that an inordinate amount of time was spent on evaluating simple record projections. The first few lines of the profiling report in Figure~\ref{fig:main_prof} indicate that the greatest cost centres in terms of time are the two simple record projections for the $\Sigma$ data type, with a combined 17.6\% of execution time spent evaluating them.

Because enabling profiling does have an affect on execution, we also re-compiled the module without profiling and ran it six times, measuring execution time with the Unix @time@ command, to determine its average runtime as 1.60 seconds.

\input{Figures/Output/MainProf}

\subsection{After}

By compiling \AgdaModule{Main} with our new option, @--inline-proj@, enabled, we reduced total runtime and memory allocation, as can be seen by comparing Figure~\ref{fig:main_inline_prof} and Figure~\ref{fig:main_prof}.

We again re-compiled the module without profiling and ran it six times, measuring execution time with the Unix @time@ command, to determine its average runtime with projections inlined as 1.44 seconds. We therefore produced a speedup of 1.11$\times$.

\input{Figures/Output/MainInlineProf}
