module Data.Tab where

import Prelude

import Data.Maybe (Maybe(..))

data Tab = Development | General

derive instance Eq Tab

toCategory :: Tab -> String
toCategory Development = "development"
toCategory General = "general"

fromCategory :: String -> Maybe Tab
fromCategory "development" = Just Development
fromCategory "general" = Just General
fromCategory _ = Nothing
