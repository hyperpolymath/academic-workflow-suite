# Academic Workflow Suite - n8n Integration

Self-hosted automation workflow for TMA marking using n8n.

## Overview

n8n is an open-source workflow automation tool that you can self-host. This integration provides ready-to-use workflows for automating TMA marking and feedback delivery.

## Prerequisites

- n8n instance (self-hosted or cloud)
- Academic Workflow Suite API access
- SMTP server for email (optional)
- Google Sheets access (optional)

## Installation

### Option 1: n8n Cloud

1. Sign up at https://n8n.io
2. Import the workflow from `workflow.json`
3. Configure credentials

### Option 2: Self-Hosted

```bash
# Using Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD=password \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Using npm
npm install n8n -g
n8n start
```

### Option 3: Docker Compose

```yaml
# docker-compose.yml
version: '3'

services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=password
      - AWAP_API_URL=http://awap-api:8080
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  n8n_data:
```

## Workflow Setup

### 1. Import Workflow

1. Open n8n (http://localhost:5678)
2. Click "Import from File"
3. Select `workflow.json`
4. Click "Import"

### 2. Configure Environment Variables

Set these in n8n settings or environment:

```bash
AWAP_API_URL=http://localhost:8080
AWAP_API_KEY=your_api_key  # if required
```

### 3. Configure Credentials

Set up credentials for:

- **SMTP** (for email sending)
  - Host, port, username, password
- **Google Sheets** (if using)
  - OAuth2 credentials

### 4. Activate Workflow

Click the "Inactive" toggle to activate the workflow.

## Workflow Description

The workflow consists of these steps:

1. **Webhook Trigger** - Receives submission data
2. **Download File** - Downloads the submission file from URL
3. **Upload TMA** - Uploads to AWAP API
4. **Submit for Marking** - Initiates marking process
5. **Wait** - Waits 5 minutes for processing
6. **Check Status** - Checks if marking completed
7. **If Completed** - Conditional logic
   - If yes: Get results and proceed
   - If no: Wait 30 seconds and retry
8. **Get Results** - Fetches marking results
9. **Send Email** - Sends feedback to student
10. **Update Google Sheet** - Records result in spreadsheet
11. **Respond to Webhook** - Returns success response

## Usage

### Triggering the Workflow

Send a POST request to the webhook URL:

```bash
curl -X POST https://your-n8n.com/webhook/submission \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "student001",
    "student_email": "student@example.com",
    "file_url": "https://example.com/submission.pdf",
    "rubric": "default",
    "spreadsheet_id": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
  }'
```

### Expected Response

```json
{
  "status": "success",
  "score": 85,
  "grade": "B+"
}
```

## Workflow Variations

### Variation 1: Cron-Based Processing

Process submissions on a schedule:

```json
{
  "trigger": "Cron",
  "schedule": "0 */6 * * *",
  "action": "Check for new files in folder"
}
```

### Variation 2: Email Trigger

Process submissions received via email:

```json
{
  "trigger": "IMAP Email",
  "folder": "Submissions",
  "filter": "Has PDF attachment"
}
```

### Variation 3: Multi-Rubric Support

Different rubrics based on assignment type:

```json
{
  "IF": "assignment_type == 'essay'",
  "THEN": "rubric = 'essay_rubric'",
  "ELSE IF": "assignment_type == 'lab_report'",
  "THEN": "rubric = 'lab_rubric'"
}
```

## Advanced Features

### Error Handling

Add error notification:

```json
{
  "node": "Error Trigger",
  "on_error": "Send Slack notification",
  "message": "Marking failed for {{ $json.student_id }}"
}
```

### Parallel Processing

Process multiple submissions simultaneously:

```json
{
  "node": "Split In Batches",
  "batch_size": 10,
  "options": {
    "reset": false
  }
}
```

### Custom Notifications

Send notifications based on grade:

```json
{
  "IF": "$json.score >= 90",
  "THEN": "Send congratulations email",
  "ELSE IF": "$json.score < 50",
  "THEN": "Send support resources email"
}
```

## Monitoring

### Execution Log

View workflow executions:

1. Click "Executions" in left sidebar
2. View successful and failed runs
3. Inspect data for each node

### Webhooks

Monitor webhook calls:

```bash
# n8n webhook URL
https://your-n8n.com/webhook/submission

# Check webhook history
curl https://your-n8n.com/rest/executions?filter=webhook
```

## Performance Optimization

### Caching

Cache rubric data to reduce API calls:

```json
{
  "node": "Set",
  "keepOnlySet": false,
  "values": {
    "rubric_cache": "={{ $('HTTP Request').item.json }}"
  }
}
```

### Batch Operations

Process submissions in batches:

```json
{
  "node": "Loop Over Items",
  "batchSize": 10,
  "options": {
    "loopLimit": 100
  }
}
```

## Troubleshooting

### Common Issues

**Issue:** Webhook not receiving requests
**Solution:** Check firewall, ensure n8n is accessible, verify webhook URL

**Issue:** File download fails
**Solution:** Ensure file URL is publicly accessible or configure auth

**Issue:** Marking timeout
**Solution:** Increase wait time or add retry logic

### Debug Mode

Enable debug logging:

```bash
export N8N_LOG_LEVEL=debug
n8n start
```

## Integration Examples

### With Moodle

```javascript
// Moodle plugin sends webhook
const response = await fetch('https://your-n8n.com/webhook/submission', {
  method: 'POST',
  body: JSON.stringify({
    student_id: user.id,
    student_email: user.email,
    file_url: submission.fileUrl,
    rubric: assignment.rubric
  })
});
```

### With Google Classroom

```python
# Google Classroom script
import requests

def on_new_submission(submission):
    requests.post(
        'https://your-n8n.com/webhook/submission',
        json={
            'student_id': submission.userId,
            'student_email': get_user_email(submission.userId),
            'file_url': submission.attachments[0].driveFile.url,
            'rubric': 'default'
        }
    )
```

## Security

### Authentication

Secure the webhook with basic auth:

```json
{
  "node": "Webhook",
  "authentication": "basicAuth",
  "credentials": {
    "name": "webhook-auth"
  }
}
```

### API Key Validation

Validate API keys:

```json
{
  "IF": "$('Webhook').item.headers['x-api-key'] == '{{ $env.API_KEY }}'",
  "THEN": "Continue",
  "ELSE": "Return 401 Unauthorized"
}
```

## See Also

- [n8n Documentation](https://docs.n8n.io)
- [AWAP API Docs](../../../docs/api.md)
- [Zapier Integration](../zapier/) (cloud alternative)

## Support

For questions or issues:
- n8n Community: https://community.n8n.io
- AWAP Docs: https://docs.academic-workflow-suite.example
