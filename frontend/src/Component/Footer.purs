module Component.Footer where

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

footer :: forall w i. HH.HTML w i
footer =
  HH.footer
    [ HP.classes [ H.ClassName "py-2 text-center text-xs text-gray-400" ] ]
    [ HH.text "developed by "
    , HH.a
        [ HP.href "https://github.com/nesso-pfl"
        , HP.target "_blank"
        , HP.classes [ H.ClassName "text-gray-400 hover:text-gray-600 underline" ]
        ]
        [ HH.text "nesso-pfl" ]
    ]
