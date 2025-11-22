//! Text generation and inference logic using Candle
//!
//! This module implements the core inference pipeline for generating
//! TMA feedback using the loaded Mistral model.

use anyhow::{Context, Result};
use candle_core::{DType, Device, Tensor};
use std::time::Instant;

use crate::model::LoadedModel;
use crate::protocol::{InferenceRequest, InferenceResponse};

/// Sampling parameters for text generation
#[derive(Debug, Clone)]
pub struct SamplingParams {
    /// Temperature for sampling (higher = more random)
    pub temperature: f64,

    /// Top-p (nucleus) sampling threshold
    pub top_p: f64,

    /// Maximum tokens to generate
    pub max_tokens: usize,

    /// Repetition penalty
    pub repetition_penalty: f32,

    /// Stop sequences
    pub stop_sequences: Vec<String>,
}

impl Default for SamplingParams {
    fn default() -> Self {
        Self {
            temperature: 0.7,
            top_p: 0.9,
            max_tokens: 512,
            repetition_penalty: 1.1,
            stop_sequences: vec![
                "</s>".to_string(),
                "<|im_end|>".to_string(),
            ],
        }
    }
}

impl From<&InferenceRequest> for SamplingParams {
    fn from(req: &InferenceRequest) -> Self {
        Self {
            temperature: req.temperature,
            top_p: req.top_p,
            max_tokens: req.max_tokens,
            ..Default::default()
        }
    }
}

/// Logits processor for sampling
pub struct LogitsProcessor {
    temperature: f64,
    top_p: f64,
    repetition_penalty: f32,
    generated_tokens: Vec<u32>,
}

impl LogitsProcessor {
    pub fn new(params: &SamplingParams) -> Self {
        Self {
            temperature: params.temperature,
            top_p: params.top_p,
            repetition_penalty: params.repetition_penalty,
            generated_tokens: Vec::new(),
        }
    }

    /// Process logits and sample next token
    pub fn sample(&mut self, logits: &Tensor) -> Result<u32> {
        let logits = logits.to_dtype(DType::F32)?;
        let logits = logits.to_vec1::<f32>()?;

        // Apply repetition penalty
        let mut logits = self.apply_repetition_penalty(logits);

        // Apply temperature
        if self.temperature > 0.0 {
            logits.iter_mut().for_each(|l| *l /= self.temperature as f32);
        }

        // Apply softmax
        let max_logit = logits.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
        let mut probs: Vec<f32> = logits
            .iter()
            .map(|&l| (l - max_logit).exp())
            .collect();

        let sum: f32 = probs.iter().sum();
        probs.iter_mut().for_each(|p| *p /= sum);

        // Apply top-p sampling
        let token = if self.top_p < 1.0 {
            self.sample_top_p(&probs)
        } else {
            self.sample_multinomial(&probs)
        };

        self.generated_tokens.push(token);
        Ok(token)
    }

    fn apply_repetition_penalty(&self, mut logits: Vec<f32>) -> Vec<f32> {
        if self.repetition_penalty == 1.0 {
            return logits;
        }

        for &token in &self.generated_tokens {
            let token_idx = token as usize;
            if token_idx < logits.len() {
                if logits[token_idx] < 0.0 {
                    logits[token_idx] *= self.repetition_penalty;
                } else {
                    logits[token_idx] /= self.repetition_penalty;
                }
            }
        }

        logits
    }

    fn sample_top_p(&self, probs: &[f32]) -> u32 {
        // Create (index, prob) pairs and sort by probability descending
        let mut indexed_probs: Vec<(usize, f32)> = probs
            .iter()
            .enumerate()
            .map(|(i, &p)| (i, p))
            .collect();

        indexed_probs.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());

        // Accumulate probabilities until we reach top_p
        let mut cumsum = 0.0;
        let mut top_p_probs = vec![0.0; probs.len()];

        for (idx, prob) in indexed_probs {
            cumsum += prob;
            top_p_probs[idx] = prob;

            if cumsum >= self.top_p {
                break;
            }
        }

        // Renormalize
        let sum: f32 = top_p_probs.iter().sum();
        if sum > 0.0 {
            top_p_probs.iter_mut().for_each(|p| *p /= sum);
        }

        self.sample_multinomial(&top_p_probs)
    }

    fn sample_multinomial(&self, probs: &[f32]) -> u32 {
        let random: f32 = rand::random();
        let mut cumsum = 0.0;

        for (i, &prob) in probs.iter().enumerate() {
            cumsum += prob;
            if random < cumsum {
                return i as u32;
            }
        }

        // Fallback to last token if rounding errors occur
        (probs.len() - 1) as u32
    }
}

/// Inference engine for text generation
pub struct InferenceEngine {
    model: LoadedModel,
}

impl InferenceEngine {
    pub fn new(model: LoadedModel) -> Self {
        Self { model }
    }

    /// Generate feedback for a TMA question
    pub fn generate(&mut self, request: &InferenceRequest) -> Result<InferenceResponse> {
        let start_time = Instant::now();

        // Validate request
        request.validate()
            .context("Invalid inference request")?;

        // Create prompt
        let prompt = request.to_prompt();
        tracing::debug!("Prompt: {}", prompt);

        // Encode prompt
        let input_tokens = self.model.encode(&prompt, true)?;
        tracing::info!("Input tokens: {}", input_tokens.len());

        // Generate text
        let sampling_params = SamplingParams::from(request);
        let generated_tokens = self.generate_tokens(&input_tokens, &sampling_params)?;

        // Decode output
        let feedback = self.model.decode(&generated_tokens, true)?;

        // Calculate metrics
        let confidence = self.calculate_confidence(&generated_tokens);
        let rubric_alignment = self.calculate_rubric_alignment(&feedback, &request.rubric);

        let inference_time_ms = start_time.elapsed().as_millis() as u64;

        tracing::info!(
            "Generated {} tokens in {}ms",
            generated_tokens.len(),
            inference_time_ms
        );

        Ok(InferenceResponse {
            feedback: feedback.trim().to_string(),
            confidence,
            rubric_alignment,
            tokens_generated: generated_tokens.len(),
            inference_time_ms,
        })
    }

    /// Generate tokens using the model
    fn generate_tokens(
        &mut self,
        input_tokens: &[u32],
        params: &SamplingParams,
    ) -> Result<Vec<u32>> {
        let mut generated = Vec::new();
        let mut logits_processor = LogitsProcessor::new(params);

        let eos_token = self.model.eos_token_id().unwrap_or(2); // Default to </s> token ID

        // Convert input tokens to tensor
        let mut tokens = input_tokens.to_vec();
        let device = &self.model.device;

        for step in 0..params.max_tokens {
            // Create input tensor for current tokens
            let input_tensor = Tensor::new(&tokens[..], device)?
                .unsqueeze(0)?; // Add batch dimension

            // Forward pass
            let logits = self.model.forward(&input_tensor, tokens.len() - 1)?;

            // Get logits for last token
            let last_logits = logits.get(0)?.get(tokens.len() - 1)?;

            // Sample next token
            let next_token = logits_processor.sample(&last_logits)?;

            // Check for stop conditions
            if next_token == eos_token {
                tracing::debug!("EOS token generated at step {}", step);
                break;
            }

            // Check for stop sequences
            let generated_text = self.model.decode(&generated, true)?;
            if params.stop_sequences.iter().any(|seq| generated_text.ends_with(seq)) {
                tracing::debug!("Stop sequence detected at step {}", step);
                break;
            }

            generated.push(next_token);
            tokens.push(next_token);

            if step % 50 == 0 {
                tracing::debug!("Generated {} tokens", step);
            }
        }

        Ok(generated)
    }

    /// Calculate confidence score based on token probabilities
    fn calculate_confidence(&self, _tokens: &[u32]) -> f32 {
        // Simplified confidence calculation
        // In production, this would analyze the probability distribution
        // of generated tokens
        0.85 // Placeholder
    }

    /// Calculate rubric alignment score
    fn calculate_rubric_alignment(&self, feedback: &str, rubric: &str) -> f32 {
        // Simplified rubric alignment calculation
        // In production, this would use semantic similarity or keyword matching

        let rubric_lower = rubric.to_lowercase();
        let feedback_lower = feedback.to_lowercase();

        // Extract key terms from rubric
        let key_terms: Vec<&str> = rubric_lower
            .split_whitespace()
            .filter(|w| w.len() > 4)
            .collect();

        if key_terms.is_empty() {
            return 0.5;
        }

        // Count how many key terms appear in feedback
        let matches = key_terms
            .iter()
            .filter(|term| feedback_lower.contains(*term))
            .count();

        (matches as f32 / key_terms.len() as f32).min(1.0)
    }
}

// Add rand dependency for sampling
mod rand {
    use std::cell::Cell;

    thread_local! {
        static RNG_STATE: Cell<u64> = Cell::new(0x4d595df4d0f33173);
    }

    pub fn random() -> f32 {
        RNG_STATE.with(|state| {
            let mut x = state.get();
            x ^= x << 13;
            x ^= x >> 7;
            x ^= x << 17;
            state.set(x);
            (x as f32) / (u64::MAX as f32)
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sampling_params_default() {
        let params = SamplingParams::default();
        assert_eq!(params.temperature, 0.7);
        assert_eq!(params.top_p, 0.9);
        assert_eq!(params.max_tokens, 512);
    }

    #[test]
    fn test_sampling_params_from_request() {
        let req = InferenceRequest {
            tma_content: "test".to_string(),
            rubric: "test".to_string(),
            question_number: 1,
            student_answer: None,
            max_tokens: 256,
            temperature: 0.5,
            top_p: 0.95,
        };

        let params = SamplingParams::from(&req);
        assert_eq!(params.temperature, 0.5);
        assert_eq!(params.top_p, 0.95);
        assert_eq!(params.max_tokens, 256);
    }

    #[test]
    fn test_logits_processor() {
        let params = SamplingParams::default();
        let mut processor = LogitsProcessor::new(&params);

        // Test that processor can be created
        assert_eq!(processor.temperature, 0.7);
        assert_eq!(processor.generated_tokens.len(), 0);
    }
}
