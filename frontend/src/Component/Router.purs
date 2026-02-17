module Component.Router where

import Prelude

import Capability.Memory (class MonadMemory, createMemory, listMemories, listTags)
import Capability.Navigate (class Navigate, replaceRoute)
import Capability.User (class MonadUser, getProfile)
import Data.Array (filter, null) as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Memory (Memory)
import Data.Route (Route(..))
import Data.String.CodeUnits (contains) as String
import Data.String.Common (split, trim, null, toLower) as String
import Data.String.Pattern (Pattern(..))
import Data.Tab (Tab(..), fromCategory, toCategory)
import Data.User (UserProfile, displayName)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

type State =
  { route :: Maybe Route
  , tab :: Tab
  , profile :: Maybe UserProfile
  , memories :: Array Memory
  , allTags :: Array String
  , tagInput :: String
  , tagFocused :: Boolean
  , filterTag :: Maybe String
  , showModal :: Boolean
  , formContent :: String
  , formTags :: String
  , formCategory :: Tab
  , submitting :: Boolean
  , submitError :: Maybe String
  , submitSuccess :: Boolean
  }

data Query a = Navigate Route a

data Action
  = Initialize
  | FetchMemories
  | SetTab Tab
  | SetTagInput String
  | TagFocus
  | TagBlur
  | SelectTag String
  | ClearTag
  | OpenModal
  | CloseModal
  | SetFormContent String
  | SetFormTags String
  | SetFormCategory Tab
  | SubmitMemory

component :: forall i o m. MonadUser m => MonadMemory m => Navigate m => H.Component Query i o m
component = H.mkComponent
  { initialState: \_ ->
      { route: Nothing
      , tab: Development
      , profile: Nothing
      , memories: []
      , allTags: []
      , tagInput: ""
      , tagFocused: false
      , filterTag: Nothing
      , showModal: false
      , formContent: ""
      , formTags: ""
      , formCategory: Development
      , submitting: false
      , submitError: Nothing
      , submitSuccess: false
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
  Just (Home _) ->
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
    ( [ tagSearch state
      , searchBar
      , tabControl state
      , resultList state
      ] <> if isJust state.profile then [ fab ] else []
    )

tagSearch :: forall slots m. State -> H.ComponentHTML Action slots m
tagSearch state =
  HH.div
    [ HP.classes [ H.ClassName "px-4 pt-4 relative" ] ]
    ( [ HH.input
          [ HP.type_ HP.InputText
          , HP.placeholder "\x1F50D タグで検索..."
          , HP.value state.tagInput
          , HE.onValueInput SetTagInput
          , HE.onFocusIn \_ -> TagFocus
          , HE.onFocusOut \_ -> TagBlur
          , HP.classes [ H.ClassName "w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" ]
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
            [ HP.classes [ H.ClassName "absolute left-4 right-4 mt-1 bg-white border rounded-lg shadow-lg z-20 max-h-48 overflow-y-auto" ] ]
            (map suggestionItem matched)
        ]
  suggestionItem t =
    HH.button
      [ HE.onMouseDown \_ -> SelectTag t
      , HP.classes [ H.ClassName "w-full text-left px-3 py-2 text-sm hover:bg-gray-100 cursor-pointer" ]
      ]
      [ HH.text t ]

searchBar :: forall slots m. H.ComponentHTML Action slots m
searchBar =
  HH.div
    [ HP.classes [ H.ClassName "px-4 pt-2" ] ]
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

resultList :: forall slots m. State -> H.ComponentHTML Action slots m
resultList state =
  HH.div
    [ HP.classes [ H.ClassName "flex-1 px-4 py-4 flex flex-col gap-3" ] ]
    ( filterBadge <> content )
  where
  filterBadge = case state.filterTag of
    Just t ->
      [ HH.div
          [ HP.classes [ H.ClassName "flex items-center gap-2" ] ]
          [ HH.span
              [ HP.classes [ H.ClassName "text-xs text-gray-500" ] ]
              [ HH.text "タグ:" ]
          , HH.button
              [ HE.onClick \_ -> ClearTag
              , HP.classes [ H.ClassName "text-xs bg-gray-900 text-white px-2 py-0.5 rounded cursor-pointer inline-flex items-center gap-1" ]
              ]
              [ HH.text t, HH.text " \x2715" ]
          ]
      ]
    Nothing -> []
  content
    | state.memories == [] =
        [ HH.p
            [ HP.classes [ H.ClassName "text-sm text-gray-400 text-center mt-8" ] ]
            [ HH.text "検索結果がありません" ]
        ]
    | otherwise = map (memoryCard state.filterTag) state.memories

memoryCard :: forall slots m. Maybe String -> Memory -> H.ComponentHTML Action slots m
memoryCard activeTag mem =
  HH.div
    [ HP.classes [ H.ClassName "bg-white rounded-lg border p-4 flex flex-col gap-2" ] ]
    [ HH.p
        [ HP.classes [ H.ClassName "text-sm text-gray-900 whitespace-pre-wrap" ] ]
        [ HH.text mem.content ]
    , HH.div
        [ HP.classes [ H.ClassName "flex gap-2 flex-wrap" ] ]
        (map (tagBadge activeTag) mem.tags)
    ]

tagBadge :: forall slots m. Maybe String -> String -> H.ComponentHTML Action slots m
tagBadge activeTag t =
  HH.button
    [ HE.onClick \_ -> SelectTag t
    , HP.classes [ H.ClassName classes ]
    ]
    [ HH.text t ]
  where
  classes
    | activeTag == Just t = "text-xs bg-gray-900 text-white px-2 py-0.5 rounded cursor-pointer"
    | otherwise = "text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded cursor-pointer hover:bg-gray-200"

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
        if state.submitSuccess then
          [ HH.p
              [ HP.classes [ H.ClassName "text-sm text-green-600 text-center py-4" ] ]
              [ HH.text "保存に成功しました" ]
          , HH.div
              [ HP.classes [ H.ClassName "flex justify-end" ] ]
              [ HH.button
                  [ HE.onClick \_ -> CloseModal
                  , HP.classes [ H.ClassName "px-4 py-2 text-sm bg-gray-900 text-white rounded-lg" ]
                  ]
                  [ HH.text "閉じる" ]
              ]
          ]
        else
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

handleAction :: forall slots o m. MonadUser m => MonadMemory m => Navigate m => Action -> H.HalogenM State Action slots o m Unit
handleAction = case _ of
  Initialize -> do
    profile <- getProfile
    H.modify_ _ { profile = profile }
  FetchMemories -> do
    state <- H.get
    result <- listMemories { category: Just (toCategory state.tab), tag: state.filterTag, page: Nothing, limit: Nothing }
    case result of
      Right memories -> H.modify_ _ { memories = memories }
      Left _ -> pure unit
  SetTab tab ->
    replaceRoute (Home (Just (toCategory tab)))
  SetTagInput v ->
    H.modify_ _ { tagInput = v }
  TagFocus ->
    H.modify_ _ { tagFocused = true }
  TagBlur ->
    H.modify_ _ { tagFocused = false }
  SelectTag t -> do
    H.modify_ _ { filterTag = Just t, tagInput = "", tagFocused = false }
    handleAction FetchMemories
  ClearTag -> do
    H.modify_ _ { filterTag = Nothing }
    handleAction FetchMemories
  OpenModal -> H.modify_ \s -> s
    { showModal = true
    , formContent = ""
    , formTags = ""
    , formCategory = s.tab
    , submitting = false
    , submitError = Nothing
    , submitSuccess = false
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
      category = toCategory state.formCategory
    result <- createMemory { content: state.formContent, tags, category }
    case result of
      Right _ -> do
        H.modify_ _ { submitting = false, submitSuccess = true }
        tab <- H.gets _.tab
        tagsResult <- listTags (Just (toCategory tab))
        case tagsResult of
          Right tags -> H.modify_ _ { allTags = tags }
          Left _ -> pure unit
        handleAction FetchMemories
      Left err -> H.modify_ _ { submitting = false, submitError = Just err }

handleQuery :: forall slots o m a. MonadUser m => MonadMemory m => Navigate m => Query a -> H.HalogenM State Action slots o m (Maybe a)
handleQuery (Navigate route a) = do
  let tab = case route of
        Home maybeTab -> fromMaybe Development (maybeTab >>= fromCategory)
  H.modify_ _ { route = Just route, tab = tab, filterTag = Nothing, tagInput = "" }
  tagsResult <- listTags (Just (toCategory tab))
  case tagsResult of
    Right tags -> H.modify_ _ { allTags = tags }
    Left _ -> pure unit
  handleAction FetchMemories
  pure (Just a)
