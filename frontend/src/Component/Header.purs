module Component.Header where

import Prelude

import Component.Router.Types (Action, State)
import Data.Maybe (Maybe(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Html.Icons (userIcon)

header :: forall slots m. State -> H.ComponentHTML Action slots m
header state =
  HH.header
    [ HP.classes [ H.ClassName "bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between sticky top-0 z-10" ] ]
    [ HH.a
        [ HP.href "/"
        , HP.classes [ H.ClassName "text-lg font-bold tracking-tight text-gray-900 no-underline" ]
        ]
        [ HH.text "memory-pfl" ]
    , case state.profile of
        Just _ ->
          HH.div
            [ HP.classes [ H.ClassName "w-9 h-9 bg-blue-50 rounded-full flex items-center justify-center" ] ]
            [ userIcon ]
        Nothing ->
          HH.a
            [ HP.href "/auth/login"
            , HP.classes [ H.ClassName "text-sm bg-gray-800 hover:bg-gray-700 text-white px-3.5 py-1.5 rounded-lg no-underline" ]
            ]
            [ HH.text "Login" ]
    ]
