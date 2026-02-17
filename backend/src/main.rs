use axum::{
    Router,
    http::{StatusCode, header},
    response::{IntoResponse, Response},
    routing::get,
};
use rust_embed::Embed;

mod model;
mod repository;

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

#[tokio::main]
async fn main() {
    let _repo = SqliteMemoryRepository::new("sqlite:data/memories.db?mode=rwc")
        .await
        .expect("failed to initialize database");

    let app = Router::new().fallback(get(static_handler));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
