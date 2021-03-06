\chapter{Introduction}
\label{cha:introduction}

In this chapter, we introduce Agda and give an overview of this project. In Section~\ref{sec:intro_agda}, we give an introduction to the Agda programming language and explain its unique characteristics, as well as a brief introduction to its compiler. In Section~\ref{sec:problem_statement}, we state the problem subject of our work. In Section~\ref{sec:motivation}, we give the motivation for the new optimisation strategies introduced here. In Section~\ref{sec:main_contributions}, we summarise our contributions, namely the optimisation strategies we implemented in the Agda compiler. Finally, in Section~\ref{sec:structure_of_the_thesis}, we give the structure of the remainder of the thesis.

\section{Agda}
\label{sec:intro_agda}

Agda \citep{Norell-2007} is a dependently-typed programming language and theorem prover, supporting proof construction in a functional programming style. Due to its incredibly flexible concrete syntax and support for Unicode identifiers \citep{bove2009}, Agda can be used to construct elegant and expressive proofs in a format that is understandable even to those unfamiliar with the tool. As a result, many users of Agda, including our group, are quick to sacrifice speed and efficiency in our code in favour of proof clarity. This makes a highly-optimised compiler backend a particularly essential tool for practical development with Agda.

\subsection{Dependent Types}

\citet{norell2009} discusses the practical usage of dependent types for programming in Agda. Type signatures in Agda support dependent types, which means that types may depend on values. In traditional functional languages, types may depend on other types. For example, the Haskell type signature \lstinline{xs :: Vector a} denotes a vector containing elements of type \lstinline{a}, where \lstinline{a} is a type variable. In a dependently-typed language like Agda types can depend not only on other types, but also on values. Consider the \AgdaFunction{replicate} function in Figure~\ref{code:replicate}, which produces a \AgdaDatatype{Vec}tor of elements of type \AgdaBound{A} with length \AgdaBound{n}. In many languages that don't support dependent types a programmer can represent a parametrised vector type that contains elements of any arbitrary type, however, they cannot represent a parametrised vector type of any arbitrary specific length.

\input{Figures/Agda/latex/Replicate}

\subsection{Type Theory}
The core syntax of Agda is a dependently-typed lambda calculus, with a simple grammar as shown in Figure~\ref{fig:grammar}. Most functional languages, such as Haskell or ML, are built on a foundation of a simply-typed lambda calculus. This basis allows the expression of propositions in mathematical logic as types of a lambda calculus.

By the Curry–Howard correspondence (or the proofs-as-programs interpretation), we can then prove these propositions true by providing an element (program) of its corresponding type \citep{poernomo2005}. Using constructive logic, a proof of a proposition is the construction of an object that is a member of the type representing that proposition. The correspondence between concepts in type theory and concepts in logic can be seen in Table~\ref{table:curry_howard}

\input{Figures/CurryHoward}

The ability for types to contain arbitrary values is significant because it expands the domain of theorems we can encode as types to the space of predicate logic. This allows us to encode almost any proposition or formula as a type.

 In order to ensure this logic holds true for all Agda programs, the Agda type-checker requires that all programs be both total and terminating \citep{norell2009}. Therefore, when an Agda program passes type-checking\footnote{(assuming a correct compiler)}, all of the specifications encoded as propositions in the types of functions are satisfied.

Agda also supports a flexible mix-fix syntax, as seen in Figure~\ref{code:if_function}, and Unicode characters, such as the \AgdaDatatype{ℕ} to represent natural numbers in Figure~\ref{code:replicate}. These features along with Agda's constructive functional style make Agda both an interesting programming language, but also a powerful proof assistant for generating elegant, expressive proofs.

\input{Figures/Agda/latex/If}

\input{Figures/AgdaCore}

\subsection{Compiler}

Agda has a number of available compilers and backends, but the one
that is most efficient and most commonly used is the ``GHC backend'' \citep{benke2007}, originally introduced under the name ``MAlonzo''; this backend generates Haskell with extensions supported by GHC, the ``Glasgow Haskell Compiler'' by \citet{ghc2012}.
This backend
has the goal of compiling Agda code with the performance of
the generated code matching that of GHC, and it does so by translating
Agda into Haskell, so that it can be compiled, and optimised by
GHC. This is a practical and useful arrangement for real-world Agda
usage because GHC has benefited from a massive development effort by a
large community to create a highly performant compiler
\citep{benke2007}.

As discussed in the previous section, Agda provides a more expressive type system than Haskell. Because Agda supports dependent types and Haskell does not, in order for Agda generated code to pass the Haskell type checker, it is necessary for the MAlonzo backend to wrap coercions around all function arguments and all function calls, which cast terms from one type to a different arbitrary type. Unfortunately, these potentially unsafe type coercions mean that there are many GHC optimisations which Agda's generated code is ``missing out on'' \citep{fredriksson2011}.

Some of the Agda optimisations described herein would typically be performed by GHC after translation to Haskell were it not for these coercions, so we instead ensure that we can still take advantage of these optimisations by implementing them in the Agda backend, before the translation to Haskell occurs.

\subsection{Sharing}

In several of our optimisations presented herein, our ultimate goal is
to introduce sharing that was previously ``lost''. Take for example
the simple module below:

\input{Figures/Agda/latex/Sharing}

An Agda developer might, incorrectly, assume that in the calculation
of \AgdaFunction{four}, the \AgdaFunction{+} function would only be
called twice, with the evaluation of \AgdaBound{two} stored and shared
among its two callers. In actuality, the \AgdaKeyword{let} binding is not
necessarily preserved in the translation to Haskell, where sharing
of the locally bound expression would be guaranteed.
Unlike Haskell, Agda does not have any resource-aware semantics.
In the compiled Haskell generated
from the \AgdaModule{Sharing} module, we can see that there are, in fact,
three calls to the generated addition function |d8|, and the semantic
``sharing'' that was implied by the programmer who wrote the
\AgdaKeyword{let} binding has been ``lost'':

%include ../Figures/Haskell/Sharing.lhs

Though this particular illustrative example is not targeted by our
optimizations, because it would require common subexpression elimination
(CSE) to transform, we use examples
like this as motivation for re-creating sharing through compiler
optimisations.

\section{Problem Statement}
\label{sec:problem_statement}

For practical development in Agda, a highly effective optimising compiler backend is a particularly essential tool to avoid performance concerns.

Our work aims to introduce a number of optimising transformations to the Agda internals and backend so that Agda users can continue to focus on elegant syntax and mathematical clarity, and leave the optimisations necessary to transform that code into a program that runs with acceptable heap allocation and execution time to the compiler.

The optimisations we focus on are specifically oriented towards aiding our team's most common, and most costly, uses of the Agda programming language, but they should be useful in a general context for most Agda users.

\section{Motivation}
\label{sec:motivation}

As discussed above, the Agda language is highly conducive to writing elegant and expressive proofs, which leads many users of Agda, including our research group, to avoid code optimisations that may increase speed or efficiency if they have the side effect of reducing proof clarity (which they often do).

As such, the optimisations presented herein are largely motivated by profiling data from our own real-world uses of Agda.

The first, and simplest, such example is the results of profiling a main execution of RATH-Agda. RATH-Agda is a library of category and allegory theories developed by \citet{Kahl-2017_RATH-Agda-2.2} which takes advantage of many features of the Agda programming language's flexibility. In order to achieve its primary goal of natural mathematical clarity and style, it faces, like many Agda programs, performance concerns.

\begin{table}
\begin{center}
\begin{tabular}{ll}
\textbf{COST CENTRE}                                     & \textbf{\%time} \\
Data.Product.\textSigma.proj₂                                     & 13.1            \\
Data.Product.\textSigma.proj₁                                     & 7.5             \\
Data.SUList.ListSetMap...                                & 3.0\\
...
\end{tabular}
\end{center}
\caption{Profiler results of RATH-Agda execution.}
\label{table:profiling}
\end{table}

Using the GHC built-in profiling system, we generated profiling data for the RATH-Agda library's execution and found that the time required to evaluate simple record projections combined to be the greatest cost-centres in the data. This representative usage of the RATH-Agda library spends more than 20\% of execution time on just two types of projections (see Table~\ref{table:profiling}).

Therefore, the first compiler optimisation we sought to add was an efficient automatic inlining of such projections.

\section{Main Contributions}
\label{sec:main_contributions}

The main contributions to the Agda compiler include:
\begin{enumerate}[(i)]
	\item automatic inlining of proper projections
	\item removal of repeated case expressions
	\item avoiding trivial case expressions with patterned let expressions
  %\item let pattern floating across function calls
\end{enumerate}

The Agda compiler's type checker allows us to identify proper projections, and we have developed a patch for automatically inlining such projections.

However, the pass commonly results in deeply nested case expressions, many of which are pattern matching on the same constructor as its ancestors, thereby duplicating variables that the compiler has already bound. By gathering the matched patterns throughout a pass over the nested terms, we are able to prune patterns that are unnecessarily repeated, and substitute in place the previously bound pattern variables.

We remove the need for more case analysis by identifying let expressions with a case expression body, which scrutinises the variable bound by the parent let. Often these case expressions in Agda's generated code have only one case alternative, a constructor pattern match. In these situations, we replace the case expression with the body of that single alternative, and bind the constructor variable(s) using an as-pattern.

%Lastly, we found an opportunity for floating let bindings up through the expression tree in cases where the same let binding can be shared among multiple function calls. This increased sharing reduces the need for the same expression to be unnecessarily evaluated multiple times.

%In this chapter, we look at the effect of the optimisation techniques formulated in Chapter~\ref{cha:main_contributions} on different Agda code samples. Through a series of examples, we will see the effect of these optimisations and the degree to which they can yield increases in efficiency for both memory allocation space and execution time.

\section{Structure of the Thesis}
\label{sec:structure_of_the_thesis}

The remainder of this thesis is organised as follows:

\paragraph{Chapter~\ref{cha:related_work}} surveys some literature and projects relevant to our work.

\paragraph{Chapter~\ref{cha:background}} introduces the required compiler theory and logical background.

\paragraph{Chapters~\ref{cha:inline_proj}~to~\ref{cha:plet-floating}} describes the processes by which we optimise Agda programs, and gives a number of illustrative examples demonstrating the application of the implemented optimisations.

\paragraph{Chapter~\ref{cha:conclusion}} discusses the contribution's strengths and weaknesses and draws some conclusions.
