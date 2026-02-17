module Capability.Memory where

import Prelude

import Control.Monad.Trans.Class (lift)
import Data.Either (Either)
import Data.Memory (CreateMemory, ListParams, Memory)
import Halogen (HalogenM)

class Monad m <= MonadMemory m where
  listMemories :: ListParams -> m (Either String (Array Memory))
  createMemory :: CreateMemory -> m (Either String Unit)

instance MonadMemory m => MonadMemory (HalogenM st act slots msg m) where
  listMemories = lift <<< listMemories
  createMemory = lift <<< createMemory
