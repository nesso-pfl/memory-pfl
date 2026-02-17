module Html.Icons where

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Html.Svg (svgElement)

searchIcon :: forall w i. HH.HTML w i
searchIcon =
  svgElement (H.ElemName "svg")
    [ HP.attr (H.AttrName "viewBox") "0 0 24 24"
    , HP.attr (H.AttrName "fill") "none"
    , HP.attr (H.AttrName "stroke") "currentColor"
    , HP.attr (H.AttrName "stroke-width") "2.5"
    , HP.classes [ H.ClassName "w-4.5 h-4.5" ]
    ]
    [ svgElement (H.ElemName "circle") [ HP.attr (H.AttrName "cx") "11", HP.attr (H.AttrName "cy") "11", HP.attr (H.AttrName "r") "7" ] []
    , svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M21 21l-4.35-4.35" ] []
    ]

userIcon :: forall w i. HH.HTML w i
userIcon =
  svgElement (H.ElemName "svg")
    [ HP.attr (H.AttrName "viewBox") "0 0 24 24"
    , HP.attr (H.AttrName "fill") "none"
    , HP.attr (H.AttrName "stroke") "#3b82f6"
    , HP.attr (H.AttrName "stroke-width") "2"
    , HP.classes [ H.ClassName "w-5 h-5" ]
    ]
    [ svgElement (H.ElemName "circle") [ HP.attr (H.AttrName "cx") "12", HP.attr (H.AttrName "cy") "8", HP.attr (H.AttrName "r") "4" ] []
    , svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M4 21v-1a6 6 0 0 1 12 0v1" ] []
    ]

editIcon :: forall w i. HH.HTML w i
editIcon =
  svgElement (H.ElemName "svg")
    [ HP.attr (H.AttrName "viewBox") "0 0 24 24"
    , HP.attr (H.AttrName "fill") "none"
    , HP.attr (H.AttrName "stroke") "currentColor"
    , HP.attr (H.AttrName "stroke-width") "2"
    , HP.classes [ H.ClassName "w-4 h-4" ]
    ]
    [ svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M17 3a2.83 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z" ] [] ]

trashIcon :: forall w i. HH.HTML w i
trashIcon =
  svgElement (H.ElemName "svg")
    [ HP.attr (H.AttrName "viewBox") "0 0 24 24"
    , HP.attr (H.AttrName "fill") "none"
    , HP.attr (H.AttrName "stroke") "currentColor"
    , HP.attr (H.AttrName "stroke-width") "2"
    , HP.classes [ H.ClassName "w-4 h-4" ]
    ]
    [ svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M3 6h18" ] []
    , svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" ] []
    , svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" ] []
    ]
