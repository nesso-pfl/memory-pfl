module Component.Router where

import Prelude

import Data.Argonaut.Core (jsonEmptyObject, stringify)
import Data.Argonaut.Decode.Class (decodeJson)
import Data.Argonaut.Encode.Combinators ((:=), (~>))
import Data.Argonaut.Parser (jsonParser)
import Data.Array (filter) as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), isJust)
import Data.Route (Route(..))
import Data.String.Common (split, trim, null) as String
import Data.String.Pattern (Pattern(..))
import Data.Tab (Tab(..))
import Data.UserProfile (UserProfile)
import Effect.Aff.Class (class MonadAff)
import Data.HTTP.Method (Method(..))
import Fetch (fetch)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

type State =
  { route :: Maybe Route
  , tab :: Tab
  , profile :: Maybe UserProfile
  , showModal :: Boolean
  , formContent :: String
  , formTags :: String
  , formCategory :: Tab
  , submitting :: Boolean
  , submitError :: Maybe String
  }

data Query a = Navigate Route a

data Action
  = Initialize
  | SetTab Tab
  | OpenModal
  | CloseModal
  | SetFormContent String
  | SetFormTags String
  | SetFormCategory Tab
  | SubmitMemory

component :: forall i o m. MonadAff m => H.Component Query i o m
component = H.mkComponent
  { initialState: \_ ->
      { route: Nothing
      , tab: Development
      , profile: Nothing
      , showModal: false
      , formContent: ""
      , formTags: ""
      , formCategory: Development
      , submitting: false
      , submitError: Nothing
      }
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
      ( [ header state
        , main state
        , footer
        ] <> if state.showModal then [ modal state ] else []
      )
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
    , case state.profile of
        Just p ->
          HH.span
            [ HP.classes [ H.ClassName "text-sm text-gray-500" ] ]
            [ HH.text (displayName p) ]
        Nothing ->
          HH.a
            [ HP.href "/auth/login"
            , HP.classes [ H.ClassName "text-sm bg-gray-900 text-white px-3 py-1.5 rounded no-underline" ]
            ]
            [ HH.text "Login" ]
    ]

main :: forall slots m. State -> H.ComponentHTML Action slots m
main state =
  HH.main
    [ HP.classes [ H.ClassName "flex-1 flex flex-col" ] ]
    ( [ searchBar
      , tabControl state
      , resultList
      ] <> if isJust state.profile then [ fab ] else []
    )

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
    [ HE.onClick \_ -> OpenModal
    , HP.classes [ H.ClassName "fixed bottom-6 right-6 w-14 h-14 bg-gray-900 text-white rounded-full shadow-lg text-2xl flex items-center justify-center" ]
    ]
    [ HH.text "＋" ]

modal :: forall slots m. State -> H.ComponentHTML Action slots m
modal state =
  HH.div
    [ HP.classes [ H.ClassName "fixed inset-0 z-50 flex items-center justify-center" ] ]
    [ HH.div
        [ HE.onClick \_ -> CloseModal
        , HP.classes [ H.ClassName "absolute inset-0 bg-black/50" ]
        ]
        []
    , HH.div
        [ HP.classes [ H.ClassName "relative bg-white rounded-xl shadow-xl w-full max-w-md mx-4 p-6 flex flex-col gap-4" ] ]
        [ HH.h2
            [ HP.classes [ H.ClassName "text-lg font-bold text-gray-900" ] ]
            [ HH.text "メモリを作成" ]
        , HH.textarea
            [ HP.placeholder "内容を入力..."
            , HP.value state.formContent
            , HE.onValueInput SetFormContent
            , HP.classes [ H.ClassName "w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300 resize-none h-32" ]
            ]
        , HH.input
            [ HP.type_ HP.InputText
            , HP.placeholder "タグ（カンマ区切り）"
            , HP.value state.formTags
            , HE.onValueInput SetFormTags
            , HP.classes [ H.ClassName "w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" ]
            ]
        , HH.div
            [ HP.classes [ H.ClassName "flex bg-gray-200 rounded-lg p-1" ] ]
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
                , HP.classes [ H.ClassName "px-4 py-2 text-sm text-gray-500 rounded-lg hover:bg-gray-100" ]
                ]
                [ HH.text "キャンセル" ]
            , HH.button
                [ HE.onClick \_ -> SubmitMemory
                , HP.disabled state.submitting
                , HP.classes [ H.ClassName "px-4 py-2 text-sm bg-gray-900 text-white rounded-lg disabled:opacity-50" ]
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
    | cat == activeCat = "flex-1 text-sm py-1.5 rounded-md font-medium bg-white shadow"
    | otherwise = "flex-1 text-sm py-1.5 rounded-md font-medium text-gray-500"

displayName :: UserProfile -> String
displayName p = case p.preferred_username of
  Just name -> name
  Nothing -> case p.name of
    Just name -> name
    Nothing -> p.sub

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

handleAction :: forall slots o m. MonadAff m => Action -> H.HalogenM State Action slots o m Unit
handleAction = case _ of
  Initialize -> do
    response <- H.liftAff $ fetch "/auth/me" {}
    when (response.status == 200) do
      text <- H.liftAff response.text
      case jsonParser text of
        Right json -> case decodeJson json of
          Right p -> H.modify_ _ { profile = Just p }
          Left _ -> pure unit
        Left _ -> pure unit
  SetTab tab -> H.modify_ _ { tab = tab }
  OpenModal -> H.modify_ \s -> s
    { showModal = true
    , formContent = ""
    , formTags = ""
    , formCategory = s.tab
    , submitting = false
    , submitError = Nothing
    }
  CloseModal -> H.modify_ _ { showModal = false }
  SetFormContent v -> H.modify_ _ { formContent = v }
  SetFormTags v -> H.modify_ _ { formTags = v }
  SetFormCategory v -> H.modify_ _ { formCategory = v }
  SubmitMemory -> do
    state <- H.get
    H.modify_ _ { submitting = true, submitError = Nothing }
    let
      tags = Array.filter (not <<< String.null) $ map String.trim $ String.split (Pattern ",") state.formTags
      category = case state.formCategory of
        Development -> "development"
        General -> "general"
      body = stringify
        $ "content" := state.formContent
        ~> "tags" := tags
        ~> "category" := category
        ~> jsonEmptyObject
    response <- H.liftAff $ fetch "/memories"
      { method: POST
      , headers: { "Content-Type": "application/json" }
      , body
      }
    if response.status == 201 then
      H.modify_ _ { showModal = false, submitting = false }
    else
      H.modify_ _ { submitting = false, submitError = Just "保存に失敗しました" }

handleQuery :: forall action slots o m a. Query a -> H.HalogenM State action slots o m (Maybe a)
handleQuery (Navigate route a) = do
  H.modify_ _ { route = Just route }
  pure (Just a)
