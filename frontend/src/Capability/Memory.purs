module Capability.Memory where

import Prelude

import Control.Monad.Trans.Class (lift)
import Data.Either (Either)
import Data.Memory (CreateMemory)
import Halogen (HalogenM)

class Monad m <= MonadMemory m where
  createMemory :: CreateMemory -> m (Either String Unit)

instance MonadMemory m => MonadMemory (HalogenM st act slots msg m) where
  createMemory = lift <<< createMemory
