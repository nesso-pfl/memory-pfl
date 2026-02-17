module Data.UserProfile where

import Data.Maybe (Maybe)

type UserProfile =
  { sub :: String
  , name :: Maybe String
  , preferred_username :: Maybe String
  , email :: Maybe String
  }
