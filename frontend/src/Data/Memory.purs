module Data.Memory where

import Prelude

import Data.Argonaut.Core (jsonEmptyObject, stringify)
import Data.Argonaut.Decode.Class (decodeJson)
import Data.Argonaut.Encode.Combinators ((:=), (~>))
import Data.Array (catMaybes, intercalate)
import Data.Either (Either(..))
import Data.HTTP.Method (Method(..))
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)
import Fetch (fetch)
import Unsafe.Coerce (unsafeCoerce)

type Memory =
  { id :: String
  , content :: String
  , tags :: Array String
  , category :: String
  , created_at :: String
  , updated_at :: String
  }

type CreateMemory =
  { content :: String, tags :: Array String, category :: String }

type ListParams =
  { category :: Maybe String, page :: Maybe Int, limit :: Maybe Int }

listMemories :: ListParams -> Aff (Either String (Array Memory))
listMemories params = do
  let
    pairs = catMaybes
      [ map (\c -> "category=" <> c) params.category
      , map (\p -> "page=" <> show p) params.page
      , map (\l -> "limit=" <> show l) params.limit
      ]
    qs = case pairs of
      [] -> ""
      _ -> "?" <> intercalate "&" pairs
  response <- fetch ("/memories" <> qs) {}
  if response.status == 200 then do
    raw <- response.json
    case decodeJson (unsafeCoerce raw) of
      Right memories -> pure (Right memories)
      Left err -> pure (Left (show err))
  else
    pure (Left "メモリの取得に失敗しました")

createMemory :: CreateMemory -> Aff (Either String Unit)
createMemory mem = do
  let
    body = stringify
      $ "content" := mem.content
      ~> "tags" := mem.tags
      ~> "category" := mem.category
      ~> jsonEmptyObject
  response <- fetch "/memories"
    { method: POST
    , headers: { "Content-Type": "application/json" }
    , body
    }
  if response.status == 201 then
    pure (Right unit)
  else
    pure (Left "保存に失敗しました")
