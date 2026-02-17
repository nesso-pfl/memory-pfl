# セマンティック検索

## 仕組み

通常のキーワード検索は文字列の一致で検索するが、セマンティック検索は **意味の近さ** で検索する。

```
「Rust のエラーハンドリング」で検索
  → 「Result 型と ? 演算子の使い方」がヒット（単語は一致しないが意味が近い）
```

これを実現するために **Embedding（埋め込みベクトル）** を使う。

## Embedding とは

テキストを **固定長の数値ベクトル**（float の配列）に変換したもの。意味が近いテキスト同士はベクトル空間上で近い位置になる。

```
"Rust のエラーハンドリング" → [0.12, -0.34, 0.56, ...] (768次元)
"Result 型の使い方"       → [0.11, -0.32, 0.55, ...] (近いベクトル)
"今日の晩ご飯"            → [0.87, 0.21, -0.45, ...] (遠いベクトル)
```

本プロジェクトでは Google の **Gemini Embedding API** (`gemini-embedding-001`) を使い、768 次元のベクトルを生成している。

### task_type

Gemini Embedding API では用途に応じた `task_type` を指定する:

- `RETRIEVAL_DOCUMENT`: メモリ保存時（検索される側）
- `RETRIEVAL_QUERY`: 検索時（検索する側）

同じテキストでも task_type によって生成されるベクトルが異なる。検索精度を上げるために、保存と検索で使い分ける。

## コサイン距離（Cosine Distance）

2 つのベクトルの「向き」がどれだけ違うかを測る指標。ベクトルの長さ（大きさ）は無視し、方向だけを比較する。

```
cosine_distance = 1 - cosine_similarity

cosine_similarity = (A · B) / (|A| × |B|)
```

| 値 | 意味 |
|------|------|
| 0 | 完全に同じ方向（同じ意味） |
| 1 | 直交（無関係） |
| 2 | 正反対 |

### なぜ L2（ユークリッド距離）ではなくコサイン距離か

- L2 距離はベクトルの **長さの違い** にも影響を受ける
- Embedding モデルの出力は正規化されている（長さ ≈ 1）ため L2 でも動くが、コサイン距離の方が意味の類似度を直接的に表す
- 長さが正確に 1 でない場合も、コサイン距離なら長さの影響を受けない

## sqlite-vec

SQLite でベクトル検索を行うための拡張。`vec0` 仮想テーブルで KNN（k 近傍）検索ができる。

### テーブル定義

```sql
CREATE VIRTUAL TABLE vec_memories USING vec0(
    id TEXT PRIMARY KEY,
    embedding float[768] distance_metric=cosine
);
```

`distance_metric=cosine` を指定しないとデフォルトの L2 距離になる。

### KNN 検索

```sql
-- クエリベクトルに近い上位 k 件を取得
SELECT id, distance
FROM vec_memories
WHERE embedding MATCH ?  -- クエリベクトル（バイナリ）
  AND k = ?              -- 取得件数
ORDER BY distance;
```

`MATCH` + `k` で KNN 検索を実行する。結果には `distance` カラムが自動的に付与される。

### 距離の閾値

KNN 検索は **常に k 件返す**。データが 3 件しかなくて k=20 なら、全く関係ない 3 件もそのまま返る。

これを防ぐため、CTE で KNN 結果を取得した後に距離でフィルタしている:

```sql
WITH ranked AS (
  SELECT v.id, v.distance
  FROM vec_memories v
  WHERE v.embedding MATCH ?
    AND k = ?
)
SELECT m.*
FROM memories m
INNER JOIN ranked r ON m.id = r.id
WHERE r.distance < 0.5   -- 閾値: コサイン距離 0.5 未満のみ
ORDER BY r.distance;
```

閾値 0.5 は「ある程度関連があるもの」を返す設定。必要に応じて調整する:
- **< 0.3**: 高い関連性のみ
- **< 0.5**: ある程度の関連性（現在の設定）
- **< 0.7**: 緩めのフィルタ

## データフロー

### メモリ保存時

```
ユーザー入力
  → POST /memories { content, tags, category }
  → Gemini API (task_type=RETRIEVAL_DOCUMENT) → 768次元ベクトル
  → memories テーブルに INSERT
  → vec_memories テーブルにベクトルを INSERT
```

### セマンティック検索時

```
検索クエリ "Rust エラー"
  → GET /memories?q=Rust+エラー
  → Gemini API (task_type=RETRIEVAL_QUERY) → 768次元ベクトル
  → vec_memories で KNN 検索 (上位20件)
  → コサイン距離 < 0.5 でフィルタ
  → memories テーブルと JOIN して結果返却
```

### 通常の一覧取得時

```
GET /memories?category=development&tag=rust
  → Gemini API は使わない
  → memories テーブルから直接 SELECT (category, tag でフィルタ)
```
