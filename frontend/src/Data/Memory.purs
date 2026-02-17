module Data.Memory where

import Prelude

import Data.Argonaut.Core (jsonEmptyObject, stringify)
import Data.Argonaut.Encode.Combinators ((:=), (~>))
import Data.Either (Either(..))
import Data.HTTP.Method (Method(..))
import Effect.Aff (Aff)
import Fetch (fetch)

type CreateMemory =
  { content :: String, tags :: Array String, category :: String }

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
