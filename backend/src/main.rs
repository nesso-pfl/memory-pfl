use std::sync::Arc;

use axum::{
    Json, Router,
    extract::State,
    http::{StatusCode, header},
    response::{IntoResponse, Response},
    routing::{get, post},
};
use rust_embed::Embed;

mod model;
mod repository;

use model::CreateMemory;
use repository::RepositoryError;
use repository::sqlite::SqliteMemoryRepository;

#[derive(Embed)]
#[folder = "../frontend/dist/"]
struct Assets;

fn serve_asset(path: &str) -> Response {
    match Assets::get(path) {
        Some(file) => {
            let mime = mime_guess::from_path(path).first_or_octet_stream();
            ([(header::CONTENT_TYPE, mime.as_ref())], file.data).into_response()
        }
        None => serve_index(),
    }
}

fn serve_index() -> Response {
    match Assets::get("index.html") {
        Some(file) => ([(header::CONTENT_TYPE, "text/html")], file.data).into_response(),
        None => (StatusCode::NOT_FOUND, "index.html not found").into_response(),
    }
}

async fn static_handler(uri: axum::http::Uri) -> Response {
    let path = uri.path().trim_start_matches('/');
    if path.is_empty() {
        return serve_index();
    }
    serve_asset(path)
}

type AppState = Arc<SqliteMemoryRepository>;

async fn create_memory(
    State(repo): State<AppState>,
    Json(input): Json<CreateMemory>,
) -> Response {
    use repository::MemoryRepository;
    match repo.create(input).await {
        Ok(memory) => (StatusCode::CREATED, Json(memory)).into_response(),
        Err(RepositoryError::Internal(e)) => {
            eprintln!("create_memory error: {e}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
        Err(e) => {
            eprintln!("create_memory error: {e}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

#[tokio::main]
async fn main() {
    let repo = SqliteMemoryRepository::new("sqlite:data/memories.db?mode=rwc")
        .await
        .expect("failed to initialize database");
    let state: AppState = Arc::new(repo);

    let app = Router::new()
        .route("/memories", post(create_memory))
        .fallback(get(static_handler))
        .with_state(state);
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
