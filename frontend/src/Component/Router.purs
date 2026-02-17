module Component.Router where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Route (Route(..))
import Halogen as H
import Halogen.HTML as HH

type State = { route :: Maybe Route }

data Query a = Navigate Route a

data Action = Initialize

component :: forall i o m. H.Component Query i o m
component = H.mkComponent
  { initialState: \_ -> { route: Nothing }
  , render
  , eval: H.mkEval $ H.defaultEval
      { handleQuery = handleQuery
      , handleAction = handleAction
      , initialize = Just Initialize
      }
  }

render :: forall action slots m. State -> H.ComponentHTML action slots m
render { route } = case route of
  Just Home -> HH.h1_ [ HH.text "Home" ]
  Nothing -> HH.div_ [ HH.text "Loading..." ]

handleAction :: forall slots o m. Action -> H.HalogenM State Action slots o m Unit
handleAction Initialize = pure unit

handleQuery :: forall action slots o m a. Query a -> H.HalogenM State action slots o m (Maybe a)
handleQuery (Navigate route a) = do
  H.modify_ _ { route = Just route }
  pure (Just a)
