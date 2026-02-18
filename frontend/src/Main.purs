module Main where

import Prelude

import AppM (runAppM)
import Component.Router as Router
import Data.Route (routeCodec)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Halogen as H
import Halogen.Aff (awaitBody)
import Halogen.VDom.Driver (runUI)
import Routing.Duplex (parse)
import Routing.PushState (makeInterface, matchesWith)

main :: Effect Unit
main = launchAff_ do
  body <- awaitBody
  nav <- H.liftEffect makeInterface
  let env = { nav }
  halogenIO <- runUI (H.hoist (runAppM env) Router.component) unit body
  void $ H.liftEffect $ matchesWith (parse routeCodec)
    ( \_ new ->
        launchAff_ $ void $ halogenIO.query $ H.mkTell $ Router.Navigate new
    )
    nav
