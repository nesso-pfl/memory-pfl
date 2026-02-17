module Capability.User where

import Prelude

import Control.Monad.Trans.Class (lift)
import Data.Maybe (Maybe)
import Data.User (UserProfile)
import Halogen (HalogenM)

class Monad m <= MonadUser m where
  getProfile :: m (Maybe UserProfile)

instance MonadUser m => MonadUser (HalogenM st act slots msg m) where
  getProfile = lift getProfile
