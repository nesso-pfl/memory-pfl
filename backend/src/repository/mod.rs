pub mod postgres;

use std::future::Future;

use crate::model::{Category, CreateMemory, Memory, UpdateMemory};

#[derive(Debug, thiserror::Error)]
pub enum RepositoryError {
    #[error("not found")]
    NotFound,
    #[error("{0}")]
    Internal(Box<dyn std::error::Error + Send + Sync>),
}

pub trait MemoryRepository: Send + Sync {
    fn create(
        &self,
        input: CreateMemory,
        embedding: Vec<f32>,
    ) -> impl Future<Output = Result<Memory, RepositoryError>> + Send;

    fn get(&self, id: &str) -> impl Future<Output = Result<Memory, RepositoryError>> + Send;

    fn update(
        &self,
        id: &str,
        input: UpdateMemory,
    ) -> impl Future<Output = Result<Memory, RepositoryError>> + Send;

    fn delete(&self, id: &str) -> impl Future<Output = Result<(), RepositoryError>> + Send;

    fn list(&self, category: Option<Category>, tags: Vec<String>, limit: usize, offset: usize) -> impl Future<Output = Result<(Vec<Memory>, usize), RepositoryError>> + Send;

    fn list_tags(&self, category: Option<Category>) -> impl Future<Output = Result<Vec<String>, RepositoryError>> + Send;

    fn search(
        &self,
        query_embedding: Vec<f32>,
        limit: usize,
        category: Option<Category>,
    ) -> impl Future<Output = Result<Vec<Memory>, RepositoryError>> + Send;
}
