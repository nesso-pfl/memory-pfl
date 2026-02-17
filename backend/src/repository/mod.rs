pub mod sqlite;

use std::future::Future;

use crate::model::{CreateMemory, Memory, UpdateMemory};

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
    ) -> impl Future<Output = Result<Memory, RepositoryError>> + Send;

    fn get(&self, id: &str) -> impl Future<Output = Result<Memory, RepositoryError>> + Send;

    fn update(
        &self,
        id: &str,
        input: UpdateMemory,
    ) -> impl Future<Output = Result<Memory, RepositoryError>> + Send;

    fn delete(&self, id: &str) -> impl Future<Output = Result<(), RepositoryError>> + Send;

    fn list(&self) -> impl Future<Output = Result<Vec<Memory>, RepositoryError>> + Send;
}
