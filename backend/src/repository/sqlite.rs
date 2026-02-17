use chrono::{DateTime, Utc};
use sqlx::{FromRow, SqlitePool};
use uuid::Uuid;

use crate::model::{Category, CreateMemory, Memory, UpdateMemory};

use super::{MemoryRepository, RepositoryError};

#[derive(FromRow)]
struct MemoryRow {
    id: String,
    content: String,
    tags: String,
    category: String,
    created_at: String,
    updated_at: String,
}

impl TryFrom<MemoryRow> for Memory {
    type Error = RepositoryError;

    fn try_from(row: MemoryRow) -> Result<Self, Self::Error> {
        let tags: Vec<String> =
            serde_json::from_str(&row.tags).map_err(|e| RepositoryError::Internal(e.into()))?;
        let category = Category::from_str(&row.category).ok_or_else(|| {
            RepositoryError::Internal(format!("unknown category: {}", row.category).into())
        })?;
        let created_at: DateTime<Utc> = row
            .created_at
            .parse()
            .map_err(|e: chrono::ParseError| RepositoryError::Internal(e.into()))?;
        let updated_at: DateTime<Utc> = row
            .updated_at
            .parse()
            .map_err(|e: chrono::ParseError| RepositoryError::Internal(e.into()))?;

        Ok(Memory {
            id: row.id,
            content: row.content,
            tags,
            category,
            created_at,
            updated_at,
        })
    }
}

pub struct SqliteMemoryRepository {
    pool: SqlitePool,
}

impl SqliteMemoryRepository {
    pub async fn new(url: &str) -> Result<Self, RepositoryError> {
        let pool = SqlitePool::connect(url)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?;

        sqlx::query(
            "CREATE TABLE IF NOT EXISTS memories (
                id TEXT PRIMARY KEY NOT NULL,
                content TEXT NOT NULL,
                tags TEXT NOT NULL DEFAULT '[]',
                category TEXT NOT NULL CHECK (category IN ('development', 'general')),
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )",
        )
        .execute(&pool)
        .await
        .map_err(|e| RepositoryError::Internal(e.into()))?;

        sqlx::query(
            "CREATE VIRTUAL TABLE IF NOT EXISTS vec_memories USING vec0(
                id TEXT PRIMARY KEY,
                embedding float[768]
            )",
        )
        .execute(&pool)
        .await
        .map_err(|e| RepositoryError::Internal(e.into()))?;

        Ok(Self { pool })
    }
}

impl MemoryRepository for SqliteMemoryRepository {
    async fn create(
        &self,
        input: CreateMemory,
        embedding: Vec<f32>,
    ) -> Result<Memory, RepositoryError> {
        let id = Uuid::new_v4().to_string();
        let now = Utc::now();
        let tags_json =
            serde_json::to_string(&input.tags).map_err(|e| RepositoryError::Internal(e.into()))?;
        let now_str = now.to_rfc3339();

        sqlx::query(
            "INSERT INTO memories (id, content, tags, category, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
        )
        .bind(&id)
        .bind(&input.content)
        .bind(&tags_json)
        .bind(input.category.as_str())
        .bind(&now_str)
        .bind(&now_str)
        .execute(&self.pool)
        .await
        .map_err(|e| RepositoryError::Internal(e.into()))?;

        let embedding_bytes: Vec<u8> = embedding.iter().flat_map(|f| f.to_le_bytes()).collect();
        sqlx::query("INSERT INTO vec_memories (id, embedding) VALUES (?, ?)")
            .bind(&id)
            .bind(&embedding_bytes)
            .execute(&self.pool)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?;

        Ok(Memory {
            id,
            content: input.content,
            tags: input.tags,
            category: input.category,
            created_at: now,
            updated_at: now,
        })
    }

    async fn get(&self, id: &str) -> Result<Memory, RepositoryError> {
        let row: MemoryRow = sqlx::query_as("SELECT * FROM memories WHERE id = ?")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?
            .ok_or(RepositoryError::NotFound)?;

        row.try_into()
    }

    async fn update(&self, id: &str, input: UpdateMemory) -> Result<Memory, RepositoryError> {
        let existing = self.get(id).await?;

        let content = input.content.unwrap_or(existing.content);
        let tags = input.tags.unwrap_or(existing.tags);
        let category = input.category.unwrap_or(existing.category);
        let now = Utc::now();

        let tags_json =
            serde_json::to_string(&tags).map_err(|e| RepositoryError::Internal(e.into()))?;
        let now_str = now.to_rfc3339();

        sqlx::query(
            "UPDATE memories SET content = ?, tags = ?, category = ?, updated_at = ? WHERE id = ?",
        )
        .bind(&content)
        .bind(&tags_json)
        .bind(category.as_str())
        .bind(&now_str)
        .bind(id)
        .execute(&self.pool)
        .await
        .map_err(|e| RepositoryError::Internal(e.into()))?;

        Ok(Memory {
            id: id.to_string(),
            content,
            tags,
            category,
            created_at: existing.created_at,
            updated_at: now,
        })
    }

    async fn delete(&self, id: &str) -> Result<(), RepositoryError> {
        let result = sqlx::query("DELETE FROM memories WHERE id = ?")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?;

        if result.rows_affected() == 0 {
            return Err(RepositoryError::NotFound);
        }

        Ok(())
    }

    async fn list(&self, limit: usize) -> Result<Vec<Memory>, RepositoryError> {
        let limit = limit as i64;
        let rows: Vec<MemoryRow> =
            sqlx::query_as("SELECT * FROM memories ORDER BY created_at DESC LIMIT ?")
                .bind(limit)
                .fetch_all(&self.pool)
                .await
                .map_err(|e| RepositoryError::Internal(e.into()))?;

        rows.into_iter().map(TryInto::try_into).collect()
    }

    async fn search(
        &self,
        query_embedding: Vec<f32>,
        limit: usize,
    ) -> Result<Vec<Memory>, RepositoryError> {
        let embedding_bytes: Vec<u8> =
            query_embedding.iter().flat_map(|f| f.to_le_bytes()).collect();
        let limit = limit as i64;

        let rows: Vec<MemoryRow> = sqlx::query_as(
            "SELECT m.id, m.content, m.tags, m.category, m.created_at, m.updated_at
             FROM memories m
             INNER JOIN vec_memories v ON m.id = v.id
             WHERE v.embedding MATCH ?
               AND k = ?
             ORDER BY distance",
        )
        .bind(&embedding_bytes)
        .bind(limit)
        .bind(limit)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| RepositoryError::Internal(e.into()))?;

        rows.into_iter().map(TryInto::try_into).collect()
    }
}
