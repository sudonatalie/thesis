% Document Class
%________________________________________________________________________
\documentclass[12pt]{report}
%________________________________________________________________________

% Imported Packages
%________________________________________________________________________
%include polycode.fmt
\usepackage{alltt}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amstext}
\usepackage{amsthm}
\usepackage{bytefield}
\usepackage{color}
\usepackage{Styles/eclbip}
\usepackage{enumerate}
\usepackage{epic}
\usepackage{Styles/fancyheadings}
\usepackage[hmargin=20mm,vmargin=30mm]{geometry}
\usepackage{graphicx}
\usepackage[pdfpagelabels,hypertexnames=false,breaklinks=true,
			bookmarksopen=true,bookmarksopenlevel=2]{hyperref}
\usepackage{ifthen}
\usepackage{listings}
\usepackage{makeidx}
\usepackage[round]{natbib}
\usepackage{Styles/setspace}
\usepackage{subcaption}
\usepackage{Styles/thesis}
\usepackage{xcolor}
\usepackage{xspace}
\usepackage[all]{xy}
\usepackage{textgreek}
\usepackage{lmodern}
\usepackage{parskip}
\usepackage{comment}
\usepackage{Styles/agda}
\usepackage{Styles/AgdaChars}
\usepackage{Styles/edcomms}

%________________________________________________________________________

% Macros and Commands
%________________________________________________________________________

% Include the macro files
\input{Macros/GeneralMathMacros}
\input{Macros/AbbreviationsMacros}
\input{Macros/ReviewMacros}
\input{Macros/EnvironmentMacros}
\input{Macros/IndexMacros}

% Import the General Thesis Information
\input{Auxiliary/ThesisInformation}

% Listings Settings
\lstdefinestyle{blockhaskell}{
  language=Haskell,
  basicstyle=\linespread{1}\normalsize\ttfamily,
  showspaces=false,
  showstringspaces=false,
  tabsize=2,
  breaklines=true
}
\lstdefinestyle{appendixhaskell}{
  style=blockhaskell,
  literate={Γ}{\textGamma}1 {Δ}{\textDelta}1 {Θ}{\texttheta}1
}
\lstdefinestyle{inline}{
  basicstyle=\ttfamily\normalsize
}
\lstdefinestyle{math}{
  basicstyle=\ttfamily\normalsize,
	mathescape
}
\lstset{style=inline}

% Make Index
\makeindex
%________________________________________________________________________

% Document
%________________________________________________________________________
\begin{document}

% Make Title Page & Authorship
\beforepreface

% Include the Dedication
\newpage
\input{Auxiliary/Dedication}

% Abstract
\prefacesection{Abstract}
\input{Auxiliary/Abstract}
\begin{code}
map                     :: (a->b) -> [a] -> [b]
map f  []               =  []
map f (x:xs)            =  f x : map f xs
\end{code}

% Acknowledgements
\prefacesection{Acknowledgements}
\input{Auxiliary/Acknowledgements}

% Make Table of Contents, List of Tables & List of Figures
\afterpreface

% Introduction
\input{Auxiliary/ResetCounters}
\input{Chapters/Introduction}

% Related Work
\input{Auxiliary/ResetCounters}
%include Chapters/RelatedWork.lhs

% Background
\input{Auxiliary/ResetCounters}
%include Chapters/Background.lhs

% Main Contributions
\input{Auxiliary/ResetCounters}
%include Chapters/Inline.lhs

\input{Auxiliary/ResetCounters}
%include Chapters/CaseSquash.lhs

\input{Auxiliary/ResetCounters}
%include Chapters/GenPlet.lhs

\input{Auxiliary/ResetCounters}
%include Chapters/Float.lhs

% Discussion and Conclusion
\input{Auxiliary/ResetCounters}
%include Chapters/Conclusion.lhs

% Appendices
\input{Auxiliary/ResetCounters}
\appendix
%include Appendix/Simplify.lhs
%include Appendix/ToTreeless.lhs
%include Appendix/CaseSquash.lhs
%include Appendix/Compiler.lhs

% Bibliography
\bibliographystyle{plainnat}
\addcontentsline{toc}{chapter}{Bibliography}
\bibliography{Bibliography/ref,Bibliography/RATH}

% Index
\newpage
\addcontentsline{toc}{chapter}{Index}
\printindex

\end{document}
%________________________________________________________________________
