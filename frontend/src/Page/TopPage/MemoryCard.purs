module Page.TopPage.MemoryCard where

import Prelude

import Component.Router.Types (Action(..))
import Data.Array (elem) as Array
import Data.Maybe (Maybe(..))
import Data.Memory (Memory)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Html.Icons (editIcon, trashIcon)

memoryCard :: forall slots m. Array String -> Maybe String -> Memory -> H.ComponentHTML Action slots m
memoryCard activeTags confirmingDelete mem =
  HH.div
    [ HP.classes [ H.ClassName "relative border border-gray-300 rounded-xl p-3 flex flex-col gap-3 bg-white" ] ]
    ( [ HH.div
          [ HP.classes [ H.ClassName "flex items-start gap-3" ] ]
          [ HH.p
              [ HP.classes [ H.ClassName "flex-1 text-sm leading-relaxed text-gray-800 whitespace-pre-wrap" ] ]
              [ HH.text mem.content ]
          , HH.div
              [ HP.classes [ H.ClassName "flex gap-1 shrink-0" ] ]
              [ HH.button
                  [ HP.attr (H.AttrName "aria-label") "編集"
                  , HE.onClick \_ -> StartEdit mem
                  , HP.classes [ H.ClassName "p-2 rounded-lg text-blue-500 hover:text-blue-600 hover:bg-blue-100" ]
                  ]
                  [ editIcon ]
              , HH.button
                  [ HP.attr (H.AttrName "aria-label") "削除"
                  , HE.onClick \_ -> DeleteMemory mem.id
                  , HP.classes [ H.ClassName "p-2 rounded-lg text-red-500 hover:text-red-600 hover:bg-red-100" ]
                  ]
                  [ trashIcon ]
              ]
          ]
      , HH.div
          [ HP.classes [ H.ClassName "flex gap-1.5 flex-wrap" ] ]
          (map (tagBadge activeTags) mem.tags)
      ] <> deleteConfirm
    )
  where
  deleteConfirm
    | confirmingDelete == Just mem.id =
        [ HH.div
            [ HP.classes [ H.ClassName "flex items-center justify-between pt-2 border-t border-gray-100" ] ]
            [ HH.span
                [ HP.classes [ H.ClassName "text-sm text-gray-500" ] ]
                [ HH.text "削除しますか？" ]
            , HH.div
                [ HP.classes [ H.ClassName "flex gap-2" ] ]
                [ HH.button
                    [ HE.onClick \_ -> CancelDelete
                    , HP.classes [ H.ClassName "text-xs px-3 py-1.5 rounded-lg text-gray-500 hover:bg-gray-100" ]
                    ]
                    [ HH.text "キャンセル" ]
                , HH.button
                    [ HE.onClick \_ -> ConfirmDelete
                    , HP.classes [ H.ClassName "text-xs px-3 py-1.5 rounded-lg bg-red-500 hover:bg-red-600 text-white" ]
                    ]
                    [ HH.text "削除" ]
                ]
            ]
        ]
    | otherwise = []

tagBadge :: forall slots m. Array String -> String -> H.ComponentHTML Action slots m
tagBadge activeTags t =
  HH.button
    [ HE.onClick \_ -> SelectTag t
    , HP.classes [ H.ClassName classes ]
    ]
    [ HH.text t ]
  where
  classes
    | Array.elem t activeTags = "text-xs font-medium bg-blue-500 text-white px-2.5 py-1 rounded-full"
    | otherwise = "text-xs font-medium text-blue-500 border border-blue-200 bg-blue-50 px-2.5 py-1 rounded-full hover:bg-blue-100"

