# Academic Workflow Suite - Canvas LMS Integration

Integration for Canvas LMS to enable automated marking of student submissions.

## Overview

This integration allows Canvas instructors to automatically submit student work to the Academic Workflow API for marking and feedback.

## Installation

1. Install required dependencies:
   ```bash
   gem install httparty
   ```

2. Add the integration to your Canvas installation:
   ```bash
   cp awap_integration.rb /path/to/canvas/lib/
   ```

3. Configure the API URL:
   ```bash
   export AWAP_API_URL="http://localhost:8080"
   ```

## Usage

### Process a Single Submission

```ruby
require_relative 'awap_integration'

client = AWAP::CanvasClient.new(api_url: 'http://localhost:8080')

# Process submission
results = client.process_canvas_submission(submission, rubric: 'essay')

# Apply grade to Canvas
client.apply_grade_to_canvas(assignment, user.id, results)
```

### Batch Process Submissions

```ruby
assignment.submissions.each do |submission|
  next unless submission.submitted?
  next if submission.graded?

  begin
    results = client.process_canvas_submission(submission, rubric: 'essay')
    client.apply_grade_to_canvas(assignment, submission.user_id, results)

    puts "Processed submission for user #{submission.user_id}"
  rescue => e
    puts "Error processing submission: #{e.message}"
  end
end
```

## Canvas External Tool Configuration

To add AWAP as an external tool in Canvas:

1. Navigate to **Settings → Apps → View App Configurations**

2. Click **+ App**

3. Use these settings:
   - **Configuration Type**: Manual Entry
   - **Name**: Academic Workflow Suite
   - **Consumer Key**: (your key)
   - **Shared Secret**: (your secret)
   - **Launch URL**: `https://your-awap-instance.com/lti/launch`
   - **Privacy**: Public

## LTI Integration

For LTI (Learning Tools Interoperability) support, implement an LTI provider that:

1. Receives submission notifications from Canvas
2. Downloads the submission file
3. Submits to AWAP API
4. Returns results to Canvas via LTI Outcomes

Example LTI launch handler:

```ruby
post '/lti/launch' do
  # Validate LTI request
  authenticator = IMS::LTI::Services::MessageAuthenticator.new(
    request.url,
    request.params,
    ENV['LTI_SECRET']
  )

  unless authenticator.valid_signature?
    halt 401, "Invalid signature"
  end

  # Process the submission
  # ...
end
```

## Grade Passback

Use LTI Outcomes to send grades back to Canvas:

```ruby
def send_grade_to_canvas(outcome_url, source_id, score)
  provider = IMS::LTI::ToolProvider.new(
    ENV['LTI_KEY'],
    ENV['LTI_SECRET'],
    {}
  )

  provider.post_replace_result!(
    score: score,
    outcome_url: outcome_url,
    outcome_sourced_id: source_id
  )
end
```

## API Reference

See the [main API documentation](../../../docs/api.md) for complete details.

## Support

For issues or questions, visit the GitHub repository.
