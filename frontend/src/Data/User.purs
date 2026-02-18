module Data.User where

import Prelude

import Data.Argonaut.Decode.Class (decodeJson)
import Data.HTTP.Method (Method(..))
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Fetch (fetch)
import Unsafe.Coerce (unsafeCoerce)

type UserProfile =
  { sub :: String
  , name :: Maybe String
  , preferred_username :: Maybe String
  , email :: Maybe String
  }

displayName :: UserProfile -> String
displayName p = case p.preferred_username of
  Just n -> n
  Nothing -> case p.name of
    Just n -> n
    Nothing -> p.sub

getProfile :: Aff (Maybe UserProfile)
getProfile = do
  response <- fetch "/auth/me" {}
  if response.status == 200 then do
    raw <- response.json
    case decodeJson (unsafeCoerce raw) of
      Right p -> pure (Just p)
      Left _ -> pure Nothing
  else
    pure Nothing

logout :: Aff Unit
logout = do
  void $ fetch "/auth/logout" { method: POST }

foreign import redirectToRoot :: Effect Unit
