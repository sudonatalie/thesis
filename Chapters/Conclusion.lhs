\chapter{Conclusion}
\label{cha:conclusion}

In this chapter, we discuss various aspects of our optimisations in summary. In
Section~\ref{sec:assessment_of_the_contributions}, we assess the strengths and
weaknesses of the main contributions. In Section~\ref{sec:future_work}, we
discuss future work that could follow this project. Finally, in
Section~\ref{sec:closing_remarks}, we draw conclusions from the thesis and give
some closing remarks.

\section{Assessment of the Contributions}
\label{sec:assessment_of_the_contributions}

%\subsection{Strengths of the Contributions}
%\label{sub:strengths_of_the_contributions}

The contributions described herein have a number of strengths that will serve
the Agda development community.

Primarily, as shown by the results of the applications of our optimisations, our
optimisations will reduce the runtime execution and heap allocation requirements
of many Agda programs%
% with a negligible impact on compile time
%\edcomm{WK}{I don't recall where you showed measurements\ldots}
, and do not show adverse
effects in any of the tests we have performed.

Secondarily, this thesis may also serve as a detailed documentation of the
portions of the Agda compiler and GHC backend that are necessary to understand
for incorporating future optimising transformations. We hope that future
contributors to Agda will find this presentation of our study of the Agda
compiler useful in implementing their own desired optimisations.

%\subsection{Weaknesses of the Contributions}
%\label{sub:weaknesses_of_the_contributions}

Although the net effect of our optimisations is a positive one, there are still
a number of weaknesses that warrant consideration.

A clear weakness of our case squashing optimisation is its isolated
implementation. Because it was developed as an independent transformation, it
requires an additional traversal of the treeless terms to execute. Further, some
of the logic built to deal with the handling of de Bruijn indices would have
been avoidable had it been built as part of an existing set of optimisations
that had similar optimisation helper functions already developed. As presented
in Subsection~\ref{sub:alternate_case_squash}, an independent version of case
squashing has since been developed and introduced into the Agda compiler, as
part of the |Agda.Compiler.Treeless.Simplify| module, which addresses both of
these weaknesses.

Both the projection inlining and case squashing optimisations make use of
accumulated environment parameters, which can be handled more modularly and
appropriately using monads. This potential for code refactoring is discussed
further in Section~\ref{sec:future_work}.

\section{Future Work} \label{sec:future_work}

In our implementations of projection inlining and case squashing, we noted that
environments of relevant information were carried through graph traversal. For
projection inlining, this was an environment of previously inlined projections
is maintained to avoid looping on recursive inlining calls. For case squashing,
this was an environment of previously met cases expressions. These environments
are currently maintained as a list objects, passed from function call to
function call. For modularity and maintainability of the code, these
environments would be better refactored into reader monad transformers, which
would allow an inherited environment to be bound to the function results and
passed through to subcomputations via the given monad.

Additionally, our floating optimisations would benefit
from recognizing single-alternative case expressions
which are not immediately nested within an enclosing let expression,
as described in Chapter~\ref{cha:plet-floating}.
In the future, we also seek to expand this optimisation's transformation to
generate ``dummy'' pattern let expressions around said case expressions before
executing the floating transformations.

Further testing of all optimisations on a greater variety of
Agda codebases is also a necessary next step before they can be safely
integrated with a stable release branch of the compiler.

\section{Closing Remarks} \label{sec:closing_remarks}

We have implemented, tested, and profiled a series of optimisations to the Agda
compiler which improve execution time and reduce memory usage for many of the
Agda programs tested, and have no negative performance effects in any of our
tests.

Our optimisations
%have a negligible impact on compile time, and
serve previously unmet needs of our team as well as many other Agda developers
by re-introducing some of the ``lost'' value sharing without affecting the
type-theoretic semantics of Agda programs.

We hope that the development and discussion of these optimisations is
useful to the Agda developer community, and may be helpful for future
contributors interested in implementing new optimisations for Agda.
