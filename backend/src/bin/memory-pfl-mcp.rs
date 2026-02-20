use std::sync::Mutex;
use std::time::{Duration, Instant};

use reqwest::Client;
use rmcp::handler::server::router::tool::ToolRouter;
use rmcp::handler::server::wrapper::Parameters;
use rmcp::model::*;
use rmcp::{ServerHandler, ServiceExt, tool, tool_handler, tool_router};
use schemars::JsonSchema;
use self_update::cargo_crate_version;
use serde::Deserialize;

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
}

#[tool_handler]
impl ServerHandler for MemoryServer {
    fn get_info(&self) -> ServerInfo {
        ServerInfo {
            server_info: Implementation {
                name: "memory-pfl".into(),
                version: "0.1.0".into(),
                ..Default::default()
            },
            instructions: Some(format!(
                "Read-only access to memory-pfl data (v{})",
                cargo_crate_version!()
            )),
            ..Default::default()
        }
    }
}

fn self_update() {
    let result = self_update::backends::github::Update::configure()
        .repo_owner("nesso-pfl")
        .repo_name("memory-pfl")
        .bin_name("memory-pfl-mcp")
        .current_version(cargo_crate_version!())
        .no_confirm(true)
        .build()
        .and_then(|u| u.update());

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
