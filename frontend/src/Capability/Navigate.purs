module Capability.Navigate where

import Prelude

import Control.Monad.Trans.Class (lift)
import Data.Route (Route)
import Halogen (HalogenM)

class Monad m <= Navigate m where
  navigate :: Route -> m Unit
  replaceRoute :: Route -> m Unit

instance Navigate m => Navigate (HalogenM st act slots msg m) where
  navigate = lift <<< navigate
  replaceRoute = lift <<< replaceRoute
