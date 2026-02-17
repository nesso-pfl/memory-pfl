module Data.Route where

import Prelude hiding ((/))

import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Routing.Duplex (RouteDuplex', optional, params, root, string)
import Routing.Duplex.Generic (sum)

type HomeParams = { tab :: Maybe String, tag :: Maybe String }

data Route = Home HomeParams

derive instance Eq Route
derive instance Generic Route _

routeCodec :: RouteDuplex' Route
routeCodec = root $ sum
  { "Home": params { tab: optional <<< string, tag: optional <<< string } }
