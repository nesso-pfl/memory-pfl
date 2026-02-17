module AppM where

import Prelude

import Capability.Memory (class MonadMemory, CreateMemory)
import Capability.Navigate (class Navigate)
import Capability.User (class MonadUser)
import Control.Monad.Reader (class MonadAsk, ReaderT, ask, runReaderT)
import Data.Argonaut.Core (jsonEmptyObject, stringify)
import Data.Argonaut.Decode.Class (decodeJson)
import Data.Argonaut.Encode.Combinators ((:=), (~>))
import Data.Either (Either(..))
import Data.HTTP.Method (Method(..))
import Data.Maybe (Maybe(..))
import Data.Route (routeCodec)
import Effect.Aff (Aff)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (class MonadEffect, liftEffect)
import Fetch (fetch)
import Foreign (unsafeToForeign)
import Routing.Duplex (print)
import Routing.PushState (PushStateInterface)
import Unsafe.Coerce (unsafeCoerce)

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

instance MonadUser AppM where
  getProfile = do
    response <- liftAff $ fetch "/auth/me" {}
    if response.status == 200 then do
      raw <- liftAff response.json
      case decodeJson (unsafeCoerce raw) of
        Right p -> pure (Just p)
        Left _ -> pure Nothing
    else
      pure Nothing

instance MonadMemory AppM where
  createMemory (mem :: CreateMemory) = do
    let
      body = stringify
        $ "content" := mem.content
        ~> "tags" := mem.tags
        ~> "category" := mem.category
        ~> jsonEmptyObject
    response <- liftAff $ fetch "/memories"
      { method: POST
      , headers: { "Content-Type": "application/json" }
      , body
      }
    if response.status == 201 then
      pure (Right unit)
    else
      pure (Left "保存に失敗しました")
