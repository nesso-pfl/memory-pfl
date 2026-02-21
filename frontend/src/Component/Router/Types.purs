module Component.Router.Types where

import Data.Memory (Memory)
import Data.Maybe (Maybe)
import Data.Route (Route)
import Data.Tab (Tab)
import Data.User (UserProfile)
import Foreign.Object (Object)
import Web.Event.Event (Event)

type State =
  { route :: Maybe Route
  , tab :: Tab
  , profile :: Maybe UserProfile
  , memories :: Array Memory
  , allTags :: Array String
  , memoriesCache :: Object (Array Memory)
  , tagsCache :: Object (Array String)
  , tagInput :: String
  , tagFocused :: Boolean
  , filterTags :: Array String
  , searchQuery :: String
  , loading :: Boolean
  , searching :: Boolean
  , confirmingDelete :: Maybe String
  , showModal :: Boolean
  , editingId :: Maybe String
  , formContent :: String
  , formTags :: String
  , formCategory :: Tab
  , submitting :: Boolean
  , submitError :: Maybe String
  , submitSuccess :: Boolean
  , showUserMenu :: Boolean
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
  | RemoveTag String
  | ClearTag
  | SetSearchQuery String
  | SubmitSearch
  | StartEdit Memory
  | DeleteMemory String
  | ConfirmDelete
  | CancelDelete
  | OpenModal
  | CloseModal
  | SetFormContent String
  | SetFormTags String
  | SetFormCategory Tab
  | SubmitMemory
  | ToggleUserMenu
  | Logout
