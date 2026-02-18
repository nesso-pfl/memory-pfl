module Page.TopPage.Modal where

import Prelude

import Component.Router.Types (Action(..), State)
import Data.Maybe (Maybe(..), isJust)
import Data.String.Common (null) as String
import Data.Tab (Tab(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

modal :: forall slots m. State -> H.ComponentHTML Action slots m
modal state =
  HH.div
    [ HP.classes [ H.ClassName "fixed inset-0 z-50 flex items-end sm:items-center justify-center" ] ]
    [ HH.div
        [ HE.onClick \_ -> CloseModal
        , HP.classes [ H.ClassName "absolute inset-0 bg-black/40" ]
        ]
        []
    , HH.div
        [ HP.classes [ H.ClassName "relative bg-white rounded-t-2xl sm:rounded-2xl shadow-2xl w-full sm:max-w-md sm:mx-4 p-6 flex flex-col gap-5" ] ]
        if state.submitSuccess then
          [ HH.p
              [ HP.classes [ H.ClassName "text-sm text-green-600 text-center py-6" ] ]
              [ HH.text "保存に成功しました" ]
          , HH.div
              [ HP.classes [ H.ClassName "flex justify-end" ] ]
              [ HH.button
                  [ HE.onClick \_ -> CloseModal
                  , HP.classes [ H.ClassName "px-5 py-2.5 text-sm font-medium bg-gray-800 hover:bg-gray-700 text-white rounded-xl" ]
                  ]
                  [ HH.text "閉じる" ]
              ]
          ]
        else
          [ HH.h2
              [ HP.classes [ H.ClassName "text-lg font-bold text-gray-900" ] ]
              [ HH.text if isJust state.editingId then "メモリを編集" else "メモリを作成" ]
          , HH.textarea
              [ HP.placeholder "内容を入力..."
              , HP.value state.formContent
              , HE.onValueInput SetFormContent
              , HP.classes [ H.ClassName "w-full border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-blue-200 focus:border-blue-300 resize-none h-32" ]
              ]
          , HH.input
              [ HP.type_ HP.InputText
              , HP.placeholder "タグ（カンマ区切り）"
              , HP.value state.formTags
              , HE.onValueInput SetFormTags
              , HP.classes [ H.ClassName "w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-200 focus:border-blue-300" ]
              ]
          , HH.div
              [ HP.classes [ H.ClassName "flex bg-gray-100 rounded-xl p-1 gap-1" ] ]
              [ categoryButton "開発" Development state.formCategory
              , categoryButton "一般" General state.formCategory
              ]
          , case state.submitError of
              Just err ->
                HH.p
                  [ HP.classes [ H.ClassName "text-sm text-red-500" ] ]
                  [ HH.text err ]
              Nothing -> HH.text ""
          , HH.div
              [ HP.classes [ H.ClassName "flex gap-3 justify-end" ] ]
              [ HH.button
                  [ HE.onClick \_ -> CloseModal
                  , HP.classes [ H.ClassName "px-5 py-2.5 text-sm font-medium text-gray-500 rounded-xl hover:bg-gray-100" ]
                  ]
                  [ HH.text "キャンセル" ]
              , HH.button
                  [ HE.onClick \_ -> SubmitMemory
                  , HP.disabled (state.submitting || String.null state.formContent)
                  , HP.classes [ H.ClassName "px-5 py-2.5 text-sm font-medium bg-gray-800 hover:bg-gray-700 text-white rounded-xl disabled:opacity-40 disabled:hover:bg-gray-800" ]
                  ]
                  [ HH.text if state.submitting then "保存中..." else "保存" ]
              ]
          ]
    ]

categoryButton :: forall slots m. String -> Tab -> Tab -> H.ComponentHTML Action slots m
categoryButton label cat activeCat =
  HH.button
    [ HE.onClick \_ -> SetFormCategory cat
    , HP.classes [ H.ClassName classes ]
    ]
    [ HH.text label ]
  where
  classes
    | cat == activeCat = "flex-1 text-sm py-2 rounded-lg font-semibold bg-white shadow-sm text-gray-900"
    | otherwise = "flex-1 text-sm py-2 rounded-lg font-medium text-gray-400 hover:text-gray-600"
