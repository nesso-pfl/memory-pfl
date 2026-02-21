module Page.TopPage.Search where

import Prelude

import Component.Router.Types (Action(..), State)
import Data.Array (elem, filter, null) as Array
import Data.String.CodeUnits (contains) as String
import Data.String.Common (null, toLower) as String
import Data.String.Pattern (Pattern(..))
import Data.Tab (Tab(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Html.Icons (searchIcon)

tabControl :: forall slots m. State -> H.ComponentHTML Action slots m
tabControl state =
  HH.div
    [ HP.classes [ H.ClassName "border-b border-gray-200 px-4 py-2" ] ]
    [ HH.div
        [ HP.classes [ H.ClassName "flex bg-gray-100 rounded-2xl p-1 gap-1" ] ]
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
    | tab == activeTab = "flex-1 text-sm py-2 rounded-xl font-semibold bg-white shadow-sm text-gray-900"
    | otherwise = "flex-1 text-sm py-2 rounded-xl font-medium text-gray-600 hover:text-gray-900"

tagSearch :: forall slots m. State -> H.ComponentHTML Action slots m
tagSearch state =
  HH.div
    [ HP.ref (H.RefLabel "tagSearch")
    , HP.classes [ H.ClassName "px-5 pt-3 relative" ]
    ]
    ( [ HH.div
          [ HP.classes [ H.ClassName "w-full border border-gray-200 rounded-xl px-2 py-1.5 flex flex-wrap items-center gap-1.5 focus-within:ring-2 focus-within:ring-blue-200 focus-within:border-blue-300" ] ]
          ( map chip state.filterTags <>
            [ HH.input
                [ HP.type_ HP.InputText
                , HP.name "tag"
                , HP.placeholder (if Array.null state.filterTags then "タグで検索..." else "")
                , HP.value state.tagInput
                , HE.onValueInput SetTagInput
                , HE.onFocusIn \_ -> TagFocus
                , HP.classes [ H.ClassName "flex-1 min-w-[80px] text-sm py-1 px-1.5 outline-none" ]
                ]
            ]
          )
      ] <> suggestions
    )
  where
  chip t =
    HH.span
      [ HP.classes [ H.ClassName "inline-flex items-center gap-0.5 text-xs font-medium bg-blue-100 text-blue-700 pl-2.5 pr-1 py-1 rounded-full" ] ]
      [ HH.text t
      , HH.button
          [ HE.onClick \_ -> RemoveTag t
          , HP.classes [ H.ClassName "ml-0.5 w-4 h-4 flex items-center justify-center rounded-full hover:bg-blue-200 text-blue-500" ]
          ]
          [ HH.text "\x2715" ]
      ]
  available = Array.filter (\t -> not (Array.elem t state.filterTags)) state.allTags
  matched
    | String.null state.tagInput = available
    | otherwise =
        let
          input = String.toLower state.tagInput
        in
          Array.filter (\t -> String.contains (Pattern input) (String.toLower t)) available
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
    [ HP.classes [ H.ClassName "px-5 pt-2 pb-3 flex gap-2 border-b border-gray-200" ] ]
    [ HH.input
        [ HP.type_ HP.InputText
        , HP.name "query"
        , HP.placeholder "キーワードで検索..."
        , HP.value state.searchQuery
        , HE.onValueInput SetSearchQuery
        , HP.classes [ H.ClassName "flex-1 border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-200 focus:border-blue-300" ]
        ]
    , HH.button
        [ HP.attr (H.AttrName "aria-label") "検索"
        , HE.onClick \_ -> SubmitSearch
        , HP.disabled (state.searching || String.null state.searchQuery)
        , HP.classes [ H.ClassName "w-10 h-10 flex items-center justify-center bg-black/80 hover:bg-black/60 text-white rounded-xl disabled:opacity-40 disabled:hover:bg-black/80" ]
        ]
        [ searchIcon ]
    ]
