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
    , HP.attr (H.AttrName "stroke-width") "2"
    , HP.attr (H.AttrName "stroke-linecap") "round"
    , HP.attr (H.AttrName "stroke-linejoin") "round"
    , HP.attr (H.AttrName "class") "w-4 h-4"
    ]
    [ svgElement (H.ElemName "circle") [ HP.attr (H.AttrName "cx") "11", HP.attr (H.AttrName "cy") "11", HP.attr (H.AttrName "r") "8" ] []
    , svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "m21 21-4.3-4.3" ] []
    ]

userIcon :: forall w i. HH.HTML w i
userIcon =
  svgElement (H.ElemName "svg")
    [ HP.attr (H.AttrName "viewBox") "0 0 24 24"
    , HP.attr (H.AttrName "fill") "none"
    , HP.attr (H.AttrName "stroke") "#3b82f6"
    , HP.attr (H.AttrName "stroke-width") "2"
    , HP.attr (H.AttrName "stroke-linecap") "round"
    , HP.attr (H.AttrName "stroke-linejoin") "round"
    , HP.attr (H.AttrName "class") "w-5 h-5"
    ]
    [ svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" ] []
    , svgElement (H.ElemName "circle") [ HP.attr (H.AttrName "cx") "12", HP.attr (H.AttrName "cy") "7", HP.attr (H.AttrName "r") "4" ] []
    ]

editIcon :: forall w i. HH.HTML w i
editIcon =
  svgElement (H.ElemName "svg")
    [ HP.attr (H.AttrName "viewBox") "0 0 24 24"
    , HP.attr (H.AttrName "fill") "none"
    , HP.attr (H.AttrName "stroke") "currentColor"
    , HP.attr (H.AttrName "stroke-width") "2"
    , HP.attr (H.AttrName "stroke-linecap") "round"
    , HP.attr (H.AttrName "stroke-linejoin") "round"
    , HP.attr (H.AttrName "class") "w-4 h-4"
    ]
    [ svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z" ] [] ]

trashIcon :: forall w i. HH.HTML w i
trashIcon =
  svgElement (H.ElemName "svg")
    [ HP.attr (H.AttrName "viewBox") "0 0 24 24"
    , HP.attr (H.AttrName "fill") "none"
    , HP.attr (H.AttrName "stroke") "currentColor"
    , HP.attr (H.AttrName "stroke-width") "2"
    , HP.attr (H.AttrName "stroke-linecap") "round"
    , HP.attr (H.AttrName "stroke-linejoin") "round"
    , HP.attr (H.AttrName "class") "w-4 h-4"
    ]
    [ svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M3 6h18" ] []
    , svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" ] []
    , svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" ] []
    , svgElement (H.ElemName "line") [ HP.attr (H.AttrName "x1") "10", HP.attr (H.AttrName "x2") "10", HP.attr (H.AttrName "y1") "11", HP.attr (H.AttrName "y2") "17" ] []
    , svgElement (H.ElemName "line") [ HP.attr (H.AttrName "x1") "14", HP.attr (H.AttrName "x2") "14", HP.attr (H.AttrName "y1") "11", HP.attr (H.AttrName "y2") "17" ] []
    ]

logoutIcon :: forall w i. HH.HTML w i
logoutIcon =
  svgElement (H.ElemName "svg")
    [ HP.attr (H.AttrName "viewBox") "0 0 24 24"
    , HP.attr (H.AttrName "fill") "none"
    , HP.attr (H.AttrName "stroke") "currentColor"
    , HP.attr (H.AttrName "stroke-width") "2"
    , HP.attr (H.AttrName "stroke-linecap") "round"
    , HP.attr (H.AttrName "stroke-linejoin") "round"
    , HP.attr (H.AttrName "class") "w-4 h-4"
    ]
    [ svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" ] []
    , svgElement (H.ElemName "polyline") [ HP.attr (H.AttrName "points") "16 17 21 12 16 7" ] []
    , svgElement (H.ElemName "line") [ HP.attr (H.AttrName "x1") "21", HP.attr (H.AttrName "x2") "9", HP.attr (H.AttrName "y1") "12", HP.attr (H.AttrName "y2") "12" ] []
    ]
