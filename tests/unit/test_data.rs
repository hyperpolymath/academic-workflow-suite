/// Test data generators for Academic Workflow Suite
///
/// This module provides utilities for generating test data including:
/// - Random TMAs with configurable quality levels
/// - Random rubrics with criteria and scoring
/// - Random student records
/// - Property-based test data
///
/// Use these generators in unit tests to ensure comprehensive coverage
/// and test edge cases.

use rand::prelude::*;
use rand::distributions::Alphanumeric;
use serde::{Deserialize, Serialize};

/// Quality level for generated TMA content
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum QualityLevel {
    Excellent,
    Good,
    Satisfactory,
    Poor,
    VeryPoor,
}

/// Generated TMA submission
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneratedTMA {
    pub submission_id: String,
    pub student_id: String,
    pub module: String,
    pub assignment: String,
    pub question: u32,
    pub content: String,
    pub word_count: usize,
    pub quality_level: String,
}

/// Rubric criterion for grading
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RubricCriterion {
    pub name: String,
    pub weight: u32,
    pub description: String,
    pub max_score: u32,
}

/// Generated grading rubric
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneratedRubric {
    pub question_id: String,
    pub module: String,
    pub title: String,
    pub total_points: u32,
    pub criteria: Vec<RubricCriterion>,
}

/// Student record
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneratedStudent {
    pub student_id: String,
    pub anonymous_id: String,
    pub enrolled_modules: Vec<String>,
    pub performance_level: String,
}

/// TMA Generator with configurable parameters
pub struct TMAGenerator {
    rng: StdRng,
}

impl TMAGenerator {
    /// Create a new TMA generator with a random seed
    pub fn new() -> Self {
        Self {
            rng: StdRng::from_entropy(),
        }
    }

    /// Create a new TMA generator with a specific seed for reproducibility
    pub fn with_seed(seed: u64) -> Self {
        Self {
            rng: StdRng::seed_from_u64(seed),
        }
    }

    /// Generate a random TMA submission
    pub fn generate_tma(&mut self, quality: QualityLevel) -> GeneratedTMA {
        let submission_id = self.random_id("SUB");
        let student_id = self.random_id("S");
        let module = self.random_module();
        let assignment = format!("TMA{:02}", self.rng.gen_range(1..=5));
        let question = self.rng.gen_range(1..=5);

        let (content, word_count) = self.generate_content(quality, &module, question);

        GeneratedTMA {
            submission_id,
            student_id,
            module,
            assignment,
            question,
            content,
            word_count,
            quality_level: format!("{:?}", quality),
        }
    }

    /// Generate content based on quality level
    fn generate_content(&mut self, quality: QualityLevel, module: &str, question: u32) -> (String, usize) {
        let templates = self.get_content_templates(module, question);
        let template = &templates[self.rng.gen_range(0..templates.len())];

        let base_word_count = match quality {
            QualityLevel::Excellent => self.rng.gen_range(450..550),
            QualityLevel::Good => self.rng.gen_range(400..500),
            QualityLevel::Satisfactory => self.rng.gen_range(300..400),
            QualityLevel::Poor => self.rng.gen_range(200..350),
            QualityLevel::VeryPoor => self.rng.gen_range(100..250),
        };

        let content = self.expand_template(template, base_word_count, quality);
        let word_count = content.split_whitespace().count();

        (content, word_count)
    }

    /// Expand a template into full content
    fn expand_template(&mut self, template: &str, target_words: usize, quality: QualityLevel) -> String {
        let mut content = template.to_string();

        // Add filler content to reach target word count
        let current_words = content.split_whitespace().count();
        if current_words < target_words {
            let additional = self.generate_filler(target_words - current_words, quality);
            content.push_str(&additional);
        }

        content
    }

    /// Generate filler content
    fn generate_filler(&mut self, words: usize, quality: QualityLevel) -> String {
        let sentences = match quality {
            QualityLevel::Excellent => vec![
                "This demonstrates a sophisticated understanding of the underlying principles.",
                "Furthermore, the implementation considers edge cases and optimization opportunities.",
                "The approach aligns with industry best practices and academic research.",
            ],
            QualityLevel::Good => vec![
                "This shows a good understanding of the key concepts.",
                "The implementation is functional and addresses the main requirements.",
                "Several important aspects are covered in this analysis.",
            ],
            QualityLevel::Satisfactory => vec![
                "This covers the basic ideas.",
                "The main points are mentioned.",
                "Some relevant information is included.",
            ],
            QualityLevel::Poor => vec![
                "This is about the topic.",
                "Some things are discussed.",
                "There are several points.",
            ],
            QualityLevel::VeryPoor => vec![
                "This is the answer.",
                "It talks about stuff.",
                "Things happen.",
            ],
        };

        let mut result = String::new();
        let mut word_count = 0;

        while word_count < words {
            let sentence = sentences[self.rng.gen_range(0..sentences.len())];
            result.push(' ');
            result.push_str(sentence);
            word_count += sentence.split_whitespace().count();
        }

        result
    }

    /// Get content templates for a module and question
    fn get_content_templates(&self, module: &str, _question: u32) -> Vec<String> {
        match module {
            "TM112" => vec![
                "Question: Explain the key differences between compiled and interpreted languages.\n\nAnswer: ".to_string(),
                "Question: Discuss operating system resource management.\n\nAnswer: ".to_string(),
            ],
            "M250" => vec![
                "Question: Implement a binary search algorithm in Java.\n\nAnswer: ".to_string(),
                "Question: Explain object-oriented principles.\n\nAnswer: ".to_string(),
            ],
            _ => vec!["Question: Generic question.\n\nAnswer: ".to_string()],
        }
    }

    /// Generate a random module code
    fn random_module(&mut self) -> String {
        let modules = ["TM112", "M250", "M269", "TM351", "TM470"];
        modules[self.rng.gen_range(0..modules.len())].to_string()
    }

    /// Generate a random ID with prefix
    fn random_id(&mut self, prefix: &str) -> String {
        let suffix: String = (0..6)
            .map(|_| self.rng.sample(Alphanumeric) as char)
            .collect();
        format!("{}-{}", prefix, suffix)
    }

    /// Generate a batch of TMAs with varying quality
    pub fn generate_batch(&mut self, count: usize) -> Vec<GeneratedTMA> {
        let qualities = [
            QualityLevel::Excellent,
            QualityLevel::Good,
            QualityLevel::Satisfactory,
            QualityLevel::Poor,
            QualityLevel::VeryPoor,
        ];

        (0..count)
            .map(|_| {
                let quality = qualities[self.rng.gen_range(0..qualities.len())];
                self.generate_tma(quality)
            })
            .collect()
    }
}

/// Rubric Generator
pub struct RubricGenerator {
    rng: StdRng,
}

impl RubricGenerator {
    pub fn new() -> Self {
        Self {
            rng: StdRng::from_entropy(),
        }
    }

    pub fn with_seed(seed: u64) -> Self {
        Self {
            rng: StdRng::seed_from_u64(seed),
        }
    }

    /// Generate a random rubric
    pub fn generate_rubric(&mut self, module: &str, question_number: u32) -> GeneratedRubric {
        let question_id = format!("{}_q{}", module.to_lowercase(), question_number);
        let num_criteria = self.rng.gen_range(3..8);

        let criteria = self.generate_criteria(num_criteria);
        let total_points: u32 = criteria.iter().map(|c| c.max_score).sum();

        GeneratedRubric {
            question_id,
            module: module.to_string(),
            title: format!("Question {} Rubric", question_number),
            total_points,
            criteria,
        }
    }

    /// Generate rubric criteria
    fn generate_criteria(&mut self, count: usize) -> Vec<RubricCriterion> {
        let criterion_names = [
            "Content Understanding",
            "Technical Accuracy",
            "Examples and Evidence",
            "Analysis and Critical Thinking",
            "Structure and Clarity",
            "Code Quality",
            "Testing Coverage",
        ];

        (0..count)
            .map(|i| {
                let name = criterion_names[i % criterion_names.len()].to_string();
                let weight = self.rng.gen_range(10..30);

                RubricCriterion {
                    name: name.clone(),
                    weight,
                    description: format!("Evaluates {}", name.to_lowercase()),
                    max_score: weight,
                }
            })
            .collect()
    }
}

/// Student Generator
pub struct StudentGenerator {
    rng: StdRng,
}

impl StudentGenerator {
    pub fn new() -> Self {
        Self {
            rng: StdRng::from_entropy(),
        }
    }

    pub fn with_seed(seed: u64) -> Self {
        Self {
            rng: StdRng::seed_from_u64(seed),
        }
    }

    /// Generate a random student
    pub fn generate_student(&mut self) -> GeneratedStudent {
        let student_id = format!("S{:06}", self.rng.gen_range(100000..999999));
        let anonymous_id = format!("ANON-{}", self.random_hex(8));

        let modules = ["TM112", "M250", "M269", "TM351", "TM470"];
        let num_modules = self.rng.gen_range(1..=3);
        let enrolled_modules: Vec<String> = (0..num_modules)
            .map(|_| modules[self.rng.gen_range(0..modules.len())].to_string())
            .collect();

        let performance_levels = ["high", "medium", "low"];
        let performance_level = performance_levels[self.rng.gen_range(0..performance_levels.len())].to_string();

        GeneratedStudent {
            student_id,
            anonymous_id,
            enrolled_modules,
            performance_level,
        }
    }

    /// Generate a batch of students
    pub fn generate_batch(&mut self, count: usize) -> Vec<GeneratedStudent> {
        (0..count).map(|_| self.generate_student()).collect()
    }

    fn random_hex(&mut self, length: usize) -> String {
        (0..length)
            .map(|_| format!("{:x}", self.rng.gen_range(0..16)))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tma_generator() {
        let mut gen = TMAGenerator::with_seed(42);
        let tma = gen.generate_tma(QualityLevel::Excellent);

        assert!(!tma.submission_id.is_empty());
        assert!(!tma.content.is_empty());
        assert!(tma.word_count > 0);
    }

    #[test]
    fn test_tma_batch_generation() {
        let mut gen = TMAGenerator::with_seed(42);
        let batch = gen.generate_batch(10);

        assert_eq!(batch.len(), 10);
        for tma in batch {
            assert!(tma.word_count > 0);
        }
    }

    #[test]
    fn test_rubric_generator() {
        let mut gen = RubricGenerator::with_seed(42);
        let rubric = gen.generate_rubric("TM112", 1);

        assert_eq!(rubric.module, "TM112");
        assert!(!rubric.criteria.is_empty());
        assert!(rubric.total_points > 0);
    }

    #[test]
    fn test_student_generator() {
        let mut gen = StudentGenerator::with_seed(42);
        let student = gen.generate_student();

        assert!(student.student_id.starts_with("S"));
        assert!(student.anonymous_id.starts_with("ANON-"));
        assert!(!student.enrolled_modules.is_empty());
    }

    #[test]
    fn test_deterministic_generation() {
        let mut gen1 = TMAGenerator::with_seed(12345);
        let mut gen2 = TMAGenerator::with_seed(12345);

        let tma1 = gen1.generate_tma(QualityLevel::Good);
        let tma2 = gen2.generate_tma(QualityLevel::Good);

        assert_eq!(tma1.word_count, tma2.word_count);
    }

    #[test]
    fn test_quality_level_word_counts() {
        let mut gen = TMAGenerator::with_seed(42);

        let excellent = gen.generate_tma(QualityLevel::Excellent);
        let poor = gen.generate_tma(QualityLevel::Poor);

        // Excellent should generally have more words
        assert!(excellent.word_count > 400);
        assert!(poor.word_count < 400);
    }
}
