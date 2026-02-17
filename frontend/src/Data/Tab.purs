module Data.Tab where

import Prelude

data Tab = Development | General

derive instance Eq Tab

toCategory :: Tab -> String
toCategory Development = "development"
toCategory General = "general"
