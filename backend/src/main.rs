use std::sync::Arc;

use axum::{
    Json, Router,
    extract::{Query, State},
    http::{StatusCode, header},
    response::{IntoResponse, Response},
    routing::get,
};
use rust_embed::Embed;
use serde::Deserialize;

mod embedding;
mod model;
mod repository;

use embedding::GeminiClient;
use model::CreateMemory;
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

struct AppStateInner {
    repo: SqliteMemoryRepository,
    gemini: GeminiClient,
}

type AppState = Arc<AppStateInner>;

async fn list_memories(State(state): State<AppState>) -> Response {
    use repository::MemoryRepository;
    match state.repo.list().await {
        Ok(memories) => Json(memories).into_response(),
        Err(e) => {
            eprintln!("list_memories error: {e}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

async fn create_memory(
    State(state): State<AppState>,
    Json(input): Json<CreateMemory>,
) -> Response {
    use repository::MemoryRepository;

    let embedding = match state.gemini.embed(&input.content, "RETRIEVAL_DOCUMENT").await {
        Ok(v) => v,
        Err(e) => {
            eprintln!("embedding error: {e}");
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };

    match state.repo.create(input, embedding).await {
        Ok(memory) => (StatusCode::CREATED, Json(memory)).into_response(),
        Err(e) => {
            eprintln!("create_memory error: {e}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

#[derive(Deserialize)]
struct SearchQuery {
    q: String,
}

async fn search_memories(
    State(state): State<AppState>,
    Query(params): Query<SearchQuery>,
) -> Response {
    use repository::MemoryRepository;

    let embedding = match state.gemini.embed(&params.q, "RETRIEVAL_QUERY").await {
        Ok(v) => v,
        Err(e) => {
            eprintln!("embedding error: {e}");
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };

    match state.repo.search(embedding, 20).await {
        Ok(memories) => Json(memories).into_response(),
        Err(e) => {
            eprintln!("search_memories error: {e}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

#[tokio::main]
async fn main() {
    unsafe {
        libsqlite3_sys::sqlite3_auto_extension(Some(std::mem::transmute(
            sqlite_vec::sqlite3_vec_init as *const (),
        )));
    }

    let repo = SqliteMemoryRepository::new("sqlite:data/memories.db?mode=rwc")
        .await
        .expect("failed to initialize database");

    let api_key = std::env::var("GEMINI_API_KEY").expect("GEMINI_API_KEY must be set");
    let gemini = GeminiClient::new(api_key);

    let state: AppState = Arc::new(AppStateInner { repo, gemini });

    let app = Router::new()
        .route("/memories", get(list_memories).post(create_memory))
        .route("/memories/search", get(search_memories))
        .fallback(get(static_handler))
        .with_state(state);
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
