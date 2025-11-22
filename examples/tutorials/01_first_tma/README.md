# Tutorial 1: Your First TMA

Learn how to mark your first TMA using the Academic Workflow Suite.

## Prerequisites

- Academic Workflow Suite API running
- A sample TMA PDF file
- Basic command line knowledge

## Step 1: Prepare Your TMA File

Create or download a sample TMA PDF file. For testing, you can use any PDF document.

```bash
# Example: Download a sample PDF (optional)
wget https://example.com/sample-essay.pdf -O my_first_tma.pdf
```

## Step 2: Set API URL

Set the API URL environment variable:

```bash
export AWS_API_URL="http://localhost:8080"
```

## Step 3: Upload and Mark

### Using Bash

```bash
curl -X POST "$AWS_API_URL/api/v1/tma/upload" \
  -F "file=@my_first_tma.pdf" \
  -F "student_id=student001" \
  -F "rubric=default"
```

### Using Python

```python
import requests

with open('my_first_tma.pdf', 'rb') as f:
    response = requests.post(
        'http://localhost:8080/api/v1/tma/upload',
        files={'file': f},
        data={
            'student_id': 'student001',
            'rubric': 'default'
        }
    )

print(response.json())
```

## Step 4: Check Results

Wait a few minutes, then retrieve results:

```bash
TMA_ID="<your-tma-id>"
curl "$AWS_API_URL/api/v1/tma/$TMA_ID/results"
```

## Expected Output

```json
{
  "tma_id": "tma_123456",
  "student_id": "student001",
  "score": 85,
  "grade": "B+",
  "feedback": {
    "summary": "Good work overall...",
    "strengths": ["Clear thesis", "Good examples"],
    "areas_for_improvement": ["Citations need work"]
  }
}
```

## Next Steps

- [Tutorial 2: Creating Custom Rubrics](../02_custom_rubric/)
- [Tutorial 3: Batch Processing](../03_batch_processing/)
