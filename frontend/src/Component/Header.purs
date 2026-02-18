module Component.Header where

import Prelude

import Component.Router.Types (Action(..), State)
import Data.Maybe (Maybe(..))
import Data.String.CodeUnits (take) as String
import Data.String.Common (toUpper) as String
import Data.User (displayName)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Html.Icons (logoutIcon)

header :: forall slots m. State -> H.ComponentHTML Action slots m
header state =
  HH.header
    [ HP.classes [ H.ClassName "bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between sticky top-0 z-10" ] ]
    [ HH.a
        [ HP.href "/"
        , HP.classes [ H.ClassName "text-lg font-bold tracking-tight text-gray-900 no-underline" ]
        ]
        [ HH.text "memory-pfl" ]
    , case state.profile of
        Just p ->
          HH.div
            [ HP.classes [ H.ClassName "relative" ]
            , HP.ref (H.RefLabel "userMenu")
            ]
            [ HH.button
                [ HP.classes [ H.ClassName "w-9 h-9 bg-blue-600 rounded-full flex items-center justify-center text-white font-semibold text-sm cursor-pointer hover:bg-blue-700 transition-colors" ]
                , HE.onClick \_ -> ToggleUserMenu
                ]
                [ HH.text (String.toUpper (String.take 1 (displayName p))) ]
            , if state.showUserMenu then userMenu p else HH.text ""
            ]
        Nothing ->
          HH.a
            [ HP.href "/auth/login"
            , HP.classes [ H.ClassName "text-sm bg-gray-800 hover:bg-gray-700 text-white px-3.5 py-1.5 rounded-lg no-underline" ]
            ]
            [ HH.text "Login" ]
    ]

userMenu :: forall slots m. { sub :: String, name :: Maybe String, preferred_username :: Maybe String, email :: Maybe String } -> H.ComponentHTML Action slots m
userMenu p =
  HH.div
    [ HP.classes [ H.ClassName "absolute right-0 top-12 bg-white rounded-lg shadow-lg border border-gray-200 py-2 w-56 z-50" ] ]
    [ HH.div
        [ HP.classes [ H.ClassName "px-4 py-2 border-b border-gray-100" ] ]
        [ HH.div
            [ HP.classes [ H.ClassName "text-sm font-medium text-gray-900" ] ]
            [ HH.text (displayName p) ]
        , case p.email of
            Just email ->
              HH.div
                [ HP.classes [ H.ClassName "text-xs text-gray-500 mt-0.5" ] ]
                [ HH.text email ]
            Nothing -> HH.text ""
        ]
    , HH.button
        [ HP.classes [ H.ClassName "w-full flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 cursor-pointer" ]
        , HE.onClick \_ -> Logout
        ]
        [ logoutIcon
        , HH.text "ログアウト"
        ]
    ]
