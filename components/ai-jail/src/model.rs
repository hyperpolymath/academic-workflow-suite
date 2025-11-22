//! Model loading and configuration for Mistral 7B using Candle
//!
//! This module handles loading Mistral 7B models from local storage,
//! with support for quantization to fit within 8GB VRAM constraints.

use anyhow::{Context, Result};
use candle_core::{DType, Device, Tensor};
use candle_nn::VarBuilder;
use candle_transformers::models::mistral::{Config as MistralConfig, Model as MistralModel};
use std::path::{Path, PathBuf};
use tokenizers::Tokenizer;

/// Quantization mode for model weights
#[derive(Debug, Clone, Copy)]
pub enum QuantizationMode {
    /// No quantization (full precision)
    None,
    /// 8-bit quantization
    Q8,
    /// 4-bit quantization (most memory efficient)
    Q4,
}

/// Configuration for model loading
#[derive(Debug, Clone)]
pub struct ModelConfig {
    /// Path to model weights (safetensors or GGUF)
    pub model_path: PathBuf,

    /// Path to tokenizer.json
    pub tokenizer_path: PathBuf,

    /// Quantization mode
    pub quantization: QuantizationMode,

    /// Device to load model on (CPU or CUDA)
    pub device: Device,

    /// Use flash attention (if available)
    pub use_flash_attn: bool,
}

impl ModelConfig {
    /// Create a new model configuration with defaults for RTX 3080 (8GB)
    pub fn new_default() -> Result<Self> {
        let model_dir = PathBuf::from("/models/mistral-7b");

        Ok(Self {
            model_path: model_dir.join("model.safetensors"),
            tokenizer_path: model_dir.join("tokenizer.json"),
            quantization: QuantizationMode::Q4, // Default to 4-bit for 8GB VRAM
            device: Device::cuda_if_available(0)?,
            use_flash_attn: true,
        })
    }

    /// Create configuration from environment variables
    pub fn from_env() -> Result<Self> {
        let model_path = std::env::var("MODEL_PATH")
            .unwrap_or_else(|_| "/models/mistral-7b/model.safetensors".to_string());

        let tokenizer_path = std::env::var("TOKENIZER_PATH")
            .unwrap_or_else(|_| "/models/mistral-7b/tokenizer.json".to_string());

        let quantization = match std::env::var("QUANTIZATION").as_deref() {
            Ok("none") | Ok("fp16") => QuantizationMode::None,
            Ok("q8") => QuantizationMode::Q8,
            Ok("q4") | _ => QuantizationMode::Q4,
        };

        let device = Device::cuda_if_available(0)?;

        Ok(Self {
            model_path: PathBuf::from(model_path),
            tokenizer_path: PathBuf::from(tokenizer_path),
            quantization,
            device,
            use_flash_attn: true,
        })
    }
}

/// Loaded model with tokenizer
pub struct LoadedModel {
    pub model: MistralModel,
    pub tokenizer: Tokenizer,
    pub device: Device,
    pub config: MistralConfig,
}

impl LoadedModel {
    /// Load a Mistral 7B model from disk
    pub fn load(config: ModelConfig) -> Result<Self> {
        tracing::info!("Loading model from {:?}", config.model_path);
        tracing::info!("Using device: {:?}", config.device);
        tracing::info!("Quantization: {:?}", config.quantization);

        // Load tokenizer
        let tokenizer = Tokenizer::from_file(&config.tokenizer_path)
            .map_err(|e| anyhow::anyhow!("Failed to load tokenizer: {}", e))?;

        // Load model configuration
        let model_config = Self::get_mistral_config();

        // Determine dtype based on quantization
        let dtype = match config.quantization {
            QuantizationMode::None => DType::F16,
            QuantizationMode::Q8 => DType::U8,
            QuantizationMode::Q4 => DType::U8, // GGUF Q4 uses U8 storage
        };

        // Load model weights
        let vb = unsafe {
            VarBuilder::from_mmaped_safetensors(
                &[config.model_path.clone()],
                dtype,
                &config.device,
            )?
        };

        // Build model
        let model = MistralModel::new(&model_config, vb)?;

        tracing::info!("Model loaded successfully");

        Ok(Self {
            model,
            tokenizer,
            device: config.device,
            config: model_config,
        })
    }

    /// Get Mistral 7B model configuration
    fn get_mistral_config() -> MistralConfig {
        MistralConfig {
            vocab_size: 32000,
            hidden_size: 4096,
            intermediate_size: 14336,
            num_hidden_layers: 32,
            num_attention_heads: 32,
            num_key_value_heads: 8,
            hidden_act: candle_nn::Activation::Silu,
            max_position_embeddings: 32768,
            rms_norm_eps: 1e-5,
            rope_theta: 10000.0,
            sliding_window: Some(4096),
            use_flash_attn: true,
        }
    }

    /// Encode text to token IDs
    pub fn encode(&self, text: &str, add_special_tokens: bool) -> Result<Vec<u32>> {
        let encoding = self.tokenizer
            .encode(text, add_special_tokens)
            .map_err(|e| anyhow::anyhow!("Tokenization failed: {}", e))?;

        Ok(encoding.get_ids().to_vec())
    }

    /// Decode token IDs to text
    pub fn decode(&self, tokens: &[u32], skip_special_tokens: bool) -> Result<String> {
        self.tokenizer
            .decode(tokens, skip_special_tokens)
            .map_err(|e| anyhow::anyhow!("Detokenization failed: {}", e))
    }

    /// Get the end-of-sequence token ID
    pub fn eos_token_id(&self) -> Option<u32> {
        self.tokenizer
            .get_vocab(true)
            .get("</s>")
            .or_else(|| self.tokenizer.get_vocab(true).get("<|im_end|>"))
            .copied()
    }

    /// Forward pass through the model
    pub fn forward(&mut self, input_ids: &Tensor, position_ids: usize) -> Result<Tensor> {
        self.model
            .forward(input_ids, position_ids)
            .context("Model forward pass failed")
    }

    /// Get estimated memory usage in bytes
    pub fn estimate_memory_usage(&self) -> usize {
        // Rough estimate for Mistral 7B
        let params = 7_000_000_000u64; // 7B parameters

        let bytes_per_param = match self.device {
            Device::Cpu => 2, // FP16
            Device::Cuda(_) => match std::env::var("QUANTIZATION").as_deref() {
                Ok("q4") => 1, // 4-bit quantized (0.5 bytes but rounded up)
                Ok("q8") => 1, // 8-bit quantized
                _ => 2, // FP16
            },
            _ => 2,
        };

        (params * bytes_per_param) as usize
    }
}

/// Builder for model configuration
pub struct ModelBuilder {
    model_path: Option<PathBuf>,
    tokenizer_path: Option<PathBuf>,
    quantization: QuantizationMode,
}

impl ModelBuilder {
    pub fn new() -> Self {
        Self {
            model_path: None,
            tokenizer_path: None,
            quantization: QuantizationMode::Q4,
        }
    }

    pub fn model_path(mut self, path: impl Into<PathBuf>) -> Self {
        self.model_path = Some(path.into());
        self
    }

    pub fn tokenizer_path(mut self, path: impl Into<PathBuf>) -> Self {
        self.tokenizer_path = Some(path.into());
        self
    }

    pub fn quantization(mut self, quant: QuantizationMode) -> Self {
        self.quantization = quant;
        self
    }

    pub fn build(self) -> Result<ModelConfig> {
        let model_path = self.model_path
            .ok_or_else(|| anyhow::anyhow!("Model path not specified"))?;

        let tokenizer_path = self.tokenizer_path
            .ok_or_else(|| anyhow::anyhow!("Tokenizer path not specified"))?;

        Ok(ModelConfig {
            model_path,
            tokenizer_path,
            quantization: self.quantization,
            device: Device::cuda_if_available(0)?,
            use_flash_attn: true,
        })
    }
}

impl Default for ModelBuilder {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_config_from_env() {
        std::env::set_var("MODEL_PATH", "/test/model.safetensors");
        std::env::set_var("TOKENIZER_PATH", "/test/tokenizer.json");
        std::env::set_var("QUANTIZATION", "q4");

        let config = ModelConfig::from_env().unwrap();
        assert_eq!(config.model_path, PathBuf::from("/test/model.safetensors"));
        assert_eq!(config.tokenizer_path, PathBuf::from("/test/tokenizer.json"));

        std::env::remove_var("MODEL_PATH");
        std::env::remove_var("TOKENIZER_PATH");
        std::env::remove_var("QUANTIZATION");
    }

    #[test]
    fn test_model_builder() {
        let config = ModelBuilder::new()
            .model_path("/test/model.safetensors")
            .tokenizer_path("/test/tokenizer.json")
            .quantization(QuantizationMode::Q8)
            .build()
            .unwrap();

        assert_eq!(config.model_path, PathBuf::from("/test/model.safetensors"));
    }
}
