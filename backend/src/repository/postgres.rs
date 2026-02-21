use chrono::{DateTime, Utc};
use pgvector::Vector;
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

use crate::model::{Category, CreateMemory, Memory, UpdateMemory};

use super::{MemoryRepository, RepositoryError};

#[derive(FromRow)]
struct MemoryRow {
    id: Uuid,
    content: String,
    tags: Vec<String>,
    category: String,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}

impl TryFrom<MemoryRow> for Memory {
    type Error = RepositoryError;

    fn try_from(row: MemoryRow) -> Result<Self, Self::Error> {
        let category = Category::from_str(&row.category).ok_or_else(|| {
            RepositoryError::Internal(format!("unknown category: {}", row.category).into())
        })?;

        Ok(Memory {
            id: row.id.to_string(),
            content: row.content,
            tags: row.tags,
            category,
            created_at: row.created_at,
            updated_at: row.updated_at,
        })
    }
}

pub struct PgMemoryRepository {
    pool: PgPool,
}

impl PgMemoryRepository {
    const SEARCH_DISTANCE_THRESHOLD: f64 = 0.5;

    pub async fn new(url: &str) -> Result<Self, RepositoryError> {
        let pool = PgPool::connect(url)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?;

        sqlx::query("CREATE EXTENSION IF NOT EXISTS vector")
            .execute(&pool)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?;

        sqlx::query(
            "CREATE TABLE IF NOT EXISTS memories (
                id UUID PRIMARY KEY,
                content TEXT NOT NULL,
                tags TEXT[] NOT NULL DEFAULT '{}',
                category TEXT NOT NULL CHECK (category IN ('development', 'general')),
                created_at TIMESTAMPTZ NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL
            )",
        )
        .execute(&pool)
        .await
        .map_err(|e| RepositoryError::Internal(e.into()))?;

        sqlx::query(
            "CREATE TABLE IF NOT EXISTS embeddings (
                id UUID PRIMARY KEY REFERENCES memories(id) ON DELETE CASCADE,
                embedding vector(768) NOT NULL
            )",
        )
        .execute(&pool)
        .await
        .map_err(|e| RepositoryError::Internal(e.into()))?;

        Ok(Self { pool })
    }
}

impl MemoryRepository for PgMemoryRepository {
    async fn create(
        &self,
        input: CreateMemory,
        embedding: Vec<f32>,
    ) -> Result<Memory, RepositoryError> {
        let id = Uuid::new_v4();
        let now = Utc::now();

        sqlx::query(
            "INSERT INTO memories (id, content, tags, category, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6)",
        )
        .bind(id)
        .bind(&input.content)
        .bind(&input.tags)
        .bind(input.category.as_str())
        .bind(now)
        .bind(now)
        .execute(&self.pool)
        .await
        .map_err(|e| RepositoryError::Internal(e.into()))?;

        let vector = Vector::from(embedding);
        sqlx::query("INSERT INTO embeddings (id, embedding) VALUES ($1, $2)")
            .bind(id)
            .bind(vector)
            .execute(&self.pool)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?;

        Ok(Memory {
            id: id.to_string(),
            content: input.content,
            tags: input.tags,
            category: input.category,
            created_at: now,
            updated_at: now,
        })
    }

    async fn get(&self, id: &str) -> Result<Memory, RepositoryError> {
        let uuid = Uuid::parse_str(id).map_err(|e| RepositoryError::Internal(e.into()))?;
        let row: MemoryRow = sqlx::query_as("SELECT * FROM memories WHERE id = $1")
            .bind(uuid)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?
            .ok_or(RepositoryError::NotFound)?;

        row.try_into()
    }

    async fn update(&self, id: &str, input: UpdateMemory) -> Result<Memory, RepositoryError> {
        let existing = self.get(id).await?;
        let uuid = Uuid::parse_str(id).map_err(|e| RepositoryError::Internal(e.into()))?;

        let content = input.content.unwrap_or(existing.content);
        let tags = input.tags.unwrap_or(existing.tags);
        let category = input.category.unwrap_or(existing.category);
        let now = Utc::now();

        sqlx::query(
            "UPDATE memories SET content = $1, tags = $2, category = $3, updated_at = $4 WHERE id = $5",
        )
        .bind(&content)
        .bind(&tags)
        .bind(category.as_str())
        .bind(now)
        .bind(uuid)
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
        let uuid = Uuid::parse_str(id).map_err(|e| RepositoryError::Internal(e.into()))?;
        let result = sqlx::query("DELETE FROM memories WHERE id = $1")
            .bind(uuid)
            .execute(&self.pool)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?;

        if result.rows_affected() == 0 {
            return Err(RepositoryError::NotFound);
        }

        Ok(())
    }

    async fn list(
        &self,
        category: Option<Category>,
        tags: Vec<String>,
        limit: usize,
        offset: usize,
    ) -> Result<(Vec<Memory>, usize), RepositoryError> {
        let limit_i64 = limit as i64;
        let offset = offset as i64;

        let mut where_clause = String::new();
        let mut conditions = Vec::new();
        let mut param_idx = 1usize;

        if category.is_some() {
            conditions.push(format!("category = ${param_idx}"));
            param_idx += 1;
        }
        if !tags.is_empty() {
            conditions.push(format!("tags @> ${param_idx}"));
            param_idx += 1;
        }
        if !conditions.is_empty() {
            where_clause = format!(" WHERE {}", conditions.join(" AND "));
        }

        let count_sql = format!("SELECT COUNT(*) FROM memories{where_clause}");
        let mut count_query = sqlx::query_scalar::<_, i64>(&count_sql);
        if let Some(ref cat) = category {
            count_query = count_query.bind(cat.as_str());
        }
        if !tags.is_empty() {
            count_query = count_query.bind(&tags);
        }
        let total: usize = count_query
            .fetch_one(&self.pool)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))? as usize;

        let select_sql = format!(
            "SELECT * FROM memories{where_clause} ORDER BY created_at DESC LIMIT ${param_idx} OFFSET ${}",
            param_idx + 1
        );
        let mut select_query = sqlx::query_as::<_, MemoryRow>(&select_sql);
        if let Some(ref cat) = category {
            select_query = select_query.bind(cat.as_str());
        }
        if !tags.is_empty() {
            select_query = select_query.bind(&tags);
        }
        select_query = select_query.bind(limit_i64).bind(offset);

        let rows: Vec<MemoryRow> = select_query
            .fetch_all(&self.pool)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?;

        let memories: Vec<Memory> = rows.into_iter().map(TryInto::try_into).collect::<Result<_, _>>()?;
        Ok((memories, total))
    }

    async fn list_tags(&self, category: Option<Category>) -> Result<Vec<String>, RepositoryError> {
        let rows = if let Some(ref cat) = category {
            sqlx::query_scalar::<_, String>(
                "SELECT DISTINCT t FROM (SELECT UNNEST(tags) AS t FROM memories WHERE category = $1) sub ORDER BY t",
            )
            .bind(cat.as_str())
            .fetch_all(&self.pool)
            .await
        } else {
            sqlx::query_scalar::<_, String>(
                "SELECT DISTINCT t FROM (SELECT UNNEST(tags) AS t FROM memories) sub ORDER BY t",
            )
            .fetch_all(&self.pool)
            .await
        };

        rows.map_err(|e| RepositoryError::Internal(e.into()))
    }

    async fn search(
        &self,
        query_embedding: Vec<f32>,
        limit: usize,
        category: Option<Category>,
    ) -> Result<Vec<Memory>, RepositoryError> {
        let vector = Vector::from(query_embedding);
        let limit = limit as i64;

        let sql = if category.is_some() {
            "SELECT m.id, m.content, m.tags, m.category, m.created_at, m.updated_at
             FROM memories m
             INNER JOIN embeddings e ON m.id = e.id
             WHERE (e.embedding <=> $1) < $2 AND m.category = $3
             ORDER BY e.embedding <=> $1
             LIMIT $4"
        } else {
            "SELECT m.id, m.content, m.tags, m.category, m.created_at, m.updated_at
             FROM memories m
             INNER JOIN embeddings e ON m.id = e.id
             WHERE (e.embedding <=> $1) < $2
             ORDER BY e.embedding <=> $1
             LIMIT $3"
        };

        let mut query = sqlx::query_as::<_, MemoryRow>(sql)
            .bind(&vector)
            .bind(Self::SEARCH_DISTANCE_THRESHOLD);
        if let Some(ref cat) = category {
            query = query.bind(cat.as_str());
        }
        query = query.bind(limit);

        let rows: Vec<MemoryRow> = query
            .fetch_all(&self.pool)
            .await
            .map_err(|e| RepositoryError::Internal(e.into()))?;

        rows.into_iter().map(TryInto::try_into).collect()
    }
}
