module Component.Router where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Route (Route(..))
import Data.Tab (Tab(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

type State =
  { route :: Maybe Route
  , tab :: Tab
  , isLoggedIn :: Boolean
  }

data Query a = Navigate Route a

data Action = Initialize | SetTab Tab

component :: forall i o m. H.Component Query i o m
component = H.mkComponent
  { initialState: \_ -> { route: Nothing, tab: Development, isLoggedIn: false }
  , render
  , eval: H.mkEval $ H.defaultEval
      { handleQuery = handleQuery
      , handleAction = handleAction
      , initialize = Just Initialize
      }
  }

render :: forall slots m. State -> H.ComponentHTML Action slots m
render state = case state.route of
  Just Home ->
    HH.div
      [ HP.classes [ H.ClassName "min-h-screen flex flex-col bg-gray-50" ] ]
      [ header state
      , main state
      , footer
      ]
  Nothing ->
    HH.div_ [ HH.text "Loading..." ]

header :: forall slots m. State -> H.ComponentHTML Action slots m
header state =
  HH.header
    [ HP.classes [ H.ClassName "sticky top-0 z-10 bg-white border-b px-4 py-3 flex items-center justify-between" ] ]
    [ HH.a
        [ HP.href "/"
        , HP.classes [ H.ClassName "text-lg font-bold text-gray-900 no-underline" ]
        ]
        [ HH.text "memory-pfl" ]
    , if state.isLoggedIn
        then HH.span [ HP.classes [ H.ClassName "text-sm text-gray-500" ] ] [ HH.text "ログイン済" ]
        else HH.button
          [ HP.classes [ H.ClassName "text-sm bg-gray-900 text-white px-3 py-1.5 rounded" ] ]
          [ HH.text "Login" ]
    ]

main :: forall slots m. State -> H.ComponentHTML Action slots m
main state =
  HH.main
    [ HP.classes [ H.ClassName "flex-1 flex flex-col" ] ]
    [ searchBar
    , tabControl state
    , resultList
    , fab
    ]

searchBar :: forall slots m. H.ComponentHTML Action slots m
searchBar =
  HH.div
    [ HP.classes [ H.ClassName "px-4 pt-4" ] ]
    [ HH.input
        [ HP.type_ HP.InputText
        , HP.placeholder "\x1F50D 検索..."
        , HP.classes [ H.ClassName "w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" ]
        ]
    ]

tabControl :: forall slots m. State -> H.ComponentHTML Action slots m
tabControl state =
  HH.div
    [ HP.classes [ H.ClassName "px-4 pt-3 pb-2" ] ]
    [ HH.div
        [ HP.classes [ H.ClassName "flex bg-gray-200 rounded-lg p-1" ] ]
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
    | tab == activeTab = "flex-1 text-sm py-1.5 rounded-md font-medium bg-white shadow"
    | otherwise = "flex-1 text-sm py-1.5 rounded-md font-medium text-gray-500"

resultList :: forall slots m. H.ComponentHTML Action slots m
resultList =
  HH.div
    [ HP.classes [ H.ClassName "flex-1 px-4 py-4" ] ]
    [ HH.p
        [ HP.classes [ H.ClassName "text-sm text-gray-400 text-center mt-8" ] ]
        [ HH.text "検索結果がありません" ]
    ]

fab :: forall slots m. H.ComponentHTML Action slots m
fab =
  HH.button
    [ HP.classes [ H.ClassName "fixed bottom-6 right-6 w-14 h-14 bg-gray-900 text-white rounded-full shadow-lg text-2xl flex items-center justify-center" ] ]
    [ HH.text "＋" ]

footer :: forall slots m. H.ComponentHTML Action slots m
footer =
  HH.footer
    [ HP.classes [ H.ClassName "border-t py-3 text-center text-xs text-gray-400" ] ]
    [ HH.text "developed by "
    , HH.a
        [ HP.href "https://github.com/nesso-pfl"
        , HP.target "_blank"
        , HP.classes [ H.ClassName "underline" ]
        ]
        [ HH.text "nesso-pfl" ]
    ]

handleAction :: forall slots o m. Action -> H.HalogenM State Action slots o m Unit
handleAction = case _ of
  Initialize -> pure unit
  SetTab tab -> H.modify_ _ { tab = tab }

handleQuery :: forall action slots o m a. Query a -> H.HalogenM State action slots o m (Maybe a)
handleQuery (Navigate route a) = do
  H.modify_ _ { route = Just route }
  pure (Just a)
