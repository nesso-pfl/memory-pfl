module Component.Header where

import Prelude

import Component.Router.Types (Action, State)
import Data.Maybe (Maybe(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Html.Svg (svgElement)

header :: forall slots m. State -> H.ComponentHTML Action slots m
header state =
  HH.header
    [ HP.classes [ H.ClassName "sticky top-0 z-10 bg-white/80 backdrop-blur-md shadow-sm px-5 py-3.5 flex items-center justify-between" ] ]
    [ HH.a
        [ HP.href "/"
        , HP.classes [ H.ClassName "text-lg font-bold tracking-tight text-gray-900 no-underline" ]
        ]
        [ HH.text "memory-pfl" ]
    , case state.profile of
        Just _ ->
          HH.div
            [ HP.classes [ H.ClassName "w-9 h-9 bg-blue-50 rounded-full flex items-center justify-center" ] ]
            [ svgElement (H.ElemName "svg")
                [ HP.attr (H.AttrName "viewBox") "0 0 24 24"
                , HP.attr (H.AttrName "fill") "none"
                , HP.attr (H.AttrName "stroke") "#3b82f6"
                , HP.attr (H.AttrName "stroke-width") "2"
                , HP.classes [ H.ClassName "w-5 h-5" ]
                ]
                [ svgElement (H.ElemName "circle") [ HP.attr (H.AttrName "cx") "12", HP.attr (H.AttrName "cy") "8", HP.attr (H.AttrName "r") "4" ] []
                , svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M4 21v-1a6 6 0 0 1 12 0v1" ] []
                ]
            ]
        Nothing ->
          HH.a
            [ HP.href "/auth/login"
            , HP.classes [ H.ClassName "text-sm bg-gray-800 hover:bg-gray-700 text-white px-3.5 py-1.5 rounded-lg no-underline" ]
            ]
            [ HH.text "Login" ]
    ]
