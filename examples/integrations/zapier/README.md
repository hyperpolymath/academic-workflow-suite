# Academic Workflow Suite - Zapier Integration

Automate your TMA marking workflow using Zapier.

## Overview

This integration allows you to connect the Academic Workflow Suite with 5000+ apps through Zapier, enabling automated workflows for submission processing, grading, and feedback delivery.

## Common Workflows

### 1. Google Drive → AWAP → Email

When a student uploads to Google Drive, automatically mark and email feedback.

**Trigger:** New File in Google Drive
**Actions:**
1. Mark TMA with AWAP
2. Wait for completion (5 min delay)
3. Get results
4. Send email with feedback

### 2. Moodle → AWAP → Google Sheets

Track all submissions and grades in a spreadsheet.

**Trigger:** New Moodle Assignment Submission (webhook)
**Actions:**
1. Download submission file
2. Mark TMA with AWAP
3. Get results
4. Add row to Google Sheets with score and feedback

### 3. Dropbox → AWAP → Slack

Get notifications when marking completes.

**Trigger:** New File in Dropbox
**Actions:**
1. Mark TMA with AWAP
2. Get results
3. Send Slack message to #grading channel

### 4. Email Attachment → AWAP → Airtable

Process submissions received via email.

**Trigger:** New Email with Attachment
**Actions:**
1. Extract PDF attachment
2. Mark TMA with AWAP
3. Get results
4. Create Airtable record with results

## Setup

### Prerequisites

- Zapier account (free or paid)
- Academic Workflow Suite API access
- API URL and credentials

### Creating a Zap

1. **Sign in to Zapier**
   - Go to https://zapier.com
   - Click "Create Zap"

2. **Configure Trigger**
   - Choose your trigger app (e.g., Google Drive, Dropbox, Email)
   - Select the trigger event (e.g., "New File")
   - Connect your account
   - Configure trigger settings

3. **Add AWAP Action - Mark TMA**
   - Click "+" to add an action
   - Search for "Webhooks by Zapier"
   - Choose "POST"
   - Configure:
     ```
     URL: https://your-api.com/api/v1/tma/upload
     Payload Type: Form
     Data:
       student_id: [from trigger]
       rubric: default
       file: [file from trigger]
     ```

4. **Add Delay**
   - Add "Delay by Zapier" action
   - Choose "Delay For" 5 minutes
   - This allows time for marking to complete

5. **Add AWAP Action - Get Results**
   - Add another Webhooks action
   - Choose "GET"
   - Configure:
     ```
     URL: https://your-api.com/api/v1/tma/[tma_id]/results
     ```

6. **Add Final Action**
   - Choose your destination (Email, Sheets, Slack, etc.)
   - Map the results fields to your destination

7. **Test and Enable**
   - Test each step
   - Turn on your Zap

## Webhook Configuration

### Setting Up Webhooks

To trigger Zaps from your LMS or application:

1. Get your Zapier webhook URL:
   - In your Zap, use "Webhooks by Zapier" as trigger
   - Choose "Catch Hook"
   - Copy the webhook URL

2. Configure your application to POST to this URL:
   ```bash
   curl -X POST https://hooks.zapier.com/hooks/catch/123456/abcdef/ \
     -H "Content-Type: application/json" \
     -d '{
       "student_id": "student001",
       "assignment_id": "essay_1",
       "file_url": "https://example.com/submission.pdf",
       "student_email": "student@example.com",
       "rubric": "default"
     }'
   ```

### Webhook Payload

Send this JSON structure:

```json
{
  "student_id": "student001",
  "assignment_id": "essay_1",
  "file_url": "https://example.com/submission.pdf",
  "student_email": "student@example.com",
  "student_name": "Jane Doe",
  "rubric": "default",
  "course_id": "CS101",
  "assignment_name": "Essay Assignment 1"
}
```

## Example Zaps

### Example 1: Email Feedback

```
Trigger: New file in Google Drive folder "Submissions"
Filter: Only continue if filename ends with .pdf
Action 1: HTTP POST to upload TMA
Action 2: Delay 5 minutes
Action 3: HTTP GET to retrieve results
Action 4: Send email via Gmail
  To: Student email (from filename or metadata)
  Subject: Your assignment feedback
  Body: Score: {{score}}, Grade: {{grade}}
        Summary: {{feedback.summary}}
```

### Example 2: Update Spreadsheet

```
Trigger: Webhook (from your LMS)
Action 1: Download file from URL
Action 2: HTTP POST to upload TMA
Action 3: Delay 5 minutes
Action 4: HTTP GET to retrieve results
Action 5: Add row to Google Sheets
  Columns: Student ID, Score, Grade, Timestamp
```

### Example 3: Slack Notification

```
Trigger: New file in Dropbox
Action 1: HTTP POST to upload TMA
Action 2: Delay 5 minutes
Action 3: HTTP GET to retrieve results
Action 4: Send Slack message
  Channel: #grading
  Message: New submission graded!
           Student: {{student_id}}
           Score: {{score}}
           Grade: {{grade}}
```

## Advanced Features

### Multi-Path Workflows

Create different paths based on grade:

```
1. Mark TMA
2. Get Results
3. Filter by Zapier
   - Path A (Grade >= B): Send congratulations email
   - Path B (Grade < B): Send improvement resources email
```

### Error Handling

Add error notifications:

```
1. Mark TMA
2. Only continue if...
   - Status code is 200
3. If error:
   - Send Slack alert to admin
   - Create Trello card for manual review
```

### Batch Processing

Use Zapier's "Looping by Zapier" for batch operations:

```
1. New row in Google Sheets (with multiple student IDs)
2. Loop through each student
3. For each: Mark TMA, get results, update sheet
```

## Cost Optimization

### Tips for Free Plans

- Use "Filter by Zapier" to prevent unnecessary runs
- Combine multiple actions in single API calls
- Use scheduled triggers instead of instant where appropriate

### Upgrading Triggers

Free plans limit to 100 tasks/month. To scale:

- Upgrade to Starter ($19.99/mo) for 750 tasks
- Use webhooks efficiently
- Batch operations where possible

## Troubleshooting

### Common Issues

**Issue:** Zap times out before marking completes
**Solution:** Increase delay time or use webhooks for completion notification

**Issue:** File upload fails
**Solution:** Ensure file URL is publicly accessible or use Zapier's file download action first

**Issue:** Results not found
**Solution:** Check TMA ID is correctly passed between steps

### Testing

Test each step individually:

1. Click "Test" after configuring each action
2. Check the output data
3. Verify API responses are as expected
4. Use Zapier's "Task History" to debug failures

## Support

- Zapier Help: https://help.zapier.com
- AWAP Docs: https://docs.academic-workflow-suite.example

## See Also

- [API Documentation](../../../docs/api.md)
- [n8n Integration](../n8n/) (self-hosted alternative)
