\documentclass{beamer}

\usetheme{Boadilla}
\usecolortheme{whale}

\AtBeginSection[]{
  \begin{frame}
  \vfill
  \centering
  \begin{beamercolorbox}[sep=8pt,center,shadow=true,rounded=true]{title}
    \usebeamerfont{title}\insertsectionhead\par%
  \end{beamercolorbox}
  \vfill
  \end{frame}
}

\makeatother
\setbeamertemplate{footline}
{
  \leavevmode%
  \hbox{%
  \begin{beamercolorbox}[wd=.35\paperwidth,ht=2.25ex,dp=1ex,center]{author in head/foot}%
    \usebeamerfont{author in head/foot}\insertshortauthor
  \end{beamercolorbox}%
  \begin{beamercolorbox}[wd=.65\paperwidth,ht=2.25ex,dp=1ex,center]{title in head/foot}%
    \usebeamerfont{title in head/foot}\insertshorttitle\hspace*{3em}
    \insertframenumber{} / \inserttotalframenumber\hspace*{1ex}
  \end{beamercolorbox}}%
  \vskip0pt%
}
\makeatletter
\setbeamertemplate{navigation symbols}{}

%include polycode.fmt
\usepackage[round]{natbib}
\usepackage{comment}
\usepackage{../Styles/agda}
\usepackage{../Styles/AgdaChars}

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
Agda \citep{Norell-2007} is a dependently-typed programming language and theorem prover, supporting proof construction in a functional programming style.
\end{frame}

\begin{frame}{Example}
\input{Agda/latex/Replicate}
\end{frame}

\begin{frame}{Syntax}
Agda supports flexible mixfix syntax and Unicode \citep{bove2009}.
\input{Agda/latex/If}
\end{frame}

\begin{frame}{Readability}
Fine-grain control over proof syntax allows for readable formats.
\input{Agda/latex/Proof}
\end{frame}

\section{References}

\begin{frame}{Bibliography}
\bibliographystyle{plainnat}
\bibliography{../Bibliography/RATH/strings,../Bibliography/RATH/ref,../Bibliography/RATH/crossrefs,../Bibliography/ref}
\end{frame}

\section{Questions}

\end{document}
