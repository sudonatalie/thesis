\begin{figure}[h]
\begin{code}
module MAlonzo.Code.Composer where

import MAlonzo.RTE (coe, erased, addInt, subInt, mulInt, quotInt,
                    remInt, geqInt, ltInt, eqInt, eqFloat)
import qualified MAlonzo.RTE
import qualified Data.Text

name6 = "Composer.twice"
d6 v0 v1 v2 = du6 v1 v2
du6 v0 v1 = coe v0 (coe v0 v1)
name10 = "Composer.thrice"
d10 v0 v1 v2 = du10 v1 v2
du10 v0 v1 = coe v0 (coe v0 (coe v0 v1))
\end{code}
\caption{Parametrised Agda module compiled to Haskell.}
\label{code:composer_haskell}
\end{figure}
