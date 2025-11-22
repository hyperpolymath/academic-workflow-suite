# Academic Workflow Suite - Moodle Plugin

This plugin integrates the Academic Workflow Suite with Moodle, enabling automated marking of student submissions.

## Features

- Automatic submission of assignment files to AWAP API
- Retrieval of automated marking results
- Application of grades and feedback to Moodle assignments
- Support for custom rubrics
- Batch processing capabilities

## Installation

1. Copy the plugin to your Moodle installation:
   ```bash
   cp -r local_awap /path/to/moodle/local/
   ```

2. Log in to Moodle as an administrator

3. Navigate to **Site administration → Notifications**

4. Complete the plugin installation

## Configuration

1. Navigate to **Site administration → Plugins → Local plugins → Academic Workflow Suite**

2. Configure the following settings:
   - **API URL**: URL of your AWAP API (e.g., `http://localhost:8080`)
   - **API Key**: Your AWAP API key (if required)
   - **Default Rubric**: Default rubric to use for marking
   - **Timeout**: Request timeout in seconds (default: 300)

## Usage

### Programmatic Usage

```php
// Process a submission
$results = local_awap_process_submission($submission, 'default');

// Apply grade to assignment
local_awap_apply_grade($assignment_id, $user_id, $results);
```

### Using the API Client

```php
// Create client
$client = new local_awap_client('http://localhost:8080');

// Upload TMA
$upload_result = $client->upload_tma(
    '/path/to/essay.pdf',
    'student001',
    'default'
);

// Submit for marking
$mark_result = $client->submit_for_marking(
    $upload_result['tma_id'],
    'default'
);

// Wait for completion
$client->wait_for_completion($mark_result['job_id']);

// Get results
$results = $client->get_results($upload_result['tma_id']);

print_r($results);
```

### Batch Processing

To process multiple submissions at once:

```php
global $DB;

// Get all ungraded submissions for an assignment
$submissions = $DB->get_records('assign_submission', [
    'assignment' => $assignment_id,
    'status' => 'submitted'
]);

foreach ($submissions as $submission) {
    try {
        // Process submission
        $results = local_awap_process_submission($submission, 'default');

        // Apply grade
        local_awap_apply_grade(
            $assignment_id,
            $submission->userid,
            $results
        );

        echo "Processed submission for user {$submission->userid}\n";

    } catch (Exception $e) {
        echo "Error processing submission: {$e->getMessage()}\n";
    }
}
```

## Automated Task

You can set up a scheduled task to automatically process new submissions:

1. Create a file `classes/task/process_submissions.php`:

```php
<?php
namespace local_awap\task;

class process_submissions extends \core\task\scheduled_task {
    public function get_name() {
        return get_string('processsubmissions', 'local_awap');
    }

    public function execute() {
        // Implementation here
    }
}
```

2. Register the task in `db/tasks.php`

3. Configure the schedule in **Site administration → Server → Scheduled tasks**

## Grade Mapping

The plugin converts AWAP percentage scores to Moodle grades:

```
AWAP Score (0-100) → Moodle Grade (0-assignment_max_grade)
```

For example, if an assignment has a maximum grade of 50:
- AWAP score of 85% → Moodle grade of 42.5

## Feedback Format

Feedback is formatted in Markdown and includes:

- Overall score and grade
- Feedback summary
- Strengths (bulleted list)
- Areas for improvement (bulleted list)
- Detailed comments

## Troubleshooting

### Connection Issues

If you're having trouble connecting to the API:

1. Verify the API URL is correct
2. Check firewall settings
3. Ensure the API is running and accessible
4. Check Moodle error logs: `admin/reports/logs/`

### Timeout Errors

If marking jobs are timing out:

1. Increase the timeout setting
2. Check API performance
3. Consider processing submissions in smaller batches

### Permission Errors

Ensure the Moodle user has appropriate permissions:

- `mod/assign:grade` - Required to set grades
- `mod/assign:viewgrades` - Required to view submissions

## API Reference

See the [main API documentation](../../../docs/api.md) for complete API details.

## Support

For issues or questions:

- GitHub Issues: https://github.com/academic-workflow-suite/moodle-plugin
- Documentation: https://docs.academic-workflow-suite.example

## License

GPL v3 or later (compatible with Moodle)
