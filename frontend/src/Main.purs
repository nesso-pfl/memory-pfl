module Main where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Halogen as H
import Halogen.Aff (awaitBody)
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)

main :: Effect Unit
main = launchAff_ do
  body <- awaitBody
  void $ runUI component unit body

component :: forall q i o m. H.Component q i o m
component = H.mkComponent
  { initialState: \_ -> unit
  , render: \_ -> HH.h1_ [ HH.text "Hello, world!" ]
  , eval: H.mkEval H.defaultEval
  }
