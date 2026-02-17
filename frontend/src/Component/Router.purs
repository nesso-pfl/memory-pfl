module Component.Router where

import Prelude

import Capability.Memory (class MonadMemory, createMemory, deleteMemory, listMemories, listTags, updateMemory)
import Capability.Navigate (class Navigate, replaceRoute)
import Capability.User (class MonadUser, getProfile)
import Data.Array (filter, null) as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Memory (Memory)
import Data.Route (Route(..))
import Data.String.CodeUnits (contains) as String
import Data.String.Common (joinWith, split, trim, null, toLower) as String
import Data.String.Pattern (Pattern(..))
import Data.Tab (Tab(..), fromCategory, toCategory)
import Data.User (UserProfile, displayName)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event as HQE
import Web.DOM.Element as DOMElement
import Web.DOM.Node as Node
import Web.Event.Event (Event)
import Web.Event.Event as Event
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.Window (document)
import Web.UIEvent.MouseEvent.EventTypes (click) as EventTypes

type State =
  { route :: Maybe Route
  , tab :: Tab
  , profile :: Maybe UserProfile
  , memories :: Array Memory
  , allTags :: Array String
  , tagInput :: String
  , tagFocused :: Boolean
  , filterTag :: Maybe String
  , searchQuery :: String
  , searching :: Boolean
  , showModal :: Boolean
  , editingId :: Maybe String
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
  | DocumentClick Event
  | SelectTag String
  | ClearTag
  | SetSearchQuery String
  | SubmitSearch
  | StartEdit Memory
  | DeleteMemory String
  | OpenModal
  | CloseModal
  | SetFormContent String
  | SetFormTags String
  | SetFormCategory Tab
  | SubmitMemory

component :: forall i o m. MonadEffect m => MonadUser m => MonadMemory m => Navigate m => H.Component Query i o m
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
      , searchQuery: ""
      , searching: false
      , showModal: false
      , editingId: Nothing
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
    [ HP.classes [ H.ClassName "sticky top-0 z-10 bg-white/80 backdrop-blur-md shadow-sm px-5 py-3.5 flex items-center justify-between" ] ]
    [ HH.a
        [ HP.href "/"
        , HP.classes [ H.ClassName "text-lg font-bold tracking-tight text-gray-900 no-underline" ]
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
            , HP.classes [ H.ClassName "text-sm bg-gray-800 hover:bg-gray-700 text-white px-3.5 py-1.5 rounded-lg no-underline" ]
            ]
            [ HH.text "Login" ]
    ]

main :: forall slots m. State -> H.ComponentHTML Action slots m
main state =
  HH.main
    [ HP.classes [ H.ClassName "flex-1 flex flex-col" ] ]
    ( [ tabControl state
      , tagSearch state
      , searchBar state
      , resultList state
      ] <> if isJust state.profile then [ fab ] else []
    )

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
        , HP.placeholder "\x1F50D キーワード検索..."
        , HP.value state.searchQuery
        , HE.onValueInput SetSearchQuery
        , HP.classes [ H.ClassName "flex-1 border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-200 focus:border-blue-300" ]
        ]
    , HH.button
        [ HE.onClick \_ -> SubmitSearch
        , HP.disabled (state.searching || String.null state.searchQuery)
        , HP.classes [ H.ClassName "px-4 py-2.5 text-sm font-medium bg-gray-800 hover:bg-gray-700 text-white rounded-xl disabled:opacity-40 disabled:hover:bg-gray-800" ]
        ]
        [ HH.text if state.searching then "検索中..." else "検索" ]
    ]

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

resultList :: forall slots m. State -> H.ComponentHTML Action slots m
resultList state =
  HH.div
    [ HP.classes [ H.ClassName "flex-1 px-5 py-4 flex flex-col gap-3" ] ]
    ( filterBadge <> content )
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
    | state.memories == [] =
        [ HH.p
            [ HP.classes [ H.ClassName "text-sm text-gray-400 text-center mt-12" ] ]
            [ HH.text "検索結果がありません" ]
        ]
    | otherwise = map (memoryCard state.filterTag) state.memories

memoryCard :: forall slots m. Maybe String -> Memory -> H.ComponentHTML Action slots m
memoryCard activeTag mem =
  HH.div
    [ HP.classes [ H.ClassName "group relative bg-white rounded-xl shadow-sm hover:shadow-md p-5 flex flex-col gap-3" ] ]
    [ HH.div
        [ HP.classes [ H.ClassName "absolute top-3 right-3 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity" ] ]
        [ HH.button
            [ HE.onClick \_ -> StartEdit mem
            , HP.classes [ H.ClassName "p-1.5 rounded-lg text-gray-300 hover:text-gray-600 hover:bg-gray-100" ]
            ]
            [ HH.text "\x270E" ]
        , HH.button
            [ HE.onClick \_ -> DeleteMemory mem.id
            , HP.classes [ H.ClassName "p-1.5 rounded-lg text-gray-300 hover:text-red-500 hover:bg-red-50" ]
            ]
            [ HH.text "\x2715" ]
        ]
    , HH.p
        [ HP.classes [ H.ClassName "text-sm leading-relaxed text-gray-800 whitespace-pre-wrap" ] ]
        [ HH.text mem.content ]
    , HH.div
        [ HP.classes [ H.ClassName "flex gap-1.5 flex-wrap" ] ]
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
    | activeTag == Just t = "text-xs font-medium bg-gray-800 text-white px-2.5 py-1 rounded-full"
    | otherwise = "text-xs font-medium bg-gray-100 text-gray-500 px-2.5 py-1 rounded-full hover:bg-gray-200 hover:text-gray-700"

fab :: forall slots m. H.ComponentHTML Action slots m
fab =
  HH.button
    [ HE.onClick \_ -> OpenModal
    , HP.classes [ H.ClassName "fixed bottom-6 right-6 w-14 h-14 bg-gray-800 hover:bg-gray-700 text-white rounded-full shadow-lg hover:shadow-xl hover:scale-105 text-2xl flex items-center justify-center" ]
    ]
    [ HH.text "＋" ]

modal :: forall slots m. State -> H.ComponentHTML Action slots m
modal state =
  HH.div
    [ HP.classes [ H.ClassName "fixed inset-0 z-50 flex items-end sm:items-center justify-center" ] ]
    [ HH.div
        [ HE.onClick \_ -> CloseModal
        , HP.classes [ H.ClassName "absolute inset-0 bg-black/40 backdrop-blur-sm" ]
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

footer :: forall slots m. H.ComponentHTML Action slots m
footer =
  HH.footer
    [ HP.classes [ H.ClassName "py-4 text-center text-xs text-gray-300" ] ]
    [ HH.text "developed by "
    , HH.a
        [ HP.href "https://github.com/nesso-pfl"
        , HP.target "_blank"
        , HP.classes [ H.ClassName "text-gray-400 hover:text-gray-600 underline" ]
        ]
        [ HH.text "nesso-pfl" ]
    ]

handleAction :: forall slots o m. MonadEffect m => MonadUser m => MonadMemory m => Navigate m => Action -> H.HalogenM State Action slots o m Unit
handleAction = case _ of
  Initialize -> do
    profile <- getProfile
    H.modify_ _ { profile = profile }
    doc <- liftEffect $ window >>= document
    void $ H.subscribe $ HQE.eventListener EventTypes.click (HTMLDocument.toEventTarget doc) (Just <<< DocumentClick)
  FetchMemories -> do
    state <- H.get
    H.modify_ _ { searching = not (String.null state.searchQuery) }
    result <- listMemories { q: state.searchQuery, category: Just (toCategory state.tab), tag: state.filterTag, page: Nothing, limit: Nothing }
    H.modify_ _ { searching = false }
    case result of
      Right memories -> H.modify_ _ { memories = memories }
      Left _ -> pure unit
  SetTab tab -> do
    state <- H.get
    replaceRoute (Home { tab: Just (toCategory tab), tag: state.filterTag })
  SetTagInput v ->
    H.modify_ _ { tagInput = v }
  TagFocus ->
    H.modify_ _ { tagFocused = true }
  DocumentClick ev -> do
    mRef <- H.getRef (H.RefLabel "tagSearch")
    case mRef, Event.target ev >>= DOMElement.fromEventTarget of
      Just el, Just targetEl -> do
        inside <- liftEffect $ Node.contains (DOMElement.toNode el) (DOMElement.toNode targetEl)
        unless inside $ H.modify_ _ { tagFocused = false }
      _, _ -> H.modify_ _ { tagFocused = false }
  SelectTag t -> do
    H.modify_ _ { tagInput = "", tagFocused = false }
    tab <- H.gets _.tab
    replaceRoute (Home { tab: Just (toCategory tab), tag: Just t })
  ClearTag -> do
    tab <- H.gets _.tab
    replaceRoute (Home { tab: Just (toCategory tab), tag: Nothing })
  SetSearchQuery v ->
    H.modify_ _ { searchQuery = v }
  SubmitSearch ->
    handleAction FetchMemories
  StartEdit mem -> H.modify_ \s -> s
    { showModal = true
    , editingId = Just mem.id
    , formContent = mem.content
    , formTags = String.joinWith ", " mem.tags
    , formCategory = fromMaybe s.tab (fromCategory mem.category)
    , submitting = false
    , submitError = Nothing
    , submitSuccess = false
    }
  DeleteMemory id -> do
    result <- deleteMemory id
    case result of
      Right _ -> do
        handleAction FetchMemories
        tab <- H.gets _.tab
        tagsResult <- listTags (Just (toCategory tab))
        case tagsResult of
          Right tags -> H.modify_ _ { allTags = tags }
          Left _ -> pure unit
      Left _ -> pure unit
  OpenModal -> H.modify_ \s -> s
    { showModal = true
    , editingId = Nothing
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
      body = { content: state.formContent, tags, category }
    result <- case state.editingId of
      Just id -> updateMemory id body
      Nothing -> createMemory body
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

handleQuery :: forall slots o m a. MonadEffect m => MonadUser m => MonadMemory m => Navigate m => Query a -> H.HalogenM State Action slots o m (Maybe a)
handleQuery (Navigate route a) = do
  let { tab, filterTag } = case route of
        Home p ->
          { tab: fromMaybe Development (p.tab >>= fromCategory)
          , filterTag: p.tag
          }
  H.modify_ _ { route = Just route, tab = tab, filterTag = filterTag, tagInput = "", searchQuery = "" }
  tagsResult <- listTags (Just (toCategory tab))
  case tagsResult of
    Right tags -> H.modify_ _ { allTags = tags }
    Left _ -> pure unit
  handleAction FetchMemories
  pure (Just a)
