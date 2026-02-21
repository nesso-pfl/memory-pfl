module Data.Memory where

import Prelude

import Data.Argonaut.Core (jsonEmptyObject, stringify)
import Data.Argonaut.Decode.Class (decodeJson)
import Data.Argonaut.Encode.Combinators ((:=), (~>))
import Data.Array (catMaybes, intercalate)
import Data.Either (Either(..))
import Data.String.Common (null) as String
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
  { q :: String, category :: Maybe String, tags :: Maybe String, page :: Maybe Int, limit :: Maybe Int }

listMemories :: ListParams -> Aff (Either String (Array Memory))
listMemories params = do
  let
    qPair = if String.null params.q then Nothing else Just ("q=" <> params.q)
    pairs = catMaybes
      [ qPair
      , map (\c -> "category=" <> c) params.category
      , map (\t -> "tags=" <> t) params.tags
      , map (\p -> "page=" <> show p) params.page
      , map (\l -> "limit=" <> show l) params.limit
      ]
    qs = case pairs of
      [] -> ""
      _ -> "?" <> intercalate "&" pairs
  response <- fetch ("/memories" <> qs) {}
  if response.status == 200 then do
    raw <- response.json
    let decoded = decodeJson (unsafeCoerce raw) :: Either _ { memories :: Array Memory }
    case decoded of
      Right resp -> pure (Right resp.memories)
      Left err -> pure (Left (show err))
  else
    pure (Left "メモリの取得に失敗しました")

listTags :: Maybe String -> Aff (Either String (Array String))
listTags category = do
  let
    qs = case category of
      Just c -> "?category=" <> c
      Nothing -> ""
  response <- fetch ("/memories/tags" <> qs) {}
  if response.status == 200 then do
    raw <- response.json
    case decodeJson (unsafeCoerce raw) of
      Right tags -> pure (Right tags)
      Left err -> pure (Left (show err))
  else
    pure (Left "タグの取得に失敗しました")

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

updateMemory :: String -> CreateMemory -> Aff (Either String Unit)
updateMemory id mem = do
  let
    body = stringify
      $ "content" := mem.content
          ~> "tags" := mem.tags
          ~> "category" := mem.category
          ~> jsonEmptyObject
  response <- fetch ("/memories/" <> id)
    { method: PUT
    , headers: { "Content-Type": "application/json" }
    , body
    }
  if response.status == 200 then
    pure (Right unit)
  else
    pure (Left "更新に失敗しました")

deleteMemory :: String -> Aff (Either String Unit)
deleteMemory id = do
  response <- fetch ("/memories/" <> id) { method: DELETE }
  if response.status == 204 then
    pure (Right unit)
  else
    pure (Left "削除に失敗しました")
