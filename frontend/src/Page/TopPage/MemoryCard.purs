module Page.TopPage.MemoryCard where

import Prelude

import Component.Router.Types (Action(..))
import Data.Maybe (Maybe(..))
import Data.Memory (Memory)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Html.Icons (editIcon, trashIcon)

memoryCard :: forall slots m. Maybe String -> Maybe String -> Memory -> H.ComponentHTML Action slots m
memoryCard activeTag confirmingDelete mem =
  HH.div
    [ HP.classes [ H.ClassName "relative border border-gray-200 rounded-xl p-5 flex flex-col gap-3 bg-white" ] ]
    ( [ HH.div
          [ HP.classes [ H.ClassName "flex items-start gap-3" ] ]
          [ HH.p
              [ HP.classes [ H.ClassName "flex-1 text-sm leading-relaxed text-gray-800 whitespace-pre-wrap" ] ]
              [ HH.text mem.content ]
          , HH.div
              [ HP.classes [ H.ClassName "flex gap-1 shrink-0" ] ]
              [ HH.button
                  [ HE.onClick \_ -> StartEdit mem
                  , HP.classes [ H.ClassName "p-1.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100" ]
                  ]
                  [ editIcon ]
              , HH.button
                  [ HE.onClick \_ -> DeleteMemory mem.id
                  , HP.classes [ H.ClassName "p-1.5 rounded-lg text-red-400 hover:text-red-600 hover:bg-red-50" ]
                  ]
                  [ trashIcon ]
              ]
          ]
      , HH.div
          [ HP.classes [ H.ClassName "flex gap-1.5 flex-wrap" ] ]
          (map (tagBadge activeTag) mem.tags)
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

tagBadge :: forall slots m. Maybe String -> String -> H.ComponentHTML Action slots m
tagBadge activeTag t =
  HH.button
    [ HE.onClick \_ -> SelectTag t
    , HP.classes [ H.ClassName classes ]
    ]
    [ HH.text t ]
  where
  classes
    | activeTag == Just t = "text-xs font-medium bg-blue-500 text-white px-2.5 py-1 rounded-full"
    | otherwise = "text-xs font-medium text-blue-500 border border-blue-200 bg-blue-50 px-2.5 py-1 rounded-full hover:bg-blue-100"

