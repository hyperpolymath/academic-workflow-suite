#!/usr/bin/env python3
"""
Security Report Generator
Aggregates all security audit results and generates comprehensive reports
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any

try:
    from jinja2 import Template
    HAS_JINJA2 = True
except ImportError:
    HAS_JINJA2 = False


class SecurityReportGenerator:
    """Generate comprehensive security reports"""

    def __init__(self, report_dir: str = "/tmp"):
        self.report_dir = Path(report_dir)
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.findings = {
            "critical": [],
            "high": [],
            "medium": [],
            "low": [],
        }
        self.test_results = []

    def load_dependency_audit(self):
        """Load dependency audit results"""
        pattern = "dependency-audit/audit_*.json"
        for report in self.report_dir.glob(pattern):
            try:
                with open(report) as f:
                    data = json.load(f)
                    summary = data.get("summary", {})
                    self.findings["critical"].extend(
                        [f"Dependency vulnerability (critical)"] * summary.get("critical", 0)
                    )
                    self.findings["high"].extend(
                        [f"Dependency vulnerability (high)"] * summary.get("high", 0)
                    )
                    self.test_results.append({
                        "name": "Dependency Audit",
                        "status": "FAIL" if summary.get("total", 0) > 0 else "PASS",
                        "details": f"Total vulnerabilities: {summary.get('total', 0)}"
                    })
            except (json.JSONDecodeError, FileNotFoundError):
                pass

    def load_text_reports(self):
        """Load text-based security reports"""
        report_patterns = [
            ("license_*.txt", "License Check"),
            ("secrets_*.txt", "Secret Scan"),
            ("sql_injection_report.txt", "SQL Injection Test"),
            ("xss_test_report.txt", "XSS Test"),
            ("auth_bypass_report.txt", "Auth Bypass Test"),
            ("container_escape_report.txt", "Container Escape Test"),
            ("privilege_escalation_report.txt", "Privilege Escalation Test"),
            ("network_isolation_report.txt", "Network Isolation Test"),
            ("filesystem_access_report.txt", "Filesystem Access Test"),
            ("anonymization_verification.txt", "Anonymization Verification"),
            ("audit_trail_report.txt", "Audit Trail Verification"),
        ]

        for pattern, name in report_patterns:
            for report_file in self.report_dir.glob(pattern):
                try:
                    with open(report_file) as f:
                        content = f.read()

                        # Parse violations/findings
                        if "FAIL" in content or "VIOLATION" in content or "VULNERABLE" in content:
                            status = "FAIL"
                            # Count violations
                            violations = content.count("[VIOLATION]") + content.count("[VULNERABLE]")
                            if violations > 0:
                                if "CRITICAL" in content:
                                    self.findings["critical"].append(f"{name}: {violations} issues")
                                elif "HIGH" in content:
                                    self.findings["high"].append(f"{name}: {violations} issues")
                                else:
                                    self.findings["medium"].append(f"{name}: {violations} issues")
                        else:
                            status = "PASS"

                        self.test_results.append({
                            "name": name,
                            "status": status,
                            "details": f"Report: {report_file.name}"
                        })
                except FileNotFoundError:
                    pass

    def generate_summary(self) -> Dict[str, Any]:
        """Generate summary statistics"""
        total_tests = len(self.test_results)
        passed = sum(1 for r in self.test_results if r["status"] == "PASS")
        failed = total_tests - passed

        total_findings = sum(len(v) for v in self.findings.values())

        return {
            "timestamp": datetime.now().isoformat(),
            "total_tests": total_tests,
            "tests_passed": passed,
            "tests_failed": failed,
            "pass_rate": round((passed / total_tests * 100) if total_tests > 0 else 0, 2),
            "critical_findings": len(self.findings["critical"]),
            "high_findings": len(self.findings["high"]),
            "medium_findings": len(self.findings["medium"]),
            "low_findings": len(self.findings["low"]),
            "total_findings": total_findings,
        }

    def generate_html_report(self, output_path: str):
        """Generate HTML report"""
        if not HAS_JINJA2:
            print("jinja2 not installed. Install with: pip install jinja2")
            return

        html_template = """
<!DOCTYPE html>
<html>
<head>
    <title>Security Report - {{ timestamp }}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric { background: #f8f9fa; padding: 20px; border-radius: 5px; text-align: center; }
        .metric-value { font-size: 36px; font-weight: bold; margin: 10px 0; }
        .metric-label { color: #666; font-size: 14px; }
        .critical { color: #dc3545; }
        .high { color: #fd7e14; }
        .medium { color: #ffc107; }
        .low { color: #28a745; }
        .pass { color: #28a745; }
        .fail { color: #dc3545; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #007bff; color: white; }
        tr:hover { background: #f8f9fa; }
        .findings-list { list-style: none; padding: 0; }
        .findings-list li { padding: 10px; margin: 5px 0; background: #fff3cd; border-left: 4px solid #ffc107; }
        .badge { padding: 4px 8px; border-radius: 3px; font-size: 12px; font-weight: bold; }
        .badge-pass { background: #d4edda; color: #155724; }
        .badge-fail { background: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Security Audit Report</h1>
        <p><strong>Generated:</strong> {{ timestamp }}</p>

        <h2>Executive Summary</h2>
        <div class="summary">
            <div class="metric">
                <div class="metric-label">Total Tests</div>
                <div class="metric-value">{{ summary.total_tests }}</div>
            </div>
            <div class="metric">
                <div class="metric-label">Pass Rate</div>
                <div class="metric-value pass">{{ summary.pass_rate }}%</div>
            </div>
            <div class="metric">
                <div class="metric-label">Critical Findings</div>
                <div class="metric-value critical">{{ summary.critical_findings }}</div>
            </div>
            <div class="metric">
                <div class="metric-label">High Findings</div>
                <div class="metric-value high">{{ summary.high_findings }}</div>
            </div>
            <div class="metric">
                <div class="metric-label">Medium Findings</div>
                <div class="metric-value medium">{{ summary.medium_findings }}</div>
            </div>
        </div>

        <h2>Test Results</h2>
        <table>
            <thead>
                <tr>
                    <th>Test Name</th>
                    <th>Status</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody>
                {% for test in test_results %}
                <tr>
                    <td>{{ test.name }}</td>
                    <td>
                        <span class="badge badge-{{ test.status.lower() }}">{{ test.status }}</span>
                    </td>
                    <td>{{ test.details }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>

        <h2>Security Findings</h2>

        {% if findings.critical %}
        <h3 class="critical">Critical Issues ({{ findings.critical|length }})</h3>
        <ul class="findings-list">
            {% for finding in findings.critical %}
            <li style="border-left-color: #dc3545; background: #f8d7da;">{{ finding }}</li>
            {% endfor %}
        </ul>
        {% endif %}

        {% if findings.high %}
        <h3 class="high">High Issues ({{ findings.high|length }})</h3>
        <ul class="findings-list">
            {% for finding in findings.high %}
            <li style="border-left-color: #fd7e14; background: #fff3cd;">{{ finding }}</li>
            {% endfor %}
        </ul>
        {% endif %}

        {% if findings.medium %}
        <h3 class="medium">Medium Issues ({{ findings.medium|length }})</h3>
        <ul class="findings-list">
            {% for finding in findings.medium %}
            <li>{{ finding }}</li>
            {% endfor %}
        </ul>
        {% endif %}

        <h2>Recommendations</h2>
        <ul>
            <li>Address all critical and high severity findings immediately</li>
            <li>Review and remediate medium severity findings</li>
            <li>Implement automated security testing in CI/CD pipeline</li>
            <li>Schedule regular security audits</li>
            <li>Keep dependencies up to date</li>
        </ul>
    </div>
</body>
</html>
        """

        template = Template(html_template)
        html_content = template.render(
            timestamp=self.timestamp,
            summary=self.generate_summary(),
            test_results=self.test_results,
            findings=self.findings,
        )

        with open(output_path, "w") as f:
            f.write(html_content)

        print(f"HTML report generated: {output_path}")

    def generate_json_report(self, output_path: str):
        """Generate JSON report"""
        report = {
            "timestamp": self.timestamp,
            "summary": self.generate_summary(),
            "test_results": self.test_results,
            "findings": self.findings,
        }

        with open(output_path, "w") as f:
            json.dump(report, f, indent=2)

        print(f"JSON report generated: {output_path}")

    def print_console_report(self):
        """Print summary to console"""
        summary = self.generate_summary()

        print("\n" + "=" * 60)
        print("SECURITY AUDIT SUMMARY")
        print("=" * 60)
        print(f"Timestamp: {summary['timestamp']}")
        print(f"Total Tests: {summary['total_tests']}")
        print(f"Passed: {summary['tests_passed']}")
        print(f"Failed: {summary['tests_failed']}")
        print(f"Pass Rate: {summary['pass_rate']}%")
        print()
        print(f"Critical Findings: {summary['critical_findings']}")
        print(f"High Findings: {summary['high_findings']}")
        print(f"Medium Findings: {summary['medium_findings']}")
        print(f"Low Findings: {summary['low_findings']}")
        print(f"Total Findings: {summary['total_findings']}")
        print("=" * 60)

        if summary['critical_findings'] > 0 or summary['high_findings'] > 0:
            print("\n⚠ CRITICAL: High/Critical issues detected!")
            return 1
        elif summary['total_findings'] > 0:
            print("\n⚠ WARNING: Security issues detected")
            return 2
        else:
            print("\n✓ All security checks passed")
            return 0


def main():
    """Main entry point"""
    generator = SecurityReportGenerator()

    print("Loading security audit results...")
    generator.load_dependency_audit()
    generator.load_text_reports()

    # Generate reports
    html_path = f"/tmp/security_report_{generator.timestamp}.html"
    json_path = f"/tmp/security_report_{generator.timestamp}.json"

    generator.generate_html_report(html_path)
    generator.generate_json_report(json_path)

    # Print console summary
    exit_code = generator.print_console_report()

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
