module AppM where

import Prelude

import Capability.Navigate (class Navigate)
import Control.Monad.Reader (class MonadAsk, ReaderT, ask, runReaderT)
import Data.Route (routeCodec)
import Effect.Aff (Aff)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (class MonadEffect, liftEffect)
import Foreign (unsafeToForeign)
import Routing.Duplex (print)
import Routing.PushState (PushStateInterface)

type Env = { nav :: PushStateInterface }

newtype AppM a = AppM (ReaderT Env Aff a)

runAppM :: Env -> AppM ~> Aff
runAppM env (AppM m) = runReaderT m env

derive newtype instance Functor AppM
derive newtype instance Apply AppM
derive newtype instance Applicative AppM
derive newtype instance Bind AppM
derive newtype instance Monad AppM
derive newtype instance MonadEffect AppM
derive newtype instance MonadAff AppM
derive newtype instance MonadAsk Env AppM

instance Navigate AppM where
  navigate route = do
    { nav } <- ask
    liftEffect $ nav.pushState (unsafeToForeign {}) (print routeCodec route)
