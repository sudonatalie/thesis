\chapter{Background}
\label{cha:background}

In this chapter, we introduce the necessary logical and compiler background concepts required for the understanding of the material presented in this thesis. In Section~\ref{sec:lambda_calc}, we review some of the mathematical background useful for understanding our optimisations. In Section~\ref{sec:background_agda}, we give an introduction to the Agda compiler.

\section{Lambda Calculus}
\label{sec:lambda_calc}

Lambda calculus (or $\lambda$-calculus) is a formal system for representing computational logic in terms of function abstractions and applications using variable binding and substitution. It warrants our understanding because concepts surrounding the Agda programming language and its compilation are inspired by, and can be elegantly explained by, the framework of the lambda calculi. In fact, the namesake of the default Agda GHC backend, MAlonzo, is Alonzo Church, the mathematician who first developed the lambda calculus \citep{agdawiki}.

\subsection{Pure $\lambda$-Calculus}

In a pure $\lambda$-calculus, terms are built inductively from only variables, $\lambda$-abstractions and applications \citep{Church-1941}, as shown in the following grammar:

\input{Figures/LambdaCalc}

\subsection{De Bruijn Index Notation}

In order to eliminate the need for named variables in $\lambda$-calculus notation, De Bruijn indexed notation is used to represent bound terms (variables) with natural numbers, as presented by \citet{deBruijn-1972}. In any term, the positive integer $n$ refers to the $n$th surrounding $\lambda$ binder. In other words, the number is an index indicating the number of variable binders (or $\lambda$-abstractions) in scope between itself and the binder for the variable being referenced. The grammar of a De Bruijn indexed lambda calculus is shown below:

\input{Figures/DeBruijnLambdaCalc}

See Figure~\ref{fig:db_example} for an illustration where the variable bindings and indices are coloured to indicate matches and the references are shown with arrows.

\input{Figures/DeBruijn}

The internal representation of Agda code in the compiler is based on a De Bruijn indexed $\lambda$-calculus.

\subsection{$\lambda\sigma$-Calculus}

In order to perform the desired optimisations on the abstract syntax tree, we must be able to perform substitutions on terms. Treating the abstract syntax tree structure as a specialised $\lambda$-calculus, we can implement substitution as a function on terms.

Because our terms are built on De Bruijn indexed variables, we use \citet{Abadi-Cardelli-Curien-Levy-1990}'s explicit substitution of a $\lambda\sigma$-calculus as a reference for understanding correct substitution on terms in the context of local variables bound by incrementing indices. The $\lambda\sigma$-calculus is a refinement of the $\lambda$-calculus where substitutions are manipulated explicitly, and substitution application is a term constructor rather than a meta-level notation.

\subsection{Substitution}
\label{sub:lambda_calc_subst}

Take then, for instance, the classical application of the $\beta$-reduction rule in a pure $\lambda$ calculus:

\begin{equation*}
(\lambda x.t)s \to_{\beta} t[x := s]
\end{equation*}

Beta reduction is the process of simplifying an application of a function to the resulting substituted term. However, in order to $\beta$-reduce a De Bruijn indexed expression, like $(\lambda a)b$, it isn't sufficient to only substitute $b$ into the appropriate occurrences in $a$. As the $\lambda$ binding disappears, we must also decrement all remaining free indices in $a$ \citep{Abadi-Cardelli-Curien-Levy-1990}. This adapted form of the $\beta$-rule for De Bruijn indexed $\lambda$ calculus can be represented by the following infinite substitution:

\begin{equation*}
(\lambda t)s \to_{\beta} t[0 := s, 1 := 0, 2 := 1, ...]
\end{equation*}

However, the substitution in this adapted rule must be evaluated carefully to produce a correct result. Consider if the term $t$ contains another $\lambda$ binding. As the substitution is applied to that nested $\lambda$ term, occurrences of $0$ should not be replaced with $s$, because occurrences of $0$ refer to the nested $\lambda$ term's bound variable. Instead, occurrences of $1$ should be replaced with $s$; likewise, occurrences of $2$ should be replaced by $1$, and so on. We thus ``shift'' the substitution \citep{Abadi-Cardelli-Curien-Levy-1990}.

It is also important when applying substitutions to $\lambda$ terms that we avoid the unintended capture of free variables in our terms being substituted in. Imagine again the nested $\lambda$ term, with occurrences of $1$ being replaced with $s$. Occurrences of $0$ in $s$ must be replaced with $1$, else the nested $\lambda$ binder will capture the index. We this ``lift'' the indices of $s$ \citep{Abadi-Cardelli-Curien-Levy-1990}. These two caveats result in the following substitution rule  for De Bruijn indexed lambda terms:

\begin{equation*}
(\lambda t)[0 := s, 1 := 0, ...] = \lambda t[1 := s[0 := 1, 1 := 2, ...], 2 := 1, ...]
\end{equation*}

Recognising the required index ``shifting'' and ``lifting'' in the substitution rule above should suffice as background for understanding the variable manipulation performed in our optimisation.

\section{Agda}
\label{sec:background_agda}

\subsection{Compiler}

The Agda programming language's first and most-used backend is MAlonzo, or more generically, the GHC backend \citep{benke2007}. Given an Adga module containing a \AgdaFunction{main} function\footnote{An Agda module without a main file can be compiled with @--no-main@.}, the Agda @--compile@ option will compile the program using the GHC backend by default, which translates an Agda program into Haskell source. The generated Haskell source can then be automatically (default) or manually (with @--ghc-dont-call-ghc@) compiled to an executable program via GHC \citep{agdadocs}. % http://agda.readthedocs.io/en/latest/tools/compilers.html

There are several stages of translation and compilation in this process, as shown in Figure~\ref{fig:agda_compile}. The transition of primary interest for our optimisations is the conversion of compiled clauses to a ``treeless'' syntax. This translation occurs after Agda type-checking but before Haskell source is generated. Most Agda optimisations occur as alterations to the treeless terms.

\input{Figures/CompilerFlowchart}

An Agda function is defined by declaring its type\footnote{It is worth noting that type
inference is an undecidable problem for definitions with dependent
types, so type signatures must be provided in many cases, and by
convention, should always be provided.}
and providing a definition in the form of one or more clauses.
Functions on datatypes can be defined by pattern matching on the
constructors of that datatype, describing a structurally recursive
function \citep{agdawiki}.
% http://wiki.portal.chalmers.se/agda/agda.php?n=Docs.DatatypeAndFunctionDefinitions
This should sound familiar to users of functional programming
languages like Haskell. Unlike Haskell, however, Agda does not permit
partial functions. Therefore, functions defined by pattern matching
must not exclude any possible cases from the pattern matching clauses
\citep{agdawiki}.
% http://wiki.portal.chalmers.se/agda/pmwiki.php?n=ReferenceManual.Totality#Coveragechecking}
Because function definitions in Agda are written as a series of one or
more pattern matching clauses on possible variable inputs, we can
construct an equivalent definition via case tree \citep{agdawiki}.
% http://wiki.portal.chalmers.se/agda/agda.php?n=Docs.PatternMatching
Once coverage checking and type checking is completed, pattern
matching can be translated into case trees by successively splitting
on each variable \citep{agdahackage}.
% https://hackage.haskell.org/package/Agda-2.5.2/docs/Agda-TypeChecking-CompiledClause.html
Compiled clauses are the first stage of compilation and they are,
simply put, case trees.

Take for example the simple \AgdaFunction{not} function on booleans below:

\input{Figures/Agda/latex/Not}

After successful scope, coverage and type checking, the following compiled clauses are produced for the \AgdaFunction{not} function:

\input{Figures/CompiledNot}

and if the @--compile@ flag is enabled, it will then be transformed into treeless syntax:

\input{Figures/TreelessNot}

The treeless syntax is the input to the compiler backend of Agda. It's
a high-level internal syntax, the name for which is derived from its
use of case expressions instead of case trees.
The other notable difference between compiled clauses and treeless
syntax is the absence of instantiated datatypes
and constructors
\citep{agdahackage}.
% https://hackage.haskell.org/package/Agda-2.5.2/docs/Agda-Syntax-Treeless.html
Note that internally, variables are represented only by their De Bruijn index, however for ease of illustration, we use named variables in our pretty-printed samples of treeless terms.

\subsubsection{Treeless Syntax}

This treeless syntax is constructed from the |TTerm|s (\textbf{T}reeless \textbf{Terms}) data type and is the representation of the abstract syntax tree that we will refer to most frequently. It can be reasoned about as a lambda calculus with all local variables represented as De Bruijn indices. A listing of |TTerm| constructors is shown below:

\begin{code}
type Args = [TTerm]

data TTerm = TVar Nat
           | TPrim TPrim
           | TDef QName
           | TApp TTerm Args
           | TLam TTerm
           | TLit Literal
           | TCon QName
           | TLet TTerm TTerm
           | TCase Nat CaseType TTerm [TAlt]
           | TUnit
           | TSort
           | TErased
           | TError TError

data TAlt = TACon QName Nat TTerm
          | TAGuard TTerm TTerm
          | TALit Literal TTerm
\end{code}

In more detail, the constructor alternatives for |TTerm|s are as follows \citep{agdahackage}:

\begin{itemize}

\item |TVar| constructs a De Bruijn-indexed variable term.

\item |TPrim| constructs a compiler-related primitive, such as addition, subtraction and equality on some primitive types.

\item |TDef| constructs a qualified name identifying a function or datatype definition.

\item |TApp| constructs a |TTerm| applied to a list of arguments, where each argument is itself a |TTerm|.

\item |TLam| constructs a $\lambda$-abstraction with a body.

\item |TLit| constructs a literal value, such as an integer or string.

\item |TCon| constructs a qualified name identifying a constructor.

\item |TLet| constructs a let expression, introducing a new local term binding in a term body.

\item |TCase| constructs a case expression on a case scrutinee (always a De Bruijn indexed variable), a case type, a default value and a list of alternatives.

  The case alternatives, \textbf{|TAlt|}s, may be constructed from:
  \begin{itemize}
  \item a |TACon|, which matches on a constructor of a given qualified name, binding the appropriate number of pattern variables to the body term if a match is made. Note that a |TCase|'s list of |Args| must have unique qualified names for each |TACon|.
  \item a |TAGuard|, which matches on a boolean guard and binds no variables if matched against.
  \item a |TALit|, which matches on a literal term.
  \end{itemize}

\item |TUnit|s are used for levels.

\item |TSort| constructs a sort, as in the type of types.

\item |TErased|s are used to replace irrelevant terms that are no longer needed.

\item |TError|s are used to indicate a runtime error.

\end{itemize}

%In the following chapters, we discuss the design and implementation of our optimisations to the Agda compiler. In each Chapter, we give a logical representation of the optimisation, present our implementation and give usage instructions for the feature in our compiler branch. We also give references to the source code in the Appendix.

We also present below a simplified logical representation of the Agda treeless syntax as a grammar named using variables $x$ instead instead of De Bruijn indices:

%include ../Figures/TreelessGrammar.lhs

We use this simplification in the following chapters to discuss our optimisations at a logical level of abstraction.

%In the implementation Subsections, we discuss some implementation details of our optimisations with reference to the Haskell data type of Agda's treeless representation. The treeless syntax (|TTerm|) listing can be found in Figure~\ref{code:TTerm}.

\subsection{Module System}

The Agda module is designed with simplicity in mind, with the primary goal of organising the way names are used in Agda programs into a hierarchical structure. By default, definitions and datatypes must be referenced unambiguously with both their qualified name and the module in which it is defined.

By this implementation, Agda modules don't have a ``type'', and scope checking can be accomplished entirely independently of type-checking. After type-checking, all definitions are lambda lifted \citep{agdadocs}. However, because names are fully qualified and the concept of ``scope'' is removed from type-checking, information about potential sharing is lost once arguments are substituted into the types of module definitions.

Consider the following simple parametrized module in Agda:

\input{Figures/Agda/latex/Composer}

and the Haskell generated by compiling this module:

%include ../Figures/Haskell/Composer.lhs

In this example the module's explicit parameters have been abstracted over the definitions to become explicit arguments to the module's functions.

Because arguments are inherited from all enclosing modules, in larger Agda projects, it is easy to create a situation where very large type signatures must be serialised many times when the same modules are referenced more than once \citep{agdamail}. % https://lists.chalmers.se/pipermail/agda/2017/009406.html

In Chapter~\ref{cha:plet-floating} we discuss our attempts to re-introduce some of this lost sharing potential and reduce repeated computations.

\subsection{Alternate method of case squashing}
\label{sub:alternate_case_squash}

%https://github.com/agda/agda/commit/56132a6046473ae1f62a5e12e705de0e79c74188

Following our own development of @--squash-cases@ (see Chapter~\ref{cha:case_squashing}),
an optimisation was added to the Agda compiler's Simplify stage
which accomplishes the same goals as @--squash-cases@ in a slightly
different way.
We examine here that method of removing repeated case expressions.

Immediately following the conversion of compiled clauses to treeless syntax in the Agda compiler, a series of optimising transformations are applied before the treeless expression is returned. One such step is the ``simplify'' group of transformations, which modify a |TTerm| in a variety of optimising ways.

As the expression is traversed, |simplify| is recursively called on each |TTerm| term, and |simpAlt| is called on each |TAlt| alternative. Given some expression casing on De Bruijn index $x$, for each alternative of the pattern |TACon name arity body|, the scrutinised variable index in the body, $x + arity$, is looked up in the variable environment. If the variable has already been bound, and therefore has a different De Bruijn index, $y$, a rewrite rule is added to the constructor. The rewrite rule indicates that every instance of |TApp (TCon name) [TVar i || i <- reverse $ take arity [0..]]| in the alternative's body should be replaced with a |TVar y|.

The rewrite rule is encoded as part of the wrapper |Reader| environment that is carried along with the |TTerm| throughout simplification, and is evaluated later by applying substitutions. It is at this point that all necessary De Bruijn index shifting is managed.

%An abridged version of @Treeless/Simplify.hs@ showing the primary functions involved in this optimisation in the updated Agda compiler is available in Appendix~\ref{app:simplify}.
