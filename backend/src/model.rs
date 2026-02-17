use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Category {
    Development,
    General,
}

impl Category {
    pub fn as_str(&self) -> &'static str {
        match self {
            Category::Development => "development",
            Category::General => "general",
        }
    }

    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "development" => Some(Category::Development),
            "general" => Some(Category::General),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Memory {
    pub id: String,
    pub content: String,
    pub tags: Vec<String>,
    pub category: Category,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

pub struct CreateMemory {
    pub content: String,
    pub tags: Vec<String>,
    pub category: Category,
}

pub struct UpdateMemory {
    pub content: Option<String>,
    pub tags: Option<Vec<String>>,
    pub category: Option<Category>,
}
