use std::sync::Arc;

use auth::{AuthConfig, AuthState, Claims, UserProfile, roles::MemoryPflApiRole};
use axum::{
    Extension, Json, Router,
    extract::{FromRequestParts, Path, Query, State},
    http::{StatusCode, header, request::Parts},
    response::{IntoResponse, Response},
    routing::get,
};
use backend::embedding::GeminiClient;
use backend::model::{Category, CreateMemory, UpdateMemory};
use backend::repository;
use backend::repository::sqlite::SqliteMemoryRepository;
use rust_embed::Embed;
use serde::Deserialize;

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

struct RequireRead;

impl<S: Send + Sync> FromRequestParts<S> for RequireRead {
    type Rejection = StatusCode;
    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let claims = parts.extensions.get::<Claims>().ok_or(StatusCode::UNAUTHORIZED)?;
        claims
            .has_role(&MemoryPflApiRole::Read)
            .then_some(Self)
            .ok_or(StatusCode::FORBIDDEN)
    }
}

struct RequireWrite;

impl<S: Send + Sync> FromRequestParts<S> for RequireWrite {
    type Rejection = StatusCode;
    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let claims = parts.extensions.get::<Claims>().ok_or(StatusCode::UNAUTHORIZED)?;
        claims
            .has_role(&MemoryPflApiRole::Write)
            .then_some(Self)
            .ok_or(StatusCode::FORBIDDEN)
    }
}

async fn list_memories(
    _: RequireRead,
    State(state): State<AppState>,
    Query(params): Query<ListQuery>,
) -> Response {
    use repository::MemoryRepository;

    if params.q.is_empty() {
        let limit = params.limit.min(200);
        let offset = params.page.saturating_sub(1) * limit;
        return match state.repo.list(params.category, params.tag, limit, offset).await {
            Ok(memories) => Json(memories).into_response(),
            Err(e) => {
                eprintln!("list_memories error: {e}");
                StatusCode::INTERNAL_SERVER_ERROR.into_response()
            }
        };
    }

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

async fn get_memory(_: RequireRead, State(state): State<AppState>, Path(id): Path<String>) -> Response {
    use repository::MemoryRepository;
    match state.repo.get(&id).await {
        Ok(memory) => Json(memory).into_response(),
        Err(repository::RepositoryError::NotFound) => StatusCode::NOT_FOUND.into_response(),
        Err(e) => {
            eprintln!("get_memory error: {e}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

async fn create_memory(
    _: RequireWrite,
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

async fn update_memory(
    _: RequireWrite,
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(input): Json<UpdateMemory>,
) -> Response {
    use repository::MemoryRepository;
    match state.repo.update(&id, input).await {
        Ok(memory) => Json(memory).into_response(),
        Err(repository::RepositoryError::NotFound) => StatusCode::NOT_FOUND.into_response(),
        Err(e) => {
            eprintln!("update_memory error: {e}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

async fn delete_memory(_: RequireWrite, State(state): State<AppState>, Path(id): Path<String>) -> Response {
    use repository::MemoryRepository;
    match state.repo.delete(&id).await {
        Ok(()) => StatusCode::NO_CONTENT.into_response(),
        Err(repository::RepositoryError::NotFound) => StatusCode::NOT_FOUND.into_response(),
        Err(e) => {
            eprintln!("delete_memory error: {e}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

#[derive(Deserialize)]
struct ListQuery {
    #[serde(default)]
    q: String,
    category: Option<Category>,
    tag: Option<String>,
    #[serde(default = "default_limit")]
    limit: usize,
    #[serde(default = "default_page")]
    page: usize,
}

fn default_limit() -> usize {
    100
}

fn default_page() -> usize {
    1
}

#[derive(Deserialize)]
struct TagsQuery {
    category: Option<Category>,
}

async fn list_tags(
    _: RequireRead,
    State(state): State<AppState>,
    Query(params): Query<TagsQuery>,
) -> Response {
    use repository::MemoryRepository;
    match state.repo.list_tags(params.category).await {
        Ok(tags) => Json(tags).into_response(),
        Err(e) => {
            eprintln!("list_tags error: {e}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        }
    }
}

async fn me_handler(Extension(profile): Extension<UserProfile>) -> Json<UserProfile> {
    Json(profile)
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

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

    let env = |key: &str| std::env::var(key).unwrap_or_else(|_| panic!("{key} must be set"));
    let auth_config = AuthConfig::builder()
        .issuer_url(env("AUTH_ISSUER_URL"))
        .client_id(env("AUTH_CLIENT_ID"))
        .client_secret(env("AUTH_CLIENT_SECRET"))
        .redirect_uri(env("AUTH_REDIRECT_URI"))
        .post_logout_uri(env("AUTH_POST_LOGOUT_URI"))
        .redis_url(env("AUTH_REDIS_URL"))
        .build()
        .expect("invalid auth config");
    let auth_state = AuthState::new(auth_config)
        .await
        .expect("failed to initialize auth");

    let api = Router::new()
        .route("/memories", get(list_memories).post(create_memory))
        .route("/memories/tags", get(list_tags))
        .route("/memories/{id}", get(get_memory).put(update_memory).delete(delete_memory))
        .route("/auth/me", get(me_handler))
        .layer(axum::middleware::from_fn_with_state(
            auth_state.clone(),
            auth::auth_middleware,
        ))
        .with_state(state);

    let app = Router::new()
        .merge(api)
        .merge(auth::auth_routes(auth_state))
        .fallback(get(static_handler));

    let port = std::env::var("PORT").expect("PORT must be set");
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}")).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
