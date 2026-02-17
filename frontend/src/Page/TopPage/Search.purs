module Page.TopPage.Search where

import Prelude

import Component.Router.Types (Action(..), State)
import Data.Array (filter, null) as Array
import Data.String.CodeUnits (contains) as String
import Data.String.Common (null, toLower) as String
import Data.String.Pattern (Pattern(..))
import Data.Tab (Tab(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Html.Svg (svgElement)

tabControl :: forall slots m. State -> H.ComponentHTML Action slots m
tabControl state =
  HH.div
    [ HP.classes [ H.ClassName "px-5 pt-4 pb-1" ] ]
    [ HH.div
        [ HP.classes [ H.ClassName "flex bg-gray-100 rounded-xl p-1 gap-1" ] ]
        [ tabButton "開発" Development state.tab
        , tabButton "一般" General state.tab
        ]
    ]

tabButton :: forall slots m. String -> Tab -> Tab -> H.ComponentHTML Action slots m
tabButton label tab activeTab =
  HH.button
    [ HE.onClick \_ -> SetTab tab
    , HP.classes [ H.ClassName classes ]
    ]
    [ HH.text label ]
  where
  classes
    | tab == activeTab = "flex-1 text-sm py-2 rounded-lg font-semibold bg-white shadow-sm text-gray-900"
    | otherwise = "flex-1 text-sm py-2 rounded-lg font-medium text-gray-400 hover:text-gray-600"

tagSearch :: forall slots m. State -> H.ComponentHTML Action slots m
tagSearch state =
  HH.div
    [ HP.ref (H.RefLabel "tagSearch")
    , HP.classes [ H.ClassName "px-5 pt-3 relative" ]
    ]
    ( [ HH.input
          [ HP.type_ HP.InputText
          , HP.placeholder "\x1F50D タグで検索..."
          , HP.value state.tagInput
          , HE.onValueInput SetTagInput
          , HE.onFocusIn \_ -> TagFocus
          , HP.classes [ H.ClassName "w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-200 focus:border-blue-300" ]
          ]
      ] <> suggestions
    )
  where
  matched
    | String.null state.tagInput = state.allTags
    | otherwise =
        let input = String.toLower state.tagInput
        in Array.filter (\t -> String.contains (Pattern input) (String.toLower t)) state.allTags
  suggestions
    | not state.tagFocused = []
    | Array.null matched = []
    | otherwise =
        [ HH.div
            [ HP.classes [ H.ClassName "absolute left-5 right-5 mt-1.5 bg-white border border-gray-200 rounded-xl shadow-lg z-20 max-h-48 overflow-y-auto py-1" ] ]
            (map suggestionItem matched)
        ]
  suggestionItem t =
    HH.button
      [ HE.onClick \_ -> SelectTag t
      , HP.classes [ H.ClassName "w-full text-left px-4 py-2 text-sm hover:bg-gray-50 text-gray-700" ]
      ]
      [ HH.text t ]

searchBar :: forall slots m. State -> H.ComponentHTML Action slots m
searchBar state =
  HH.div
    [ HP.classes [ H.ClassName "px-5 pt-2 flex gap-2" ] ]
    [ HH.input
        [ HP.type_ HP.InputText
        , HP.placeholder "キーワードで検索"
        , HP.value state.searchQuery
        , HE.onValueInput SetSearchQuery
        , HP.classes [ H.ClassName "flex-1 border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-200 focus:border-blue-300" ]
        ]
    , HH.button
        [ HE.onClick \_ -> SubmitSearch
        , HP.disabled (state.searching || String.null state.searchQuery)
        , HP.classes [ H.ClassName "w-10 h-10 flex items-center justify-center bg-blue-500 hover:bg-blue-600 text-white rounded-xl disabled:opacity-40 disabled:hover:bg-blue-500" ]
        ]
        [ svgElement (H.ElemName "svg")
            [ HP.attr (H.AttrName "viewBox") "0 0 24 24"
            , HP.attr (H.AttrName "fill") "none"
            , HP.attr (H.AttrName "stroke") "currentColor"
            , HP.attr (H.AttrName "stroke-width") "2.5"
            , HP.classes [ H.ClassName "w-4.5 h-4.5" ]
            ]
            [ svgElement (H.ElemName "circle") [ HP.attr (H.AttrName "cx") "11", HP.attr (H.AttrName "cy") "11", HP.attr (H.AttrName "r") "7" ] []
            , svgElement (H.ElemName "path") [ HP.attr (H.AttrName "d") "M21 21l-4.35-4.35" ] []
            ]
        ]
    ]
