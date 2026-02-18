use backend::embedding::GeminiClient;
use backend::model::Category;
use backend::repository::MemoryRepository;
use backend::repository::postgres::PgMemoryRepository;
use rmcp::handler::server::router::tool::ToolRouter;
use rmcp::handler::server::wrapper::Parameters;
use rmcp::model::*;
use rmcp::{ServerHandler, ServiceExt, tool, tool_handler, tool_router};
use schemars::JsonSchema;
use serde::Deserialize;

struct MemoryServer {
    repo: PgMemoryRepository,
    gemini: GeminiClient,
    tool_router: ToolRouter<Self>,
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
}

#[tool_router]
impl MemoryServer {
    fn new(repo: PgMemoryRepository, gemini: GeminiClient) -> Self {
        Self {
            repo,
            gemini,
            tool_router: Self::tool_router(),
        }
    }

    #[tool(description = "List all memories")]
    async fn list_memories(&self) -> String {
        match self.repo.list(Some(Category::Development), None, 100, 0).await {
            Ok(memories) => serde_json::to_string(&memories).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Get a memory by ID")]
    async fn get_memory(&self, Parameters(input): Parameters<GetMemoryInput>) -> String {
        match self.repo.get(&input.id).await {
            Ok(memory) => serde_json::to_string(&memory).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Search memories semantically")]
    async fn search_memories(&self, Parameters(input): Parameters<SearchMemoriesInput>) -> String {
        let embedding = match self.gemini.embed(&input.query, "RETRIEVAL_QUERY").await {
            Ok(v) => v,
            Err(e) => return format!("Error: {e}"),
        };
        match self.repo.search(embedding, 20, Some(Category::Development)).await {
            Ok(memories) => serde_json::to_string(&memories).unwrap_or_default(),
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

    let repo = PgMemoryRepository::new(&env("DATABASE_URL"))
        .await
        .expect("failed to initialize database");

    let api_key = env("GEMINI_API_KEY");
    let gemini = GeminiClient::new(api_key);

    let server = MemoryServer::new(repo, gemini);
    let service = server.serve(rmcp::transport::io::stdio()).await?;
    service.waiting().await?;

    Ok(())
}
