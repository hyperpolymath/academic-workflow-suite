# AWAP Python SDK

Python SDK for the Academic Workflow API.

## Installation

```bash
pip install -e .
```

Or for development:

```bash
pip install -e ".[dev]"
```

## Quick Start

```python
from awap_sdk import AwapClient

# Create client
client = AwapClient(api_url="http://localhost:8080")

# Mark a TMA (one-liner)
result = client.mark_tma(
    file_path="essay.pdf",
    student_id="student001",
    rubric="default"
)

print(f"Score: {result.score}")
print(f"Grade: {result.grade}")
print(f"Summary: {result.feedback.summary}")
```

## Advanced Usage

### Step-by-step marking

```python
from awap_sdk import AwapClient

client = AwapClient()

# Step 1: Upload TMA
tma_id = client.upload_tma(
    file_path="essay.pdf",
    student_id="student001",
    rubric="default"
)

# Step 2: Submit for marking
job_id = client.submit_for_marking(tma_id, rubric="default")

# Step 3: Wait for completion
client.wait_for_completion(job_id)

# Step 4: Get results
result = client.get_results(tma_id)
```

### Configuration

```python
client = AwapClient(
    api_url="https://api.example.com",
    timeout=600,  # 10 minutes
    verify_ssl=True
)
```

### Error Handling

```python
from awap_sdk import AwapClient, AwapError, AwapAPIError, AwapTimeoutError

client = AwapClient()

try:
    result = client.mark_tma("essay.pdf", "student001")
except AwapAPIError as e:
    print(f"API Error (status {e.status_code}): {e}")
except AwapTimeoutError as e:
    print(f"Timeout: {e}")
except AwapError as e:
    print(f"Error: {e}")
```

## Examples

See the `examples/` directory for complete working examples:

- `mark_tma.py` - Basic marking example

## API Reference

### AwapClient

Main client class for interacting with the API.

#### Methods

- `upload_tma(file_path, student_id, rubric)` - Upload a TMA file
- `submit_for_marking(tma_id, rubric, auto_feedback)` - Submit for marking
- `get_job_status(job_id)` - Get job status
- `wait_for_completion(job_id, poll_interval, timeout)` - Wait for job to complete
- `get_results(tma_id)` - Get marking results
- `mark_tma(file_path, student_id, rubric, wait)` - Convenience method (all-in-one)

### Data Classes

#### MarkingResult

Represents marking results:
- `tma_id` - TMA identifier
- `student_id` - Student identifier
- `score` - Numerical score
- `grade` - Letter grade
- `feedback` - Feedback object
- `marked_at` - Timestamp

#### Feedback

Represents feedback:
- `summary` - Overall feedback summary
- `strengths` - List of strengths
- `areas_for_improvement` - List of areas to improve
- `detailed_comments` - Detailed comments

## License

MIT
