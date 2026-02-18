module Component.Router (module Component.Router.Types, component) where

import Prelude

import Capability.Memory (class MonadMemory, createMemory, deleteMemory, listMemories, listTags, updateMemory)
import Capability.Navigate (class Navigate, replaceRoute)
import Capability.User (class MonadUser, getProfile, logout)
import Component.Footer (footer)
import Component.Header (header)
import Component.Router.Types (Action(..), Query(..), State)
import Data.Array (filter) as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Route (Route(..))
import Data.String.Common (split, trim, null, joinWith) as String
import Data.String.Pattern (Pattern(..))
import Data.Tab (Tab(..), fromCategory, toCategory)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.Query.Event as HQE
import Page.TopPage (topPage)
import Page.TopPage.Modal (modal)
import Web.DOM.Element as DOMElement
import Web.DOM.Node as Node
import Web.Event.Event (Event)
import Web.Event.Event as Event
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.Window (document)
import Web.UIEvent.MouseEvent.EventTypes (click) as EventTypes

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
      , confirmingDelete: Nothing
      , showModal: false
      , editingId: Nothing
      , formContent: ""
      , formTags: ""
      , formCategory: Development
      , submitting: false
      , submitError: Nothing
      , submitSuccess: false
      , showUserMenu: false
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
      [ HP.classes [ H.ClassName "min-h-screen flex flex-col" ] ]
      ( [ header state
        , topPage state
        , footer
        ] <> if state.showModal then [ modal state ] else []
      )
  Nothing ->
    HH.div_ [ HH.text "Loading..." ]

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
    let mTarget = Event.target ev >>= DOMElement.fromEventTarget
    mTagRef <- H.getRef (H.RefLabel "tagSearch")
    case mTagRef, mTarget of
      Just el, Just targetEl -> do
        inside <- liftEffect $ Node.contains (DOMElement.toNode el) (DOMElement.toNode targetEl)
        unless inside $ H.modify_ _ { tagFocused = false }
      _, _ -> H.modify_ _ { tagFocused = false }
    mMenuRef <- H.getRef (H.RefLabel "userMenu")
    case mMenuRef, mTarget of
      Just el, Just targetEl -> do
        inside <- liftEffect $ Node.contains (DOMElement.toNode el) (DOMElement.toNode targetEl)
        unless inside $ H.modify_ _ { showUserMenu = false }
      _, _ -> H.modify_ _ { showUserMenu = false }
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
  DeleteMemory id ->
    H.modify_ _ { confirmingDelete = Just id }
  ConfirmDelete -> do
    state <- H.get
    case state.confirmingDelete of
      Just id -> do
        H.modify_ _ { confirmingDelete = Nothing }
        result <- deleteMemory id
        case result of
          Right _ -> do
            handleAction FetchMemories
            tagsResult <- listTags (Just (toCategory state.tab))
            case tagsResult of
              Right tags -> H.modify_ _ { allTags = tags }
              Left _ -> pure unit
          Left _ -> pure unit
      Nothing -> pure unit
  CancelDelete ->
    H.modify_ _ { confirmingDelete = Nothing }
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
  ToggleUserMenu ->
    H.modify_ \s -> s { showUserMenu = not s.showUserMenu }
  Logout ->
    logout

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
