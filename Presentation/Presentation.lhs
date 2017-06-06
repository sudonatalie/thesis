\documentclass[t]{beamer}

% Font
\usefonttheme{serif}

% Bold, centre title
\setbeamerfont{frametitle}{size=\large,series=\bfseries}
\setbeamertemplate{frametitle}
{
\centerline{\insertframetitle}
\par
}

% Remove symbols
\usenavigationsymbolstemplate{}

%include polycode.fmt
\usepackage[round]{natbib}
\usepackage{comment}
\usepackage{../Styles/agda}
\usepackage{../Styles/AgdaChars}
\usepackage{tikz}
\usetikzlibrary{shapes,positioning,arrows.meta}
\usepackage{subcaption}
\usepackage{listings}
\usepackage{lstlinebgrd}
\usepackage{expl3,xparse}

\ExplSyntaxOn
\NewDocumentCommand \lstcolorlines { O{orange!20} m }
{
 \clist_if_in:nVT { #2 } { \the\value{lstnumber} }{ \color{#1} }
}
\ExplSyntaxOff

\newcommand{\lstbg}[3][0pt]{{\fboxsep#1\colorbox{#2}{\strut #3}}}
\lstdefinelanguage{diff}{
  morecomment=[f][\lstbg{red!20}]-,         % deleted lines
  morecomment=[f][\lstbg{green!20}]+,       % added lines
  morecomment=[f][\textit]{---}, % header lines
  morecomment=[f][\textit]{+++}
}
\lstdefinestyle{diff}{
	language=diff,
	basicstyle=\ttfamily\footnotesize,
	extendedchars=true,
	literate={⊥}{{$\bot$}}1
}
\lstdefinestyle{haskell}{
	language=Haskell,
	basicstyle=\ttfamily\scriptsize,
	extendedchars=true,
	literate={⊥}{{$\bot$}}1 {ℕ}{{$\mathbb{N}$}}1
}

\title{(Re-)Creating sharing in Agda's GHC backend}
\author{Natalie Perna}

\institute{
  Department of Computing and Software\\
  McMaster University
}

\date{Tuesday, June 6, 2017}

\begin{document}

\begin{frame}
\titlepage
\end{frame}

\begin{frame}{Outline}
\tableofcontents
\end{frame}

\section{Agda}

\begin{frame}{Agda}
\begin{itemize}
  \item Agda \citep{Norell-2007} programming language
  \item \ldots and theorem prover
  \item Dependently-typed
  \item Proof construction in a functional programming style
  \item Flexible mixfix syntax
  \item Unicode identifiers \citep{bove2009}
\end{itemize}
\end{frame}

\begin{frame}{Examples}
Dependent types:\\
\input{Agda/latex/Replicate}

\pause

Syntax:\\
\input{Agda/latex/If}

\pause

Proof:\\
\input{Agda/latex/Proof}
\end{frame}

\begin{frame}{Sharing}
\begin{figure}[h]
\hspace{-1.5cm}
\begin{subfigure}{.45\textwidth}
\small
\input{Agda/latex/Sharing}
\end{subfigure}
\hspace{1cm}
\begin{subfigure}{.55\textwidth}
\lstinputlisting[style=haskell]{Figures/Sharing.hs}
\end{subfigure}
\end{figure}
\end{frame}

\section{Compiler}

\begin{frame}{Compiler}
\textit{Goal}:\\
Achieve performance matching GHC

\pause\vspace{.5cm}

\textit{Solution}:\\
GHC Backend translates Agda into Haskell \citep{benke2007}

\pause\vspace{1cm}

\textit{Performance}:

\begin{itemize}
  \item Pretty good performance compiling with GHC
  \item Lack of GHC optimisations that occur around unsafe coercions \citep{fredriksson2011}
  \item Additional passes over generated code necessary to improve
\end{itemize}
\end{frame}

\begin{frame}[c]{Stages of compilation}
\input{Figures/CompilerFlowchart}
\end{frame}

\section{Optimisations}

\subsection{Projection Inlining}

\begin{frame}{Projection Inlining}

Inline all proper projections.

\begin{itemize}
  \item Recurse through expression tree
  \item Identify proper projections by qualified name
  \item Replace function with body
  \item Substitute in function arguments
\end{itemize}
\end{frame}

\begin{frame}{Projection Inlining: Application}
\begin{figure}[h]
\hspace{-1.5cm}
\begin{subfigure}{.45\textwidth}
\small
\input{Agda/latex/Example1}
\end{subfigure}
\hspace{1cm}
\begin{subfigure}{.55\textwidth}
\lstinputlisting[style=diff]{Figures/Example1_inline.diff}
\end{subfigure}
\end{figure}
\end{frame}

\subsection{Case Squashing}

\begin{frame}{Case Squashing}

Eliminate case expressions where the scrutinee has already been matched on by an enclosing ancestor case expression.

\begin{figure}[h]
\hspace{-2cm}
\footnotesize
\centering
\begin{subfigure}{.47\textwidth}
\centering
\begin{spec}
case x of
  d v0..vn ->
    ...
      case x of
        d v0'...vn' -> r
\end{spec}
\end{subfigure}
{$\longrightarrow$}
\begin{subfigure}{.47\textwidth}
\centering
\begin{spec}
case x of
  d v0...vn ->
    ...
      r[v0' := v0, ..., vn' := vn]
\end{spec}
\end{subfigure}
\end{figure}
\end{frame}

\begin{frame}{Case Squashing: Application}
\begin{figure}[h]
\hspace{-1.5cm}
\begin{subfigure}{.45\textwidth}
\small
\input{Agda/latex/Example1}
\end{subfigure}
\hspace{1cm}
\begin{subfigure}{.55\textwidth}
\lstinputlisting[style=diff]{Figures/Example1_squash.diff}
\end{subfigure}
\end{figure}
\end{frame}

\subsection{Pattern Let Generating}

\begin{frame}{Pattern Let Generating}
We can avoid generating certain trivial case expressions by identifying qualifying let expressions.

\begin{figure}[h]
\hspace{-1cm}
\footnotesize
\centering
\begin{subfigure}{.47\textwidth}
\begin{spec}
let x = e
in case x of
  d v0...vn -> t
  otherwise -> u
\end{spec}
\end{subfigure}
{$\longrightarrow$}
\begin{subfigure}{.47\textwidth}
\begin{spec}
let x@(d v0...vn) = e
in t
\end{spec}
\end{subfigure}
\end{figure}
where |unreachable(u)|.
\end{frame}

\begin{frame}{Pattern Let Generating: Application}
\lstinputlisting[style=diff]{Figures/Triangle_genplet.diff}
\end{frame}

\subsection{Pattern Let Floating}

\begin{frame}{Pattern Let Floating}
Float pattern lets up through the abstract syntax tree to join with other bindings for the same expression.

\begin{figure}[h]
\hspace{-1cm}
\footnotesize
\centering
\begin{subfigure}{.57\textwidth}
\begin{spec}
f  (let x@(d v0...vn) =  e in t1)
   (let x@(d v0...vn) =  e in t2)
\end{spec}
\end{subfigure}
{$\longrightarrow$}
\begin{subfigure}{.37\textwidth}
\begin{spec}
let x@(d v0...vn) = e
in f t1 t2
\end{spec}
\end{subfigure}
\end{figure}

\begin{figure}[h]
\hspace{-1cm}
\footnotesize
\centering
\begin{subfigure}{.57\textwidth}
\begin{spec}
f  (let a@(b@(c,d),e)   = e in t1)
   (let a@(b, c@(d,e))  = e in t2)
\end{spec}
\end{subfigure}
{$\longrightarrow$}
\begin{subfigure}{.37\textwidth}
\begin{spec}
let f@(g@(h,i),j@(k,l)) = e
in f t1' t2'
\end{spec}
\end{subfigure}
\begin{spec}
where  t1' =  t1[a := f, b := g, c := h, d := i, e := j]
       t2' =  t2[a := f, b := g, c := j, d := k, e := l]
\end{spec}
\end{figure}
\end{frame}

\begin{frame}{Pattern Let Floating: Application}
\lstinputlisting[style=haskell,linebackgroundcolor={\lstcolorlines{2,4,6,8}}]{Figures/Triangle_before.hs}
\rule{\textwidth}{0.4pt}
\lstinputlisting[style=haskell,linebackgroundcolor={\lstcolorlines{2}}]{Figures/Triangle_float.hs}
\end{frame}

\begin{frame}{Pattern Let Floating: Application}
\lstinputlisting[style=haskell,linebackgroundcolor={\lstcolorlines{}}]{Figures/Triangle_float.hs}
\rule{\textwidth}{0.4pt}
\lstinputlisting[style=haskell,linebackgroundcolor={\lstcolorlines{3,4}}]{Figures/Triangle_split.hs}
\end{frame}

\section{Conclusion}

\begin{frame}{Challenges}
\begin{itemize}
  \item Understanding of compilation pipeline
  \item Familiarisation with internal syntax
  \item Non-termination of recursive inlining
  \item Identifying squashable cases via De Bruijn index
  \item Substituting case bodies with appropriate variable indices
\end{itemize}
\end{frame}

\begin{frame}{Conclusion}
\begin{itemize}
  \item Profiled existing Agda programs for highest cost centres
  \item Developed transformations to focus on the inherent ``loss'' of sharing
  \item Tested optimising transformations on various typical Agda programs
  \item High-level documentation of Agda compiler pipeline
\end{itemize}
\end{frame}

\section{References}

\begin{frame}{Bibliography}
\bibliographystyle{plainnat}
\bibliography{../Bibliography/RATH/strings,../Bibliography/RATH/ref,../Bibliography/RATH/crossrefs,../Bibliography/ref}
\end{frame}

\begin{frame}{Questions}
\end{frame}

\end{document}
