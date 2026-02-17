use serde::{Deserialize, Serialize};

pub struct GeminiClient {
    api_key: String,
    client: reqwest::Client,
}

#[derive(Serialize)]
struct EmbedRequest {
    model: String,
    content: Content,
    task_type: String,
    output_dimensionality: u32,
}

#[derive(Serialize)]
struct Content {
    parts: Vec<Part>,
}

#[derive(Serialize)]
struct Part {
    text: String,
}

#[derive(Deserialize)]
struct EmbedResponse {
    embedding: EmbeddingValues,
}

#[derive(Deserialize)]
struct EmbeddingValues {
    values: Vec<f32>,
}

impl GeminiClient {
    pub fn new(api_key: String) -> Self {
        Self {
            api_key,
            client: reqwest::Client::new(),
        }
    }

    pub async fn embed(&self, text: &str, task_type: &str) -> Result<Vec<f32>, reqwest::Error> {
        let url = format!(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key={}",
            self.api_key
        );
        let body = EmbedRequest {
            model: "models/gemini-embedding-001".into(),
            content: Content {
                parts: vec![Part { text: text.into() }],
            },
            task_type: task_type.into(),
            output_dimensionality: 768,
        };
        let resp: EmbedResponse = self.client.post(&url).json(&body).send().await?.json().await?;
        Ok(resp.embedding.values)
    }
}
