use std::sync::Mutex;
use std::time::{Duration, Instant};

use reqwest::Client;
use rmcp::handler::server::router::tool::ToolRouter;
use rmcp::handler::server::wrapper::Parameters;
use rmcp::model::*;
use rmcp::{ServerHandler, ServiceExt, tool, tool_handler, tool_router};
use schemars::JsonSchema;
use self_update::cargo_crate_version;
use serde::{Deserialize, Serialize};
use serde_json::json;

const CLIENT_ID: &str = "memory-pfl-mcp";

struct TokenCache {
    token: String,
    expires_at: Instant,
}

struct MemoryServer {
    client: Client,
    base_url: String,
    token_url: String,
    client_secret: String,
    token_cache: Mutex<Option<TokenCache>>,
    tool_router: ToolRouter<Self>,
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: String,
    expires_in: u64,
}

#[derive(Deserialize, JsonSchema)]
struct ListMemoriesInput {
    #[schemars(description = "Filter by category: \"development\" or \"general\"")]
    category: Option<String>,
    #[schemars(description = "Filter by tag")]
    tag: Option<String>,
}

#[derive(Deserialize, JsonSchema)]
struct GetMemoryInput {
    #[schemars(description = "The ID of the memory to retrieve")]
    id: String,
}

#[derive(Deserialize, JsonSchema)]
struct SearchMemoriesInput {
    #[schemars(description = "The search query for semantic search")]
    query: String,
    #[schemars(description = "Filter by category: \"development\" or \"general\"")]
    category: Option<String>,
}

#[derive(Deserialize, Serialize, JsonSchema)]
struct CreateMemoryInput {
    #[schemars(description = "The content of the memory")]
    content: String,
    #[schemars(description = "Tags for categorization")]
    tags: Vec<String>,
    #[schemars(description = "Category: \"development\" or \"general\"")]
    category: String,
}

#[derive(Deserialize, JsonSchema)]
struct UpdateMemoryInput {
    #[schemars(description = "The ID of the memory to update")]
    id: String,
    #[schemars(description = "New content (omit to keep unchanged)")]
    content: Option<String>,
    #[schemars(description = "New tags (omit to keep unchanged)")]
    tags: Option<Vec<String>>,
    #[schemars(description = "New category: \"development\" or \"general\" (omit to keep unchanged)")]
    category: Option<String>,
}

#[derive(Deserialize, JsonSchema)]
struct DeleteMemoryInput {
    #[schemars(description = "The ID of the memory to delete")]
    id: String,
}

#[tool_router]
impl MemoryServer {
    fn new(base_url: String, token_url: String, client_secret: String) -> Self {
        Self {
            client: Client::new(),
            base_url,
            token_url,
            client_secret,
            token_cache: Mutex::new(None),
            tool_router: Self::tool_router(),
        }
    }

    async fn access_token(&self) -> Result<String, String> {
        {
            let cache = self.token_cache.lock().unwrap();
            if let Some(c) = cache.as_ref() {
                if Instant::now() < c.expires_at {
                    return Ok(c.token.clone());
                }
            }
        }

        let resp: TokenResponse = self
            .client
            .post(&self.token_url)
            .form(&[
                ("grant_type", "client_credentials"),
                ("client_id", CLIENT_ID),
                ("client_secret", &self.client_secret),
            ])
            .send()
            .await
            .and_then(|r| r.error_for_status())
            .map_err(|e| format!("Token request failed: {e}"))?
            .json()
            .await
            .map_err(|e| format!("Token parse failed: {e}"))?;

        let token = resp.access_token.clone();
        let mut cache = self.token_cache.lock().unwrap();
        *cache = Some(TokenCache {
            token: resp.access_token,
            expires_at: Instant::now() + Duration::from_secs(resp.expires_in.saturating_sub(30)),
        });
        Ok(token)
    }

    async fn get(&self, path: &str) -> Result<reqwest::RequestBuilder, String> {
        let token = self.access_token().await?;
        Ok(self
            .client
            .get(format!("{}{}", self.base_url, path))
            .bearer_auth(token))
    }

    async fn post(&self, path: &str) -> Result<reqwest::RequestBuilder, String> {
        let token = self.access_token().await?;
        Ok(self
            .client
            .post(format!("{}{}", self.base_url, path))
            .bearer_auth(token))
    }

    async fn put(&self, path: &str) -> Result<reqwest::RequestBuilder, String> {
        let token = self.access_token().await?;
        Ok(self
            .client
            .put(format!("{}{}", self.base_url, path))
            .bearer_auth(token))
    }

    async fn delete(&self, path: &str) -> Result<reqwest::RequestBuilder, String> {
        let token = self.access_token().await?;
        Ok(self
            .client
            .delete(format!("{}{}", self.base_url, path))
            .bearer_auth(token))
    }

    #[tool(description = "List memories, optionally filtered by category and/or tag")]
    async fn list_memories(&self, Parameters(input): Parameters<ListMemoriesInput>) -> String {
        let mut req = match self.get("/memories").await {
            Ok(r) => r,
            Err(e) => return format!("Error: {e}"),
        };
        if let Some(c) = &input.category {
            req = req.query(&[("category", c.as_str())]);
        }
        if let Some(t) = &input.tag {
            req = req.query(&[("tag", t.as_str())]);
        }
        match req.send().await.and_then(|r| r.error_for_status()) {
            Ok(resp) => resp.text().await.unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Get a memory by ID")]
    async fn get_memory(&self, Parameters(input): Parameters<GetMemoryInput>) -> String {
        let path = format!("/memories/{}", input.id);
        match self.get(&path).await {
            Ok(req) => match req.send().await.and_then(|r| r.error_for_status()) {
                Ok(resp) => resp.text().await.unwrap_or_default(),
                Err(e) => format!("Error: {e}"),
            },
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Search memories semantically")]
    async fn search_memories(
        &self,
        Parameters(input): Parameters<SearchMemoriesInput>,
    ) -> String {
        let mut req = match self.get("/memories").await {
            Ok(r) => r,
            Err(e) => return format!("Error: {e}"),
        };
        req = req.query(&[("q", &input.query)]);
        if let Some(c) = &input.category {
            req = req.query(&[("category", c.as_str())]);
        }
        match req.send().await.and_then(|r| r.error_for_status()) {
            Ok(resp) => resp.text().await.unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Create a new memory")]
    async fn create_memory(
        &self,
        Parameters(input): Parameters<CreateMemoryInput>,
    ) -> String {
        let req = match self.post("/memories").await {
            Ok(r) => r,
            Err(e) => return format!("Error: {e}"),
        };
        match req.json(&input).send().await.and_then(|r| r.error_for_status()) {
            Ok(resp) => resp.text().await.unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Update an existing memory by ID")]
    async fn update_memory(
        &self,
        Parameters(input): Parameters<UpdateMemoryInput>,
    ) -> String {
        let path = format!("/memories/{}", input.id);
        let req = match self.put(&path).await {
            Ok(r) => r,
            Err(e) => return format!("Error: {e}"),
        };
        let mut body = json!({});
        if let Some(c) = input.content { body["content"] = json!(c); }
        if let Some(t) = input.tags { body["tags"] = json!(t); }
        if let Some(c) = input.category { body["category"] = json!(c); }
        match req.json(&body).send().await.and_then(|r| r.error_for_status()) {
            Ok(resp) => resp.text().await.unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Delete a memory by ID")]
    async fn delete_memory(
        &self,
        Parameters(input): Parameters<DeleteMemoryInput>,
    ) -> String {
        let path = format!("/memories/{}", input.id);
        match self.delete(&path).await {
            Ok(req) => match req.send().await.and_then(|r| r.error_for_status()) {
                Ok(_) => "Deleted".into(),
                Err(e) => format!("Error: {e}"),
            },
            Err(e) => format!("Error: {e}"),
        }
    }
}

#[tool_handler]
impl ServerHandler for MemoryServer {
    fn get_info(&self) -> ServerInfo {
        ServerInfo {
            capabilities: ServerCapabilities::builder().enable_tools().build(),
            server_info: Implementation {
                name: "memory-pfl".into(),
                version: "0.1.0".into(),
                ..Default::default()
            },
            instructions: Some(format!(
                "ユーザーの開発メモ・知見・意思決定の記録を保存したデータベース (v{})。\
                 過去の設計判断、学んだこと、開発パターンなどを検索・作成・更新・削除できる。\
                 ユーザーが過去の経験や知見に関連する作業をしているとき、\
                 類似の問題を以前解決したか確認したいとき、\
                 新しい知見を記録したいとき、\
                 または明示的にメモリを参照したいときに使用する。",
                cargo_crate_version!()
            )),
            ..Default::default()
        }
    }
}

fn self_update() {
    // Redirect stdout to /dev/null during self_update to avoid polluting MCP stdio
    use std::fs::File;
    use std::os::unix::io::AsRawFd;
    let devnull = File::open("/dev/null").unwrap();
    let saved_stdout = unsafe { libc::dup(1) };
    unsafe { libc::dup2(devnull.as_raw_fd(), 1) };

    let result = self_update::backends::github::Update::configure()
        .repo_owner("nesso-pfl")
        .repo_name("memory-pfl")
        .bin_name("memory-pfl-mcp")
        .current_version(cargo_crate_version!())
        .no_confirm(true)
        .build()
        .and_then(|u| u.update());

    // Restore stdout
    unsafe { libc::dup2(saved_stdout, 1) };
    unsafe { libc::close(saved_stdout) };

    match result {
        Ok(status) => {
            if status.updated() {
                eprintln!("Updated to {}", status.version());
            }
        }
        Err(e) => eprintln!("Update check failed: {e}"),
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    self_update();

    let env = |key: &str| std::env::var(key).unwrap_or_else(|_| panic!("{key} must be set"));

    let base_url = env("MCP_BASE_URL");
    let token_url = env("MCP_TOKEN_URL");
    let client_secret = env("MCP_CLIENT_SECRET");

    let server = MemoryServer::new(base_url, token_url, client_secret);
    let service = server.serve(rmcp::transport::io::stdio()).await?;
    service.waiting().await?;

    Ok(())
}
