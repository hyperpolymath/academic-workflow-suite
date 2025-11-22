# Academic Workflow Suite - Test Data Documentation

This directory contains comprehensive test data, fixtures, and testing utilities for the Academic Workflow Suite. All test data is **fictional and anonymized** to protect privacy while providing realistic testing scenarios.

## Table of Contents

- [Directory Structure](#directory-structure)
- [Test Fixtures](#test-fixtures)
- [Test Data Generators](#test-data-generators)
- [Integration Tests](#integration-tests)
- [Performance Benchmarks](#performance-benchmarks)
- [Security Tests](#security-tests)
- [Usage Guide](#usage-guide)
- [Contributing](#contributing)

## Directory Structure

```
tests/
├── fixtures/                    # Static test data
│   ├── tmas/                   # Example TMA submissions
│   ├── rubrics/                # Grading rubrics
│   ├── feedback/               # Expected feedback examples
│   ├── students/               # Student data (anonymized)
│   └── modules/                # Module definitions
├── unit/                       # Unit test utilities
│   └── test_data.rs           # Rust test data generators
├── integration/                # Integration test scenarios
│   └── scenarios/             # Test scenario definitions
├── performance/               # Performance testing
│   └── benchmarks/           # Benchmark data files
├── ai-isolation/              # AI security tests
│   └── network-tests/        # Network isolation tests
└── README.md                  # This file
```

## Test Fixtures

### TMA Submissions (`fixtures/tmas/`)

Realistic Open University-style Tutor-Marked Assignment submissions at different quality levels:

#### TM112 (Introduction to Computing and Information Technology 2)
- **Question 1: Compiled vs Interpreted Languages**
  - `tm112_question1_excellent.txt` - High-quality answer (95+ marks)
  - `tm112_question1_good.txt` - Good answer (70-85 marks)
  - `tm112_question1_poor.txt` - Poor answer (<40 marks, failing)

- **Question 2: Operating System Resource Management**
  - `tm112_question2_excellent.txt` - Comprehensive answer
  - `tm112_question2_good.txt` - Solid answer

- **Question 3: Database Keys**
  - `tm112_question3_excellent.txt` - Primary/foreign keys explanation

- **Question 4: OSI Model**
  - `tm112_question4_excellent.txt` - Seven-layer model discussion

- **Question 5: AI Ethics**
  - `tm112_question5_excellent.txt` - Ethical implications discussion

#### M250 (Object-oriented Java Programming)
- **Question 1: Binary Search**
  - `m250_question1_excellent.txt` - Full implementation with analysis
  - `m250_question1_good.txt` - Good implementation
  - `m250_question1_poor.txt` - Incorrect implementation

- **Question 2: Stacks and Queues**
  - `m250_question2_excellent.txt` - Complete ADT explanation

### Grading Rubrics (`fixtures/rubrics/`)

Detailed YAML-format rubrics for automated grading:

- **`tm112_question1_rubric.yaml`** - Compiled vs interpreted languages
- **`tm112_question2_rubric.yaml`** - Operating system functions
- **`m250_question1_rubric.yaml`** - Binary search implementation
- **`generic_rubric_template.yaml`** - Template for creating new rubrics

#### Rubric Structure

```yaml
question_id: tm112_q1
module: TM112
title: "Question Title"
total_points: 100
word_limit: 500

criteria:
  - name: "Criterion Name"
    weight: 20
    description: "What this criterion evaluates"
    levels:
      - score: 20
        descriptor: "Excellent: ..."
      - score: 15
        descriptor: "Good: ..."
      # ... more levels

common_errors:
  - error: "Specific mistake pattern"
    penalty: 10

bonus_points:
  - description: "Extra credit for..."
    points: 5
```

### Expected Feedback (`fixtures/feedback/`)

Example feedback files showing different grade levels:

- **`tm112_q1_excellent_feedback.md`** - Detailed feedback for distinction-level work
- **`tm112_q1_good_feedback.md`** - Feedback for upper-second class work
- **`tm112_q1_poor_feedback.md`** - Constructive feedback for failing work

Each feedback file includes:
- Grade breakdown by criteria
- Strengths identified
- Areas for improvement
- Specific comments on content
- Next steps for student development

### Student Data (`fixtures/students/`)

Anonymized student records for testing:

#### `students.json`
- 12 fictional students
- Anonymous IDs (ANON-xxxxxxxx format)
- Module enrollments
- Performance levels
- Accessibility requirements

#### `student_submissions.json`
- Submission records
- Grading status tracking
- Timestamps
- Tutor assignments

**Privacy Notice:** All student data is completely fictional. No real student information is used.

### Module Definitions (`fixtures/modules/`)

#### `modules.yaml`
Open University module metadata:
- TM112: Introduction to Computing and IT 2
- M250: Object-oriented Java Programming
- M269: Algorithms and Data Structures
- TM351: Data Management and Analysis
- TM470: Computing Project

Each includes:
- Credits and level
- Topics covered
- Assessment structure
- Prerequisites

#### `assignment_schedules.yaml`
TMA schedules with:
- Due dates and cutoff dates
- Question details
- Word limits
- Weighting

## Test Data Generators

### Rust Generators (`unit/test_data.rs`)

Programmatic test data generation for property-based testing:

```rust
use test_data::{TMAGenerator, RubricGenerator, StudentGenerator, QualityLevel};

// Generate a random TMA
let mut gen = TMAGenerator::new();
let tma = gen.generate_tma(QualityLevel::Excellent);

// Generate batch
let batch = gen.generate_batch(100);

// Generate rubric
let mut rub_gen = RubricGenerator::new();
let rubric = rub_gen.generate_rubric("TM112", 1);

// Generate students
let mut stu_gen = StudentGenerator::new();
let student = stu_gen.generate_student();
```

#### Features:
- **Deterministic**: Use `with_seed()` for reproducible tests
- **Quality Levels**: Excellent, Good, Satisfactory, Poor, VeryPoor
- **Realistic Content**: Context-appropriate generated text
- **Batch Generation**: Create large test datasets

## Integration Tests

### Test Scenarios (`integration/scenarios/`)

Comprehensive YAML-based integration test scenarios:

#### `happy_path.yaml`
Complete successful marking workflow:
1. Student submits TMA
2. System loads rubric
3. AI grades submission
4. Feedback generated
5. Results published
6. Student views results

#### `error_recovery.yaml`
Error handling and resilience:
- AI service timeout recovery
- Invalid file format rejection
- Word count violation handling
- Database connection loss recovery
- Concurrent submission conflicts
- AI model failure fallback
- PII detection and protection

#### `batch_marking.yaml`
Batch processing scenarios:
- Small batch (10 submissions)
- Large batch (100 submissions)
- Mixed quality distributions
- Error handling in batches
- Priority queueing
- Resume after interruption

#### `concurrent_users.yaml`
Multi-user concurrency:
- Concurrent student submissions
- Parallel grading operations
- Read-write concurrency
- Database lock contention
- API rate limiting
- Session management
- Cache coherency
- Deadlock detection
- Resource exhaustion prevention

### Running Integration Tests

```bash
# Run all integration tests
./scripts/run-integration-tests.sh

# Run specific scenario
./scripts/run-integration-tests.sh happy_path

# With verbose output
./scripts/run-integration-tests.sh --verbose batch_marking
```

## Performance Benchmarks

### Benchmark Data (`performance/benchmarks/`)

Test files of varying sizes:

#### Individual TMAs
- **`small_tma.txt`** - 100 words
  - Quick processing test
  - Baseline performance

- **`medium_tma.txt`** - 500 words
  - Typical TMA size
  - Standard performance benchmark

- **`large_tma.txt`** - 2000 words
  - Long-form essay
  - Stress test for analysis

#### Batch Files
- **`batch_10.json`** - 10 submissions
  - Small batch processing
  - Target: <60 seconds total

- **`batch_100.json`** - 100 submissions
  - Large-scale processing
  - Target: <600 seconds total
  - Scalability test

### Performance Targets

| Test | Target Time | Throughput |
|------|-------------|------------|
| Small TMA | <3 seconds | N/A |
| Medium TMA | <6 seconds | N/A |
| Large TMA | <15 seconds | N/A |
| Batch 10 | <60 seconds | >10/min |
| Batch 100 | <600 seconds | >10/min |

### Running Benchmarks

```bash
# Run all benchmarks
./scripts/run-benchmarks.sh

# Run specific benchmark
./scripts/benchmark-tma-grading.sh small_tma.txt

# Run batch benchmark
./scripts/benchmark-batch.sh batch_100.json
```

## Security Tests

### AI Isolation Tests (`ai-isolation/network-tests/`)

Critical security tests for AI container isolation:

#### `network_isolation_test.sh`
Verifies AI container has no network access:
- ✓ External ping blocked
- ✓ DNS resolution blocked
- ✓ HTTP/HTTPS blocked
- ✓ TCP/UDP connections blocked
- ✓ Network mode is 'none'
- ✓ Only loopback interface present
- ✓ No default route configured

```bash
./tests/ai-isolation/network-tests/network_isolation_test.sh
```

#### `container_escape_test.sh`
Prevents container escape attacks:
- ✓ Container not privileged
- ✓ No dangerous capabilities
- ✓ Docker socket not exposed
- ✓ No dangerous mounts
- ✓ User namespacing active
- ✓ PID namespace isolated
- ✓ Resource limits configured

```bash
./tests/ai-isolation/network-tests/container_escape_test.sh
```

#### `pii_leakage_test.sh`
Protects Personally Identifiable Information:
- ✓ PII detected in submissions
- ✓ Student names anonymized
- ✓ Email addresses protected
- ✓ Student IDs anonymized
- ✓ Phone numbers redacted
- ✓ Addresses not in plain text
- ✓ Logs don't contain PII
- ✓ Feedback sanitized
- ✓ Exports anonymized
- ✓ Session data protected

```bash
./tests/ai-isolation/network-tests/pii_leakage_test.sh
```

### Security Test Exit Codes

- `0` - All tests passed (secure)
- `1` - Security issue detected (FAIL)
- `2` - Test setup error

## Usage Guide

### For Developers

#### Running All Tests

```bash
# From project root
cd tests

# Run unit tests
cargo test --test test_data

# Run integration tests
./run-integration-tests.sh

# Run security tests
./ai-isolation/network-tests/network_isolation_test.sh
./ai-isolation/network-tests/container_escape_test.sh
./ai-isolation/network-tests/pii_leakage_test.sh

# Run performance benchmarks
./run-benchmarks.sh
```

#### Using Test Fixtures in Code

**Python:**
```python
import json
import yaml

# Load student data
with open('tests/fixtures/students/students.json') as f:
    students = json.load(f)

# Load rubric
with open('tests/fixtures/rubrics/tm112_question1_rubric.yaml') as f:
    rubric = yaml.safe_load(f)

# Load TMA
with open('tests/fixtures/tmas/tm112_question1_excellent.txt') as f:
    tma_content = f.read()
```

**Rust:**
```rust
use std::fs;

// Load TMA
let tma = fs::read_to_string(
    "tests/fixtures/tmas/tm112_question1_excellent.txt"
)?;

// Generate test data
let mut gen = TMAGenerator::with_seed(42);
let test_tma = gen.generate_tma(QualityLevel::Good);
```

### For QA/Testing

#### Manual Testing Workflow

1. **Select Test Data**
   ```bash
   cd tests/fixtures/tmas
   ls -la
   ```

2. **Submit to System**
   - Use web interface or API
   - Upload selected TMA file
   - Note submission ID

3. **Verify Against Expected**
   - Compare grade with rubric expectations
   - Check feedback against examples
   - Validate processing time

4. **Run Security Tests**
   ```bash
   ./ai-isolation/network-tests/network_isolation_test.sh
   ```

#### Creating New Test Data

1. **TMA Submissions:**
   - Use existing files as templates
   - Follow naming convention: `{module}_question{n}_{quality}.txt`
   - Include word count at end

2. **Rubrics:**
   - Copy `generic_rubric_template.yaml`
   - Customize criteria and weights
   - Ensure weights sum to 100

3. **Add to Version Control:**
   ```bash
   git add tests/fixtures/
   git commit -m "Add test data for [module] [question]"
   ```

## Data Quality Standards

All test data must meet these standards:

### Realism
- ✓ Authentic OU-style questions and answers
- ✓ Realistic word counts and formatting
- ✓ Appropriate academic language
- ✓ Common student errors represented

### Privacy
- ✓ All data completely fictional
- ✓ No real student information
- ✓ Anonymous IDs used throughout
- ✓ GDPR-compliant by design

### Coverage
- ✓ Multiple quality levels (excellent to poor)
- ✓ Various modules and question types
- ✓ Edge cases and error conditions
- ✓ Performance test ranges

### Maintainability
- ✓ Clear file naming conventions
- ✓ Documented structure
- ✓ Version controlled
- ✓ Regular updates

## Test Data Versioning

Test data follows semantic versioning:

- **Major**: Breaking changes to data structure
- **Minor**: New test cases or fixtures added
- **Patch**: Corrections to existing data

Current version: **1.0.0**

## Contributing

### Adding New Test Data

1. Create fixtures in appropriate directory
2. Follow naming conventions
3. Include documentation in README
4. Add tests using new fixtures
5. Submit pull request with description

### Reporting Issues

If test data doesn't match real-world scenarios:

1. Open issue describing the problem
2. Provide real-world example (anonymized)
3. Suggest corrections
4. Update test data when approved

## License

Test data is licensed under the same terms as the main project (see LICENSE file).

## Questions?

For questions about test data:
- Check this README first
- Review example files
- Contact development team
- Open an issue on GitHub

---

**Last Updated:** 2024-11-22
**Test Data Version:** 1.0.0
**Total Test Files:** 50+
