/**
 * k6 Load Testing Script for Academic Workflow Suite
 * Usage: k6 run k6_script.js
 *
 * Environment variables:
 *   BASE_URL - API base URL (default: http://localhost:8000)
 *   VUS - Number of virtual users (default: 10)
 *   DURATION - Test duration (default: 30s)
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';
import { randomString, randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Configuration
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';

// Custom metrics
const tmaSubmissionDuration = new Trend('tma_submission_duration');
const feedbackGenerationDuration = new Trend('feedback_generation_duration');
const successfulSubmissions = new Counter('successful_submissions');
const failedSubmissions = new Counter('failed_submissions');
const errorRate = new Rate('error_rate');

// Test options
export const options = {
  stages: [
    { duration: '30s', target: 10 },   // Ramp up to 10 users
    { duration: '1m', target: 10 },    // Stay at 10 users
    { duration: '30s', target: 50 },   // Ramp up to 50 users
    { duration: '2m', target: 50 },    // Stay at 50 users
    { duration: '30s', target: 100 },  // Ramp up to 100 users
    { duration: '1m', target: 100 },   // Stay at 100 users
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<2000', 'p(99)<5000'],  // 95% < 2s, 99% < 5s
    'http_req_failed': ['rate<0.05'],                    // Error rate < 5%
    'tma_submission_duration': ['p(95)<3000'],           // 95% submissions < 3s
    'error_rate': ['rate<0.1'],                          // Custom error rate < 10%
  },
};

// Sample TMA content
const SAMPLE_TMAS = {
  short: `
# Question 1
What is the capital of France?

## Answer
Paris is the capital of France.
`,
  medium: `
# Question 1
Explain the concept of object-oriented programming.

## Answer
Object-oriented programming (OOP) is a programming paradigm based on the concept
of objects, which can contain data and code. The data is in the form of fields
(often known as attributes or properties), and the code is in the form of
procedures (often known as methods).

# Question 2
What are the four pillars of OOP?

## Answer
The four pillars of OOP are:
1. Encapsulation - bundling data and methods
2. Abstraction - hiding complex implementation details
3. Inheritance - creating new classes from existing ones
4. Polymorphism - objects taking multiple forms
`,
  long: `
# Question 1
Discuss the impact of climate change on global ecosystems.

## Answer
Climate change has profound effects on global ecosystems. Rising temperatures
alter habitats, forcing species to migrate or adapt. Ocean acidification
threatens marine life, particularly coral reefs and shellfish.
${"Lorem ipsum dolor sit amet. ".repeat(200)}
`
};

// Helper functions
function randomStudentId() {
  return `STU${randomIntBetween(10000, 99999)}`;
}

function randomTmaId() {
  return `TMA${randomIntBetween(1000, 9999)}`;
}

function selectTmaSize() {
  const rand = Math.random();
  if (rand < 0.6) return 'short';    // 60% short
  if (rand < 0.9) return 'medium';   // 30% medium
  return 'long';                      // 10% long
}

// Main test scenario
export default function () {
  group('TMA Submission Workflow', function () {
    const studentId = randomStudentId();
    const tmaId = randomTmaId();
    const tmaSize = selectTmaSize();

    // 1. Submit TMA
    group('Submit TMA', function () {
      const payload = JSON.stringify({
        tma_id: tmaId,
        student_id: studentId,
        content: SAMPLE_TMAS[tmaSize],
        metadata: {
          course: 'CS101',
          assignment: `Assignment ${randomIntBetween(1, 10)}`,
          submitted_at: new Date().toISOString(),
        },
      });

      const params = {
        headers: {
          'Content-Type': 'application/json',
        },
        tags: { name: 'SubmitTMA', size: tmaSize },
      };

      const submitStart = Date.now();
      const submitRes = http.post(`${BASE_URL}/api/v1/tma/submit`, payload, params);
      const submitDuration = Date.now() - submitStart;

      tmaSubmissionDuration.add(submitDuration);

      const submitSuccess = check(submitRes, {
        'submission status is 200': (r) => r.status === 200,
        'submission has submission_id': (r) => {
          try {
            const body = JSON.parse(r.body);
            return body.submission_id !== undefined;
          } catch (e) {
            return false;
          }
        },
      });

      if (submitSuccess) {
        successfulSubmissions.add(1);
        const submissionId = JSON.parse(submitRes.body).submission_id;

        // 2. Check status
        sleep(randomIntBetween(1, 3));

        group('Check Status', function () {
          const statusRes = http.get(
            `${BASE_URL}/api/v1/tma/status/${submissionId}`,
            { tags: { name: 'CheckStatus' } }
          );

          check(statusRes, {
            'status check is 200': (r) => r.status === 200,
            'has status field': (r) => {
              try {
                const body = JSON.parse(r.body);
                return body.status !== undefined;
              } catch (e) {
                return false;
              }
            },
          });
        });

        // 3. Get feedback
        sleep(randomIntBetween(2, 5));

        group('Get Feedback', function () {
          const feedbackStart = Date.now();
          const feedbackRes = http.get(
            `${BASE_URL}/api/v1/tma/feedback/${submissionId}`,
            { tags: { name: 'GetFeedback' } }
          );
          const feedbackDuration = Date.now() - feedbackStart;

          feedbackGenerationDuration.add(feedbackDuration);

          const feedbackSuccess = check(feedbackRes, {
            'feedback status is 200 or 202': (r) => r.status === 200 || r.status === 202,
            'has feedback data': (r) => {
              if (r.status === 202) return true; // Still processing
              try {
                const body = JSON.parse(r.body);
                return body.feedback !== undefined;
              } catch (e) {
                return false;
              }
            },
          });

          if (!feedbackSuccess) {
            errorRate.add(1);
          } else {
            errorRate.add(0);
          }
        });
      } else {
        failedSubmissions.add(1);
        errorRate.add(1);
      }
    });
  });

  sleep(randomIntBetween(1, 3));
}

// Smoke test scenario (quick validation)
export function smokeTest() {
  const tmaId = randomTmaId();
  const payload = JSON.stringify({
    tma_id: tmaId,
    student_id: randomStudentId(),
    content: SAMPLE_TMAS.short,
    metadata: { test: 'smoke' },
  });

  const res = http.post(`${BASE_URL}/api/v1/tma/submit`, payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(res, {
    'smoke test status is 200': (r) => r.status === 200,
  });
}

// Stress test scenario (high load)
export function stressTest() {
  const requests = [];

  for (let i = 0; i < 10; i++) {
    requests.push([
      'POST',
      `${BASE_URL}/api/v1/tma/submit`,
      JSON.stringify({
        tma_id: randomTmaId(),
        student_id: randomStudentId(),
        content: SAMPLE_TMAS.short,
        metadata: { batch: i },
      }),
      { headers: { 'Content-Type': 'application/json' } },
    ]);
  }

  const responses = http.batch(requests);

  for (const res of responses) {
    check(res, {
      'batch request successful': (r) => r.status === 200,
    });
  }
}

// Spike test scenario (sudden traffic spike)
export function spikeTest() {
  const vus = __VU;
  const iterations = vus < 50 ? 1 : 5; // More iterations during spike

  for (let i = 0; i < iterations; i++) {
    http.post(
      `${BASE_URL}/api/v1/tma/submit`,
      JSON.stringify({
        tma_id: randomTmaId(),
        student_id: randomStudentId(),
        content: SAMPLE_TMAS.short,
        metadata: { spike: true },
      }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  }
}

// Soak test scenario (sustained load)
export function soakTest() {
  const payload = JSON.stringify({
    tma_id: randomTmaId(),
    student_id: randomStudentId(),
    content: SAMPLE_TMAS[selectTmaSize()],
    metadata: { soak: true },
  });

  const res = http.post(`${BASE_URL}/api/v1/tma/submit`, payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(res, {
    'soak test successful': (r) => r.status === 200,
  });

  sleep(1);
}

// Setup function (runs once at start)
export function setup() {
  console.log(`Starting k6 load test against ${BASE_URL}`);

  // Health check
  const healthRes = http.get(`${BASE_URL}/health`);
  if (healthRes.status !== 200) {
    console.warn('Warning: Health check failed!');
  }

  return { startTime: Date.now() };
}

// Teardown function (runs once at end)
export function teardown(data) {
  const duration = (Date.now() - data.startTime) / 1000;
  console.log(`Test completed in ${duration.toFixed(2)} seconds`);
}

// Handle summary (custom reporting)
export function handleSummary(data) {
  return {
    'summary.json': JSON.stringify(data),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, options) {
  const indent = options.indent || '';
  const colors = options.enableColors;

  let summary = '\n';
  summary += `${indent}✓ Total Requests: ${data.metrics.http_reqs.values.count}\n`;
  summary += `${indent}✓ Failed Requests: ${data.metrics.http_req_failed.values.passes}\n`;
  summary += `${indent}✓ Request Duration (avg): ${data.metrics.http_req_duration.values.avg.toFixed(2)}ms\n`;
  summary += `${indent}✓ Request Duration (p95): ${data.metrics.http_req_duration.values['p(95)'].toFixed(2)}ms\n`;
  summary += `${indent}✓ Request Duration (p99): ${data.metrics.http_req_duration.values['p(99)'].toFixed(2)}ms\n`;
  summary += `${indent}✓ Successful Submissions: ${data.metrics.successful_submissions.values.count}\n`;
  summary += `${indent}✓ Failed Submissions: ${data.metrics.failed_submissions.values.count}\n`;

  return summary;
}
