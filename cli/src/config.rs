use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub project_name: String,
    pub backend_url: String,
    pub moodle_url: Option<String>,
    pub auto_sync: bool,
    pub ai_model: Option<String>,
    pub marking_rubric: Option<String>,
    #[serde(default)]
    pub default_concurrency: usize,
    #[serde(default)]
    pub timeout_seconds: u64,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            project_name: "Academic Workflow Suite".to_string(),
            backend_url: "http://localhost:8000".to_string(),
            moodle_url: None,
            auto_sync: false,
            ai_model: None,
            marking_rubric: None,
            default_concurrency: 5,
            timeout_seconds: 300,
        }
    }
}

impl Config {
    pub fn load<P: AsRef<Path>>(path: P) -> Result<Self> {
        let content = fs::read_to_string(path.as_ref())
            .context("Failed to read configuration file")?;

        let config: Config = serde_yaml::from_str(&content)
            .context("Failed to parse configuration file")?;

        Ok(config)
    }

    pub fn save<P: AsRef<Path>>(&self, path: P) -> Result<()> {
        let yaml = serde_yaml::to_string(self)
            .context("Failed to serialize configuration")?;

        fs::write(path.as_ref(), yaml)
            .context("Failed to write configuration file")?;

        Ok(())
    }

    pub fn validate(&self) -> Result<()> {
        if self.project_name.is_empty() {
            return Err(anyhow::anyhow!("Project name cannot be empty"));
        }

        if self.backend_url.is_empty() {
            return Err(anyhow::anyhow!("Backend URL cannot be empty"));
        }

        // Validate URL format
        if !self.backend_url.starts_with("http://") && !self.backend_url.starts_with("https://") {
            return Err(anyhow::anyhow!("Backend URL must start with http:// or https://"));
        }

        if let Some(moodle_url) = &self.moodle_url {
            if !moodle_url.starts_with("http://") && !moodle_url.starts_with("https://") {
                return Err(anyhow::anyhow!("Moodle URL must start with http:// or https://"));
            }
        }

        if self.default_concurrency == 0 {
            return Err(anyhow::anyhow!("Concurrency must be greater than 0"));
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::NamedTempFile;

    #[test]
    fn test_default_config() {
        let config = Config::default();
        assert_eq!(config.project_name, "Academic Workflow Suite");
        assert_eq!(config.backend_url, "http://localhost:8000");
        assert_eq!(config.auto_sync, false);
    }

    #[test]
    fn test_save_and_load() {
        let temp_file = NamedTempFile::new().unwrap();
        let config = Config::default();

        config.save(temp_file.path()).unwrap();
        let loaded = Config::load(temp_file.path()).unwrap();

        assert_eq!(config.project_name, loaded.project_name);
        assert_eq!(config.backend_url, loaded.backend_url);
    }

    #[test]
    fn test_validate() {
        let config = Config::default();
        assert!(config.validate().is_ok());

        let mut invalid = Config::default();
        invalid.project_name = String::new();
        assert!(invalid.validate().is_err());

        let mut invalid = Config::default();
        invalid.backend_url = "invalid-url".to_string();
        assert!(invalid.validate().is_err());
    }
}
