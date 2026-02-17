module Capability.Memory where

import Prelude

import Control.Monad.Trans.Class (lift)
import Data.Either (Either)
import Halogen (HalogenM)

type CreateMemory =
  { content :: String, tags :: Array String, category :: String }

class Monad m <= MonadMemory m where
  createMemory :: CreateMemory -> m (Either String Unit)

instance MonadMemory m => MonadMemory (HalogenM st act slots msg m) where
  createMemory = lift <<< createMemory
