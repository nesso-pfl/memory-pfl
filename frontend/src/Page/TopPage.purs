module Page.TopPage where

import Prelude

import Component.Router.Types (Action(..), State)
import Data.Maybe (Maybe(..), isJust)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Html.Icons (loaderIcon)
import Page.TopPage.MemoryCard (memoryCard)
import Page.TopPage.Search (tabControl, tagSearch, searchBar)

topPage :: forall slots m. State -> H.ComponentHTML Action slots m
topPage state =
  HH.main
    [ HP.classes [ H.ClassName "flex-1 flex flex-col" ] ]
    ( [ tabControl state
      , tagSearch state
      , searchBar state
      , resultList state
      ] <> if isJust state.profile then [ fab ] else []
    )

resultList :: forall slots m. State -> H.ComponentHTML Action slots m
resultList state =
  HH.div
    [ HP.classes [ H.ClassName "flex-1 px-5 py-4 flex flex-col gap-3 bg-gray-50" ] ]
    (filterBadge <> content)
  where
  filterBadge = case state.filterTag of
    Just t ->
      [ HH.div
          [ HP.classes [ H.ClassName "flex items-center gap-2" ] ]
          [ HH.span
              [ HP.classes [ H.ClassName "text-xs text-gray-400" ] ]
              [ HH.text "タグ:" ]
          , HH.button
              [ HE.onClick \_ -> ClearTag
              , HP.classes [ H.ClassName "text-xs bg-gray-800 text-white pl-2.5 pr-2 py-1 rounded-full inline-flex items-center gap-1 hover:bg-gray-700" ]
              ]
              [ HH.text t, HH.text " \x2715" ]
          ]
      ]
    Nothing -> []
  content
    | state.loading && state.memories == [] =
        [ HH.div
            [ HP.classes [ H.ClassName "flex justify-center mt-12 text-gray-400" ] ]
            [ loaderIcon ]
        ]
    | state.memories == [] =
        [ HH.p
            [ HP.classes [ H.ClassName "text-sm text-gray-400 text-center mt-12" ] ]
            [ HH.text "検索結果がありません" ]
        ]
    | otherwise = map (memoryCard state.filterTag state.confirmingDelete) state.memories

fab :: forall slots m. H.ComponentHTML Action slots m
fab =
  HH.button
    [ HP.attr (H.AttrName "aria-label") "メモリを作成"
    , HE.onClick \_ -> OpenModal
    , HP.classes [ H.ClassName "fixed bottom-6 right-6 w-14 h-14 bg-gray-800 hover:bg-gray-700 text-white rounded-full shadow-lg text-2xl flex items-center justify-center" ]
    ]
    [ HH.text "＋" ]
