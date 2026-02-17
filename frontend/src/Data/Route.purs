module Data.Route where

import Prelude hiding ((/))

import Data.Generic.Rep (class Generic)
import Routing.Duplex (RouteDuplex', root)
import Routing.Duplex.Generic (noArgs, sum)

data Route = Home

derive instance Eq Route
derive instance Generic Route _

routeCodec :: RouteDuplex' Route
routeCodec = root $ sum { "Home": noArgs }
