module MAlonzo.Code.Sharing where

import MAlonzo.RTE
import qualified MAlonzo.RTE
import qualified Data.Text

name2 = "Sharing.ℕ"
d2 = ()
data T2 a0 = C4 | C6 a0
name8 = "Sharing._+_"
d8 v0 v1
  = case coe v0 of
      C4 -> coe v1
      C6 v2 -> coe C6 (coe d8 v2 v1)
      _ -> ⊥
name16 = "Sharing.one"
d16 = coe C6 C4
name18 = "Sharing.four"
d18 = coe d8 (coe d8 d16 d16)
        (coe d8 d16 d16)
