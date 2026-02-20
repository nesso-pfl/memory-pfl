use reqwest::Client;
use rmcp::handler::server::router::tool::ToolRouter;
use rmcp::handler::server::wrapper::Parameters;
use rmcp::model::*;
use rmcp::{ServerHandler, ServiceExt, tool, tool_handler, tool_router};
use schemars::JsonSchema;
use serde::Deserialize;

struct MemoryServer {
    client: Client,
    base_url: String,
    cookie: String,
    tool_router: ToolRouter<Self>,
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
    fn new(base_url: String, cookie: String) -> Self {
        Self {
            client: Client::new(),
            base_url,
            cookie,
            tool_router: Self::tool_router(),
        }
    }

    fn get(&self, path: &str) -> reqwest::RequestBuilder {
        self.client
            .get(format!("{}{}", self.base_url, path))
            .header("Cookie", &self.cookie)
    }

    #[tool(description = "List memories, optionally filtered by category and/or tag")]
    async fn list_memories(&self, Parameters(input): Parameters<ListMemoriesInput>) -> String {
        let mut req = self.get("/memories");
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
        match self.get(&path).send().await.and_then(|r| r.error_for_status()) {
            Ok(resp) => resp.text().await.unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Search memories semantically")]
    async fn search_memories(
        &self,
        Parameters(input): Parameters<SearchMemoriesInput>,
    ) -> String {
        let mut req = self.get("/memories").query(&[("q", &input.query)]);
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
            instructions: Some("Read-only access to memory-pfl data".into()),
            ..Default::default()
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let env = |key: &str| std::env::var(key).unwrap_or_else(|_| panic!("{key} must be set"));

    let base_url = env("MCP_BASE_URL");
    let cookie = env("MCP_COOKIE");

    let server = MemoryServer::new(base_url, cookie);
    let service = server.serve(rmcp::transport::io::stdio()).await?;
    service.waiting().await?;

    Ok(())
}
