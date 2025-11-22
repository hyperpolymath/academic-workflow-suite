# API Reference

**Complete REST API documentation for Academic Workflow Suite**

This document provides comprehensive API documentation for the AWS Core Engine REST API.

---

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Base URL](#base-url)
- [Common Headers](#common-headers)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Endpoints](#endpoints)
  - [Documents](#documents)
  - [Analysis](#analysis)
  - [Rubrics](#rubrics)
  - [Feedback](#feedback)
  - [Export](#export)
  - [Configuration](#configuration)
  - [Health & Metrics](#health--metrics)
- [Data Models](#data-models)
- [WebSocket API](#websocket-api-future)
- [Versioning](#versioning)
- [SDK Examples](#sdk-examples)

---

## Overview

The AWS Core Engine provides a RESTful HTTP API for the Office add-in and other clients.

**API Version**: 0.1.0
**Protocol**: HTTP/1.1, HTTP/2
**Data Format**: JSON
**Base URL**: `http://localhost:8080/api`

**Key Features**:
- RESTful design following industry standards
- JSON request/response bodies
- Standard HTTP status codes
- Comprehensive error messages
- Privacy-preserving (student IDs anonymized)

---

## Authentication

### Current Version (0.1.0)

**No authentication required** for localhost connections.

All API requests are accepted from `localhost` only. The server binds to `127.0.0.1:8080` and does not accept external connections.

### Future Versions

Authentication will be implemented using:
- **Local Token**: Auto-generated token stored in `~/.aws/token`
- **Bearer Authentication**: `Authorization: Bearer <token>`

---

## Base URL

All API endpoints are relative to:

```
http://localhost:8080/api
```

**Example**:
```
Full URL: http://localhost:8080/api/documents/load
```

---

## Common Headers

### Request Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Content-Type` | Yes | Must be `application/json` |
| `Accept` | No | Defaults to `application/json` |
| `X-Request-ID` | No | UUID for request tracing |
| `X-Client-Version` | Recommended | AWS Add-in version |

### Response Headers

| Header | Description |
|--------|-------------|
| `Content-Type` | Always `application/json` |
| `X-Request-ID` | Echo of request ID or generated UUID |
| `X-RateLimit-Remaining` | Remaining requests (future) |

---

## Error Handling

### Standard Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Student ID is required",
    "details": {
      "field": "student_id",
      "expected": "non-empty string"
    },
    "request_id": "550e8400-e29b-41d4-a716-446655440000",
    "timestamp": "2025-11-22T14:32:01Z"
  }
}
```

### HTTP Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| `200` | OK | Successful request |
| `201` | Created | Resource created |
| `400` | Bad Request | Invalid input |
| `404` | Not Found | Resource not found |
| `409` | Conflict | Resource already exists |
| `422` | Unprocessable Entity | Valid JSON but invalid data |
| `429` | Too Many Requests | Rate limit exceeded (future) |
| `500` | Internal Server Error | Server error |
| `503` | Service Unavailable | AI jail not ready |

### Error Codes

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Input validation failed |
| `NOT_FOUND` | Resource not found |
| `AI_TIMEOUT` | AI analysis timed out |
| `AI_JAIL_UNAVAILABLE` | AI jail not responding |
| `RUBRIC_NOT_FOUND` | Specified rubric doesn't exist |
| `DOCUMENT_ALREADY_EXISTS` | Document ID already in use |
| `INTERNAL_ERROR` | Unexpected server error |

---

## Rate Limiting

**Current Version**: No rate limiting

**Future Versions**: 100 requests per minute per client

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1637512800
```

---

## Endpoints

### Documents

#### Load Document

Load a TMA document for marking.

**Endpoint**: `POST /api/documents/load`

**Request**:

```json
{
  "student_id": "A1234567",
  "module": "TM112",
  "assignment": "TMA01",
  "content": "In this assignment, I will discuss...",
  "metadata": {
    "tutor_id": "T9876543",
    "submission_date": "2025-11-15T10:00:00Z"
  }
}
```

**Response**: `201 Created`

```json
{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "student_id_hash": "7f3a2b9c8e1d4a5c6f8b9e2d3c4a5b6c7d8e9f0a...",
  "module": "TM112",
  "assignment": "TMA01",
  "created_at": "2025-11-22T14:32:01Z",
  "privacy": {
    "student_id_anonymized": true,
    "hash_algorithm": "SHA3-512"
  }
}
```

**Errors**:
- `400`: Missing required fields
- `409`: Document already exists for this student/assignment

---

#### Get Document

Retrieve document details.

**Endpoint**: `GET /api/documents/{document_id}`

**Response**: `200 OK`

```json
{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "student_id_hash": "7f3a2b9c...",
  "module": "TM112",
  "assignment": "TMA01",
  "content": "In this assignment...",
  "status": "analyzed",
  "created_at": "2025-11-22T14:32:01Z",
  "updated_at": "2025-11-22T14:35:22Z",
  "analysis": {
    "completed_at": "2025-11-22T14:32:47Z",
    "total_score": 78.0,
    "grade": "B+"
  }
}
```

**Errors**:
- `404`: Document not found

---

#### List Documents

List all documents (with pagination).

**Endpoint**: `GET /api/documents`

**Query Parameters**:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `per_page` | integer | 20 | Items per page (max 100) |
| `module` | string | - | Filter by module |
| `assignment` | string | - | Filter by assignment |
| `status` | string | - | Filter by status |

**Response**: `200 OK`

```json
{
  "documents": [
    {
      "document_id": "550e8400-e29b-41d4-a716-446655440000",
      "module": "TM112",
      "assignment": "TMA01",
      "status": "analyzed",
      "created_at": "2025-11-22T14:32:01Z"
    },
    {
      "document_id": "660f9511-f30c-52e5-b827-557766551111",
      "module": "TM112",
      "assignment": "TMA01",
      "status": "pending",
      "created_at": "2025-11-22T15:10:15Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 45,
    "total_pages": 3
  }
}
```

---

### Analysis

#### Analyze Document

Analyze a document with AI.

**Endpoint**: `POST /api/analyze`

**Request**:

```json
{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "rubric_id": "123e4567-e89b-12d3-a456-426614174000",
  "options": {
    "timeout_ms": 30000,
    "model": "standard-v1"
  }
}
```

**Response**: `200 OK`

```json
{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "analysis_id": "789abc12-def3-4567-89ab-cdef01234567",
  "student_id_hash": "7f3a2b9c...",
  "suggestions": [
    {
      "criterion_id": "understanding",
      "criterion_name": "Understanding of Concepts",
      "max_score": 30.0,
      "suggested_score": 24.0,
      "confidence": 0.85,
      "feedback": "You demonstrate a solid understanding of networking fundamentals. Your explanation of TCP/IP is clear and accurate. To improve, consider expanding your discussion of how the OSI model relates to real-world protocols.",
      "strengths": [
        "Clear TCP/IP explanation",
        "Good use of examples"
      ],
      "areas_for_improvement": [
        "More depth on OSI model",
        "Real-world protocol mapping"
      ]
    },
    {
      "criterion_id": "analysis",
      "criterion_name": "Critical Analysis",
      "max_score": 30.0,
      "suggested_score": 22.0,
      "confidence": 0.78,
      "feedback": "Your critical analysis shows promise, particularly in comparing different networking approaches. However, you could strengthen your argument by providing more evidence to support your claims.",
      "strengths": [
        "Good comparison of approaches"
      ],
      "areas_for_improvement": [
        "More supporting evidence",
        "Deeper critical evaluation"
      ]
    },
    {
      "criterion_id": "structure",
      "criterion_name": "Structure & Clarity",
      "max_score": 20.0,
      "suggested_score": 17.0,
      "confidence": 0.92,
      "feedback": "Your essay is well-structured with clear sections and logical flow. Minor improvements could be made in transitions between paragraphs.",
      "strengths": [
        "Logical flow",
        "Clear sections"
      ],
      "areas_for_improvement": [
        "Smoother transitions"
      ]
    },
    {
      "criterion_id": "evidence",
      "criterion_name": "Use of Evidence",
      "max_score": 20.0,
      "suggested_score": 15.0,
      "confidence": 0.73,
      "feedback": "You use some relevant evidence, but more citations and references to course materials would strengthen your arguments.",
      "strengths": [
        "Relevant examples used"
      ],
      "areas_for_improvement": [
        "More citations",
        "Reference to course materials"
      ]
    }
  ],
  "summary": {
    "total_score": 78.0,
    "total_possible": 100.0,
    "percentage": 78.0,
    "grade": "B+",
    "overall_feedback": "A good submission showing solid understanding. Focus on deepening your critical analysis and providing more evidence to support your claims."
  },
  "metadata": {
    "duration_ms": 2847,
    "model_used": "standard-v1",
    "completed_at": "2025-11-22T14:32:47Z"
  },
  "privacy": {
    "student_id_anonymized": true,
    "ai_received_pii": false,
    "hash_algorithm": "SHA3-512"
  }
}
```

**Errors**:
- `404`: Document not found
- `404`: Rubric not found
- `422`: Document already analyzed
- `503`: AI jail unavailable
- `504`: AI analysis timeout

---

#### Get Analysis Status

Check the status of an ongoing analysis.

**Endpoint**: `GET /api/analysis/{analysis_id}/status`

**Response**: `200 OK`

```json
{
  "analysis_id": "789abc12-def3-4567-89ab-cdef01234567",
  "status": "in_progress",
  "progress": 0.65,
  "estimated_time_remaining_ms": 5000,
  "started_at": "2025-11-22T14:32:18Z"
}
```

**Status Values**:
- `queued`: Waiting to start
- `in_progress`: Currently analyzing
- `completed`: Analysis finished
- `failed`: Analysis failed

---

### Rubrics

#### List Rubrics

Get all available rubrics.

**Endpoint**: `GET /api/rubrics`

**Query Parameters**:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `module` | string | - | Filter by module |
| `assignment` | string | - | Filter by assignment |

**Response**: `200 OK`

```json
{
  "rubrics": [
    {
      "rubric_id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "TM112 TMA01 Official Rubric",
      "module": "TM112",
      "assignment": "TMA01",
      "version": "2.1",
      "total_marks": 100,
      "criteria_count": 4,
      "created_at": "2025-01-15T10:00:00Z",
      "updated_at": "2025-10-01T09:30:00Z"
    },
    {
      "rubric_id": "234f5678-f90c-23e4-b567-537725285111",
      "name": "M250 TMA02 Official Rubric",
      "module": "M250",
      "assignment": "TMA02",
      "version": "1.0",
      "total_marks": 100,
      "criteria_count": 5,
      "created_at": "2025-02-20T14:00:00Z",
      "updated_at": "2025-02-20T14:00:00Z"
    }
  ]
}
```

---

#### Get Rubric

Get detailed rubric information.

**Endpoint**: `GET /api/rubrics/{rubric_id}`

**Response**: `200 OK`

```json
{
  "rubric_id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "TM112 TMA01 Official Rubric",
  "module": "TM112",
  "assignment": "TMA01",
  "version": "2.1",
  "description": "Official marking rubric for TM112 TMA01",
  "total_marks": 100,
  "criteria": [
    {
      "criterion_id": "understanding",
      "name": "Understanding of Concepts",
      "description": "Demonstrates understanding of key networking concepts",
      "max_score": 30.0,
      "weight": 0.30,
      "levels": [
        {
          "level": "Excellent",
          "score_range": [27, 30],
          "description": "Comprehensive understanding with excellent examples"
        },
        {
          "level": "Good",
          "score_range": [24, 26],
          "description": "Solid understanding with good examples"
        },
        {
          "level": "Satisfactory",
          "score_range": [18, 23],
          "description": "Basic understanding with some gaps"
        },
        {
          "level": "Poor",
          "score_range": [0, 17],
          "description": "Limited understanding"
        }
      ]
    },
    {
      "criterion_id": "analysis",
      "name": "Critical Analysis",
      "description": "Critical evaluation of networking approaches",
      "max_score": 30.0,
      "weight": 0.30,
      "levels": [
        {
          "level": "Excellent",
          "score_range": [27, 30],
          "description": "Thorough critical analysis with well-supported arguments"
        },
        {
          "level": "Good",
          "score_range": [24, 26],
          "description": "Good analysis with some supporting evidence"
        },
        {
          "level": "Satisfactory",
          "score_range": [18, 23],
          "description": "Basic analysis, limited evidence"
        },
        {
          "level": "Poor",
          "score_range": [0, 17],
          "description": "Little or no critical analysis"
        }
      ]
    }
  ],
  "grade_boundaries": {
    "A+": 90,
    "A": 85,
    "B+": 75,
    "B": 70,
    "C+": 65,
    "C": 60,
    "D": 50,
    "F": 0
  },
  "created_by": "Module Coordinator",
  "created_at": "2025-01-15T10:00:00Z",
  "updated_at": "2025-10-01T09:30:00Z"
}
```

**Errors**:
- `404`: Rubric not found

---

#### Create Custom Rubric

Create a custom rubric.

**Endpoint**: `POST /api/rubrics`

**Request**:

```json
{
  "name": "Custom TM112 TMA01 Rubric",
  "module": "TM112",
  "assignment": "TMA01",
  "description": "Customized rubric with emphasis on practical examples",
  "criteria": [
    {
      "name": "Understanding of Concepts",
      "description": "Understanding of networking concepts",
      "max_score": 40.0,
      "weight": 0.40
    },
    {
      "name": "Practical Application",
      "description": "Application to real-world scenarios",
      "max_score": 60.0,
      "weight": 0.60
    }
  ]
}
```

**Response**: `201 Created`

```json
{
  "rubric_id": "345g6789-g01d-34f5-c678-648836396222",
  "name": "Custom TM112 TMA01 Rubric",
  "module": "TM112",
  "assignment": "TMA01",
  "version": "1.0",
  "created_at": "2025-11-22T14:40:00Z"
}
```

---

### Feedback

#### Edit Feedback

Edit AI-suggested feedback.

**Endpoint**: `POST /api/feedback/edit`

**Request**:

```json
{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "analysis_id": "789abc12-def3-4567-89ab-cdef01234567",
  "criterion_id": "understanding",
  "edits": {
    "feedback": "Excellent work! You demonstrate a comprehensive understanding of networking fundamentals. Your explanation of TCP/IP is particularly clear. Consider expanding your OSI model discussion.",
    "score": 25.0
  },
  "tutor_id": "T9876543"
}
```

**Response**: `200 OK`

```json
{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "criterion_id": "understanding",
  "original": {
    "feedback": "You demonstrate a solid understanding...",
    "score": 24.0
  },
  "edited": {
    "feedback": "Excellent work! You demonstrate a comprehensive understanding...",
    "score": 25.0
  },
  "edited_by": "T9876543",
  "edited_at": "2025-11-22T14:35:22Z"
}
```

---

#### Get Feedback History

Get edit history for feedback.

**Endpoint**: `GET /api/feedback/{document_id}/history`

**Response**: `200 OK`

```json
{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "history": [
    {
      "timestamp": "2025-11-22T14:32:47Z",
      "event": "ai_generated",
      "criterion_id": "understanding",
      "feedback": "You demonstrate a solid understanding...",
      "score": 24.0
    },
    {
      "timestamp": "2025-11-22T14:35:22Z",
      "event": "tutor_edited",
      "criterion_id": "understanding",
      "feedback": "Excellent work! You demonstrate...",
      "score": 25.0,
      "edited_by": "T9876543"
    }
  ]
}
```

---

### Export

#### Export Marked Document

Export a marked TMA.

**Endpoint**: `POST /api/export`

**Request**:

```json
{
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "format": "pdf",
  "options": {
    "include_rubric": true,
    "include_scores": true,
    "include_comments": true,
    "destination": "~/Documents/AWS-Exports/"
  }
}
```

**Response**: `200 OK`

```json
{
  "export_id": "456h7890-h12e-45g6-d789-759947407333",
  "document_id": "550e8400-e29b-41d4-a716-446655440000",
  "format": "pdf",
  "file_path": "/Users/tutor/Documents/AWS-Exports/TM112-TMA01-A1234567-marked.pdf",
  "file_size_bytes": 245678,
  "generated_at": "2025-11-22T14:36:32Z"
}
```

**Supported Formats**:
- `pdf`: PDF with embedded feedback
- `docx`: Word document with tracked changes
- `txt`: Plain text feedback only
- `json`: Structured data export

**Errors**:
- `404`: Document not found
- `422`: Document not analyzed yet

---

### Configuration

#### Get Configuration

Get current configuration.

**Endpoint**: `GET /api/config`

**Response**: `200 OK`

```json
{
  "version": "0.1.0",
  "ai": {
    "mode": "local",
    "model": "standard-v1",
    "timeout_ms": 30000
  },
  "privacy": {
    "hash_algorithm": "SHA3-512",
    "audit_enabled": true
  },
  "export": {
    "default_format": "pdf",
    "default_destination": "~/Documents/AWS-Exports/"
  }
}
```

---

#### Update Configuration

Update configuration settings.

**Endpoint**: `PATCH /api/config`

**Request**:

```json
{
  "ai": {
    "model": "fast-v1",
    "timeout_ms": 20000
  },
  "export": {
    "default_format": "docx"
  }
}
```

**Response**: `200 OK`

```json
{
  "updated": true,
  "config": {
    "version": "0.1.0",
    "ai": {
      "mode": "local",
      "model": "fast-v1",
      "timeout_ms": 20000
    },
    "export": {
      "default_format": "docx",
      "default_destination": "~/Documents/AWS-Exports/"
    }
  }
}
```

---

### Health & Metrics

#### Health Check

Check service health.

**Endpoint**: `GET /health`

**Response**: `200 OK`

```json
{
  "status": "healthy",
  "version": "0.1.0",
  "uptime_seconds": 3600,
  "components": {
    "core_engine": {
      "status": "healthy",
      "message": "Running"
    },
    "ai_jail": {
      "status": "healthy",
      "message": "Ready"
    },
    "event_store": {
      "status": "healthy",
      "total_events": 1234,
      "database_size_mb": 15.2
    }
  },
  "timestamp": "2025-11-22T14:40:00Z"
}
```

**Status Values**:
- `healthy`: All systems operational
- `degraded`: Some non-critical issues
- `unhealthy`: Critical issues

---

#### Metrics (Future)

Get Prometheus-compatible metrics.

**Endpoint**: `GET /metrics`

**Response**: `200 OK` (Plain text)

```
# HELP aws_requests_total Total number of API requests
# TYPE aws_requests_total counter
aws_requests_total{endpoint="/api/analyze",method="POST",status="200"} 45

# HELP aws_analysis_duration_seconds Time spent on AI analysis
# TYPE aws_analysis_duration_seconds histogram
aws_analysis_duration_seconds_bucket{le="10"} 5
aws_analysis_duration_seconds_bucket{le="20"} 25
aws_analysis_duration_seconds_bucket{le="30"} 40
aws_analysis_duration_seconds_bucket{le="+Inf"} 45
aws_analysis_duration_seconds_sum 987.5
aws_analysis_duration_seconds_count 45

# HELP aws_documents_total Total documents processed
# TYPE aws_documents_total counter
aws_documents_total{module="TM112",assignment="TMA01"} 23
aws_documents_total{module="M250",assignment="TMA02"} 12
```

---

## Data Models

### Document

```typescript
interface Document {
  document_id: string;          // UUID
  student_id_hash: string;      // SHA3-512 hash
  module: string;               // e.g., "TM112"
  assignment: string;           // e.g., "TMA01"
  content: string;              // Essay text
  status: DocumentStatus;
  created_at: string;           // ISO 8601 timestamp
  updated_at: string;
  metadata?: DocumentMetadata;
}

type DocumentStatus = "pending" | "analyzing" | "analyzed" | "exported";

interface DocumentMetadata {
  tutor_id?: string;
  submission_date?: string;
  word_count?: number;
  language?: string;
}
```

### Rubric

```typescript
interface Rubric {
  rubric_id: string;            // UUID
  name: string;
  module: string;
  assignment: string;
  version: string;
  description?: string;
  total_marks: number;
  criteria: Criterion[];
  grade_boundaries?: GradeBoundaries;
  created_by?: string;
  created_at: string;
  updated_at: string;
}

interface Criterion {
  criterion_id: string;
  name: string;
  description: string;
  max_score: number;
  weight: number;               // 0.0 to 1.0
  levels?: PerformanceLevel[];
}

interface PerformanceLevel {
  level: string;                // e.g., "Excellent"
  score_range: [number, number];
  description: string;
}

interface GradeBoundaries {
  [grade: string]: number;      // e.g., "A+": 90
}
```

### Analysis

```typescript
interface Analysis {
  document_id: string;
  analysis_id: string;
  student_id_hash: string;
  suggestions: Suggestion[];
  summary: AnalysisSummary;
  metadata: AnalysisMetadata;
  privacy: PrivacyInfo;
}

interface Suggestion {
  criterion_id: string;
  criterion_name: string;
  max_score: number;
  suggested_score: number;
  confidence: number;           // 0.0 to 1.0
  feedback: string;
  strengths: string[];
  areas_for_improvement: string[];
}

interface AnalysisSummary {
  total_score: number;
  total_possible: number;
  percentage: number;
  grade: string;
  overall_feedback: string;
}

interface AnalysisMetadata {
  duration_ms: number;
  model_used: string;
  completed_at: string;
}

interface PrivacyInfo {
  student_id_anonymized: boolean;
  ai_received_pii: boolean;
  hash_algorithm: string;
}
```

### Error

```typescript
interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: any;
    request_id: string;
    timestamp: string;
  };
}
```

---

## WebSocket API (Future)

Real-time updates for long-running operations.

**Endpoint**: `ws://localhost:8080/ws`

**Connection**:

```javascript
const ws = new WebSocket('ws://localhost:8080/ws');

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'subscribe',
    channels: ['analysis', 'exports']
  }));
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Received:', message);
};
```

**Message Types**:

```typescript
// Analysis progress
{
  type: "analysis_progress",
  analysis_id: "789abc12-def3-4567-89ab-cdef01234567",
  progress: 0.65,
  estimated_time_remaining_ms: 5000
}

// Analysis complete
{
  type: "analysis_complete",
  analysis_id: "789abc12-def3-4567-89ab-cdef01234567",
  document_id: "550e8400-e29b-41d4-a716-446655440000"
}

// Export complete
{
  type: "export_complete",
  export_id: "456h7890-h12e-45g6-d789-759947407333",
  file_path: "/Users/tutor/Documents/AWS-Exports/..."
}
```

---

## Versioning

### API Versioning Strategy

**Current**: Version embedded in base URL path (future: `/api/v1/...`)

**Current Version**: 0.1.0 (no version prefix required)

**Future Versions**:
- `/api/v1/...` - Stable API (1.x releases)
- `/api/v2/...` - Next major version

### Deprecation Policy

- Major versions supported for 12 months after new version release
- Deprecation warnings added 6 months before removal
- `X-API-Deprecated` header included in responses

---

## SDK Examples

### JavaScript/TypeScript

```typescript
import axios from 'axios';

const API_BASE = 'http://localhost:8080/api';

class AWSClient {
  async loadDocument(data: {
    student_id: string;
    module: string;
    assignment: string;
    content: string;
  }) {
    const response = await axios.post(`${API_BASE}/documents/load`, data);
    return response.data;
  }

  async analyzeDocument(documentId: string, rubricId: string) {
    const response = await axios.post(`${API_BASE}/analyze`, {
      document_id: documentId,
      rubric_id: rubricId
    });
    return response.data;
  }

  async editFeedback(
    documentId: string,
    analysisId: string,
    criterionId: string,
    edits: { feedback: string; score: number }
  ) {
    const response = await axios.post(`${API_BASE}/feedback/edit`, {
      document_id: documentId,
      analysis_id: analysisId,
      criterion_id: criterionId,
      edits
    });
    return response.data;
  }

  async exportDocument(documentId: string, format: string = 'pdf') {
    const response = await axios.post(`${API_BASE}/export`, {
      document_id: documentId,
      format
    });
    return response.data;
  }
}

// Usage
const client = new AWSClient();

const doc = await client.loadDocument({
  student_id: 'A1234567',
  module: 'TM112',
  assignment: 'TMA01',
  content: 'Essay text...'
});

const analysis = await client.analyzeDocument(
  doc.document_id,
  'rubric-id-here'
);

await client.editFeedback(
  doc.document_id,
  analysis.analysis_id,
  'understanding',
  {
    feedback: 'Excellent work!',
    score: 28.0
  }
);

const export_result = await client.exportDocument(doc.document_id, 'pdf');
console.log('Exported to:', export_result.file_path);
```

### Python

```python
import requests
from typing import Dict, Any

class AWSClient:
    def __init__(self, base_url: str = "http://localhost:8080/api"):
        self.base_url = base_url

    def load_document(self, student_id: str, module: str,
                     assignment: str, content: str) -> Dict[str, Any]:
        response = requests.post(
            f"{self.base_url}/documents/load",
            json={
                "student_id": student_id,
                "module": module,
                "assignment": assignment,
                "content": content
            }
        )
        response.raise_for_status()
        return response.json()

    def analyze_document(self, document_id: str,
                        rubric_id: str) -> Dict[str, Any]:
        response = requests.post(
            f"{self.base_url}/analyze",
            json={
                "document_id": document_id,
                "rubric_id": rubric_id
            }
        )
        response.raise_for_status()
        return response.json()

    def edit_feedback(self, document_id: str, analysis_id: str,
                     criterion_id: str, feedback: str,
                     score: float) -> Dict[str, Any]:
        response = requests.post(
            f"{self.base_url}/feedback/edit",
            json={
                "document_id": document_id,
                "analysis_id": analysis_id,
                "criterion_id": criterion_id,
                "edits": {
                    "feedback": feedback,
                    "score": score
                }
            }
        )
        response.raise_for_status()
        return response.json()

# Usage
client = AWSClient()

doc = client.load_document(
    student_id="A1234567",
    module="TM112",
    assignment="TMA01",
    content="Essay text..."
)

analysis = client.analyze_document(doc["document_id"], "rubric-id")

client.edit_feedback(
    doc["document_id"],
    analysis["analysis_id"],
    "understanding",
    "Excellent work!",
    28.0
)
```

### Rust

```rust
use reqwest;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Serialize)]
struct LoadDocumentRequest {
    student_id: String,
    module: String,
    assignment: String,
    content: String,
}

#[derive(Deserialize)]
struct LoadDocumentResponse {
    document_id: Uuid,
    student_id_hash: String,
}

async fn load_document(
    client: &reqwest::Client,
    request: LoadDocumentRequest
) -> Result<LoadDocumentResponse, reqwest::Error> {
    let response = client
        .post("http://localhost:8080/api/documents/load")
        .json(&request)
        .send()
        .await?
        .json::<LoadDocumentResponse>()
        .await?;

    Ok(response)
}

// Usage
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();

    let doc = load_document(&client, LoadDocumentRequest {
        student_id: "A1234567".to_string(),
        module: "TM112".to_string(),
        assignment: "TMA01".to_string(),
        content: "Essay text...".to_string(),
    }).await?;

    println!("Document ID: {}", doc.document_id);

    Ok(())
}
```

---

## OpenAPI 3.0 Specification

Full OpenAPI spec available at:

```
GET http://localhost:8080/api/openapi.json
```

Import into tools like:
- **Swagger UI**: Interactive API documentation
- **Postman**: API testing
- **Insomnia**: API client

---

## Rate Limiting & Quotas

### Current Limits (Future)

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/api/analyze` | 10 requests | 1 minute |
| `/api/export` | 20 requests | 1 minute |
| All other endpoints | 100 requests | 1 minute |

### Handling Rate Limits

```javascript
async function analyzeWithRetry(documentId, rubricId, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await client.analyzeDocument(documentId, rubricId);
    } catch (error) {
      if (error.response?.status === 429) {
        const retryAfter = parseInt(error.response.headers['retry-after']) || 60;
        console.log(`Rate limited. Retrying in ${retryAfter}s...`);
        await sleep(retryAfter * 1000);
      } else {
        throw error;
      }
    }
  }
  throw new Error('Max retries exceeded');
}
```

---

## Support

For API questions:
- **Documentation**: [https://aws-edu.org/docs/api](https://aws-edu.org/docs/api)
- **GitHub Issues**: [https://github.com/academic-workflow-suite/issues](https://github.com/academic-workflow-suite/issues)
- **Email**: api@aws-edu.org

---

**Last Updated**: 2025-11-22
**API Version**: 0.1.0
