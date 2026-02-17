module Data.User where

import Data.Maybe (Maybe(..))

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
