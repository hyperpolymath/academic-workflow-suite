# Academic Workflow Suite - Blackboard Integration

Integration stub for Blackboard Learn LMS.

## Overview

This integration enables automated marking of Blackboard assignments using the Academic Workflow API.

## Architecture

The integration can be implemented as:

1. **Building Block** - Native Blackboard extension
2. **REST API Integration** - Using Blackboard's REST API
3. **LTI Tool** - LTI 1.3 external tool

## Building Block Approach

### Prerequisites

- Blackboard Learn 9.1 or higher
- Java Development Kit 8 or higher
- Blackboard Building Blocks SDK

### Structure

```
blackboard-awap-block/
├── src/
│   └── java/
│       └── com/
│           └── awap/
│               ├── AwapClient.java
│               ├── GradeServlet.java
│               └── SubmissionProcessor.java
├── webapp/
│   ├── WEB-INF/
│   │   ├── bb-manifest.xml
│   │   └── web.xml
│   └── config.jsp
└── build.xml
```

### bb-manifest.xml Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <plugin>
    <name value="Academic Workflow Suite"/>
    <handle value="awap"/>
    <description value="Automated marking integration"/>
    <version value="1.0.0"/>
    <requires>
      <bbversion value="3800.0.0"/>
    </requires>
    <vendor>
      <id value="awap"/>
      <name value="Academic Workflow Suite"/>
      <url value="https://academic-workflow-suite.example"/>
    </vendor>
  </plugin>
</manifest>
```

### Java Client Example

```java
package com.awap;

import java.io.*;
import java.net.*;
import org.json.*;

public class AwapClient {
    private String apiUrl;
    private int timeout;

    public AwapClient(String apiUrl) {
        this.apiUrl = apiUrl;
        this.timeout = 300000; // 5 minutes
    }

    public JSONObject uploadTMA(File file, String studentId, String rubric)
        throws IOException {
        // Implementation
        return new JSONObject();
    }

    public JSONObject submitForMarking(String tmaId, String rubric)
        throws IOException {
        // Implementation
        return new JSONObject();
    }

    public JSONObject getResults(String tmaId) throws IOException {
        // Implementation
        return new JSONObject();
    }
}
```

## REST API Integration

### Using Blackboard REST API

```python
import requests
from blackboard import BlackboardClient

# Initialize Blackboard client
bb_client = BlackboardClient(
    base_url='https://blackboard.example.com',
    client_id='your_client_id',
    client_secret='your_client_secret'
)

# Get course assignments
assignments = bb_client.get_assignments(course_id)

# Process submissions
for assignment in assignments:
    submissions = bb_client.get_submissions(assignment.id)

    for submission in submissions:
        # Download submission file
        file_path = bb_client.download_submission_file(submission)

        # Submit to AWAP
        results = awap_client.mark_tma(
            file_path=file_path,
            student_id=submission.user_id,
            rubric='default'
        )

        # Update grade in Blackboard
        bb_client.update_grade(
            assignment.id,
            submission.user_id,
            score=results.score,
            feedback=format_feedback(results)
        )
```

## LTI 1.3 Integration

### Tool Configuration

```json
{
  "title": "Academic Workflow Suite",
  "description": "Automated marking and feedback",
  "oidc_initiation_url": "https://your-awap.com/lti/oidc",
  "target_link_uri": "https://your-awap.com/lti/launch",
  "scopes": [
    "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
    "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly",
    "https://purl.imsglobal.org/spec/lti-ags/scope/score"
  ],
  "custom_parameters": {
    "rubric": "$ResourceLink.title"
  }
}
```

### Grade Passback

```python
from pylti1p3.grade_passback import GradePassback

def send_grade(launch_data, score, comment):
    grade_passback = GradePassback(launch_data)

    grade_passback.put_grade(
        score=score,
        comment=comment,
        timestamp=datetime.now().isoformat()
    )
```

## Configuration

### Environment Variables

```bash
export AWAP_API_URL="http://localhost:8080"
export AWAP_API_KEY="your_api_key"
export BB_BASE_URL="https://blackboard.example.com"
export BB_CLIENT_ID="your_client_id"
export BB_CLIENT_SECRET="your_client_secret"
```

### Configuration File

```xml
<!-- config.xml -->
<config>
  <awap>
    <apiUrl>http://localhost:8080</apiUrl>
    <timeout>300</timeout>
    <defaultRubric>default</defaultRubric>
  </awap>
  <blackboard>
    <baseUrl>https://blackboard.example.com</baseUrl>
    <autoGrade>true</autoGrade>
  </blackboard>
</config>
```

## Deployment

### Building Block Deployment

1. Package the building block:
   ```bash
   ant build
   ```

2. Upload to Blackboard:
   - Navigate to **System Admin → Building Blocks → Building Blocks**
   - Click **Upload Building Block**
   - Select the `.war` file
   - Set to **Available**

3. Configure:
   - Navigate to **System Admin → Building Blocks → Installed Tools**
   - Find "Academic Workflow Suite"
   - Click **Settings**
   - Enter API URL and credentials

## Grade Mapping

Blackboard uses various grading schemas. The integration supports:

- **Points**: Direct score mapping (0-100 → 0-points_possible)
- **Percentage**: Direct percentage (0-100%)
- **Letter**: Configurable mapping (A, B, C, etc.)
- **Complete/Incomplete**: Pass/fail threshold

## Feedback Format

Feedback is formatted as HTML for Blackboard:

```html
<h2>Automated Feedback</h2>
<p><strong>Score:</strong> 85/100</p>
<p><strong>Grade:</strong> B+</p>

<h3>Summary</h3>
<p>Good work overall...</p>

<h3>Strengths</h3>
<ul>
  <li>Clear thesis statement</li>
  <li>Good use of examples</li>
</ul>

<h3>Areas for Improvement</h3>
<ul>
  <li>Citation formatting needs work</li>
  <li>Conclusion could be stronger</li>
</ul>
```

## Support

For implementation assistance:

- Blackboard Developer Documentation: https://developer.blackboard.com
- AWAP Documentation: https://docs.academic-workflow-suite.example

## License

MIT
