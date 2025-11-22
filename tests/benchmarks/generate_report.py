#!/usr/bin/env python3
"""
Benchmark Report Generator
Parses benchmark results and generates comprehensive reports
"""

import json
import sys
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional
import statistics


class BenchmarkReportGenerator:
    """Generate benchmark reports from various sources"""

    def __init__(self, output_dir: Path):
        self.output_dir = Path(output_dir)
        self.results = {}
        self.hardware_info = {}
        self.baseline = None

    def load_hardware_info(self):
        """Load hardware information"""
        hw_file = self.output_dir / "hardware_info.json"
        if hw_file.exists():
            with open(hw_file) as f:
                self.hardware_info = json.load(f)

    def load_baseline(self, baseline_file: Path):
        """Load baseline data"""
        if baseline_file.exists():
            with open(baseline_file) as f:
                self.baseline = json.load(f)

    def parse_criterion_results(self):
        """Parse Criterion benchmark results"""
        criterion_dir = self.output_dir / "criterion"
        if not criterion_dir.exists():
            return

        # Parse criterion output logs
        for log_file in criterion_dir.glob("*.log"):
            benchmark_name = log_file.stem
            self.results[benchmark_name] = self._parse_criterion_log(log_file)

    def _parse_criterion_log(self, log_file: Path) -> Dict:
        """Parse individual criterion log file"""
        results = {}
        current_bench = None

        with open(log_file) as f:
            for line in f:
                line = line.strip()

                # Extract benchmark name
                if "Benchmarking" in line:
                    parts = line.split("Benchmarking ")
                    if len(parts) > 1:
                        current_bench = parts[1].split(":")[0]
                        results[current_bench] = {}

                # Extract timing information
                if "time:" in line and current_bench:
                    # Format: "time:   [1.234 ms 1.456 ms 1.678 ms]"
                    parts = line.split("[")
                    if len(parts) > 1:
                        times = parts[1].split("]")[0].split()
                        if len(times) >= 3:
                            results[current_bench] = {
                                "lower": self._parse_time(times[0], times[1]),
                                "estimate": self._parse_time(times[2], times[3]),
                                "upper": self._parse_time(times[4], times[5]) if len(times) >= 6 else None
                            }

        return results

    def _parse_time(self, value: str, unit: str) -> float:
        """Convert time value to nanoseconds"""
        val = float(value)
        if unit == "ns":
            return val
        elif unit == "µs" or unit == "us":
            return val * 1000
        elif unit == "ms":
            return val * 1000000
        elif unit == "s":
            return val * 1000000000
        return val

    def parse_integration_results(self):
        """Parse integration benchmark results"""
        integration_dir = self.output_dir / "integration"
        if not integration_dir.exists():
            return

        integration_results = {}

        for json_file in integration_dir.glob("*.json"):
            with open(json_file) as f:
                data = json.load(f)
                integration_results[data.get("benchmark", json_file.stem)] = data

        self.results["integration"] = integration_results

    def compare_with_baseline(self) -> Dict:
        """Compare current results with baseline"""
        if not self.baseline:
            return {}

        comparisons = {}

        for bench_name, bench_data in self.results.items():
            if bench_name not in self.baseline.get("benchmarks", {}):
                continue

            baseline_data = self.baseline["benchmarks"][bench_name]
            comparisons[bench_name] = self._compare_benchmark(bench_data, baseline_data)

        return comparisons

    def _compare_benchmark(self, current: Dict, baseline: Dict) -> Dict:
        """Compare individual benchmark"""
        comparison = {}

        for metric, value in current.items():
            if metric not in baseline:
                continue

            baseline_val = baseline[metric]

            if isinstance(value, dict) and "estimate" in value:
                current_val = value["estimate"]
                baseline_estimate = baseline_val.get("avg_ns", 0) if isinstance(baseline_val, dict) else baseline_val
            else:
                current_val = value
                baseline_estimate = baseline_val

            if baseline_estimate > 0:
                change_pct = ((current_val - baseline_estimate) / baseline_estimate) * 100
                comparison[metric] = {
                    "current": current_val,
                    "baseline": baseline_estimate,
                    "change_pct": change_pct,
                    "regression": change_pct > 10
                }

        return comparison

    def detect_regressions(self, threshold: float = 10.0) -> List[Dict]:
        """Detect performance regressions"""
        regressions = []

        comparisons = self.compare_with_baseline()

        for bench_name, bench_comparison in comparisons.items():
            for metric, data in bench_comparison.items():
                if isinstance(data, dict) and data.get("change_pct", 0) > threshold:
                    regressions.append({
                        "benchmark": bench_name,
                        "metric": metric,
                        "current": data["current"],
                        "baseline": data["baseline"],
                        "change_pct": data["change_pct"]
                    })

        return regressions

    def generate_html_report(self) -> str:
        """Generate HTML report"""
        html = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Benchmark Report - Academic Workflow Suite</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }}
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }}
        h1 {{ margin: 0; font-size: 2.5em; }}
        .meta {{ opacity: 0.9; margin-top: 10px; }}
        .section {{
            background: white;
            padding: 25px;
            margin-bottom: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        h2 {{
            color: #667eea;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
            margin-top: 0;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }}
        th, td {{
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }}
        th {{
            background: #667eea;
            color: white;
            font-weight: 600;
        }}
        tr:hover {{ background: #f8f9fa; }}
        .metric {{
            font-family: 'Courier New', monospace;
            background: #f8f9fa;
            padding: 2px 6px;
            border-radius: 3px;
        }}
        .good {{ color: #28a745; font-weight: bold; }}
        .warning {{ color: #ffc107; font-weight: bold; }}
        .bad {{ color: #dc3545; font-weight: bold; }}
        .hardware {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }}
        .hw-card {{
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #667eea;
        }}
        .hw-label {{ font-weight: 600; color: #666; font-size: 0.85em; }}
        .hw-value {{ font-size: 1.2em; margin-top: 5px; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 Benchmark Report</h1>
        <div class="meta">
            Academic Workflow Suite Performance Analysis<br>
            Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        </div>
    </div>

    {self._generate_hardware_section()}
    {self._generate_summary_section()}
    {self._generate_benchmark_sections()}
    {self._generate_regression_section()}

    <div class="section">
        <p style="text-align: center; color: #666;">
            Generated by Academic Workflow Suite Benchmark Runner
        </p>
    </div>
</body>
</html>
"""
        return html

    def _generate_hardware_section(self) -> str:
        """Generate hardware information section"""
        if not self.hardware_info:
            return ""

        cpu = self.hardware_info.get("cpu", {})
        ram = self.hardware_info.get("ram", {})
        gpu = self.hardware_info.get("gpu", {})
        storage = self.hardware_info.get("storage", {})

        return f"""
    <div class="section">
        <h2>Hardware Configuration</h2>
        <div class="hardware">
            <div class="hw-card">
                <div class="hw-label">CPU</div>
                <div class="hw-value">{cpu.get('model', 'Unknown')}</div>
                <div>{cpu.get('cores', 'N/A')} cores</div>
            </div>
            <div class="hw-card">
                <div class="hw-label">RAM</div>
                <div class="hw-value">{ram.get('total_gb', 'N/A')} GB</div>
            </div>
            <div class="hw-card">
                <div class="hw-label">GPU</div>
                <div class="hw-value">{gpu.get('model', 'None')}</div>
                <div>{gpu.get('vram_mb', 0)} MB VRAM</div>
            </div>
            <div class="hw-card">
                <div class="hw-label">Storage</div>
                <div class="hw-value">{storage.get('type', 'Unknown')}</div>
            </div>
        </div>
    </div>
"""

    def _generate_summary_section(self) -> str:
        """Generate summary section"""
        total_benchmarks = sum(len(v) if isinstance(v, dict) else 1 for v in self.results.values())

        return f"""
    <div class="section">
        <h2>Summary</h2>
        <p>Total benchmarks run: <strong>{total_benchmarks}</strong></p>
        <p>Benchmark categories: <strong>{len(self.results)}</strong></p>
    </div>
"""

    def _generate_benchmark_sections(self) -> str:
        """Generate benchmark result sections"""
        sections = []

        for bench_name, bench_data in self.results.items():
            if isinstance(bench_data, dict):
                sections.append(self._format_benchmark_section(bench_name, bench_data))

        return "\n".join(sections)

    def _format_benchmark_section(self, name: str, data: Dict) -> str:
        """Format individual benchmark section"""
        rows = []

        for metric, value in data.items():
            if isinstance(value, dict):
                if "estimate" in value:
                    formatted_value = self._format_time(value["estimate"])
                else:
                    formatted_value = str(value)
            else:
                formatted_value = self._format_time(value) if isinstance(value, (int, float)) else str(value)

            rows.append(f"<tr><td>{metric}</td><td class='metric'>{formatted_value}</td></tr>")

        return f"""
    <div class="section">
        <h2>{name.replace('_', ' ').title()}</h2>
        <table>
            <thead>
                <tr>
                    <th>Metric</th>
                    <th>Value</th>
                </tr>
            </thead>
            <tbody>
                {''.join(rows)}
            </tbody>
        </table>
    </div>
"""

    def _generate_regression_section(self) -> str:
        """Generate regression detection section"""
        if not self.baseline:
            return ""

        regressions = self.detect_regressions()

        if not regressions:
            return """
    <div class="section">
        <h2>Regression Analysis</h2>
        <p class="good">✓ No performance regressions detected</p>
    </div>
"""

        rows = []
        for reg in regressions:
            rows.append(f"""
                <tr>
                    <td>{reg['benchmark']}</td>
                    <td>{reg['metric']}</td>
                    <td class='metric'>{self._format_time(reg['baseline'])}</td>
                    <td class='metric'>{self._format_time(reg['current'])}</td>
                    <td class='bad'>+{reg['change_pct']:.1f}%</td>
                </tr>
            """)

        return f"""
    <div class="section">
        <h2>Regression Analysis</h2>
        <p class="bad">⚠ {len(regressions)} performance regression(s) detected</p>
        <table>
            <thead>
                <tr>
                    <th>Benchmark</th>
                    <th>Metric</th>
                    <th>Baseline</th>
                    <th>Current</th>
                    <th>Change</th>
                </tr>
            </thead>
            <tbody>
                {''.join(rows)}
            </tbody>
        </table>
    </div>
"""

    def _format_time(self, ns: float) -> str:
        """Format time value to appropriate unit"""
        if ns < 1000:
            return f"{ns:.2f} ns"
        elif ns < 1000000:
            return f"{ns/1000:.2f} µs"
        elif ns < 1000000000:
            return f"{ns/1000000:.2f} ms"
        else:
            return f"{ns/1000000000:.2f} s"

    def generate_markdown_report(self) -> str:
        """Generate Markdown report"""
        md = f"""# Benchmark Report - Academic Workflow Suite

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Hardware Configuration

"""

        if self.hardware_info:
            cpu = self.hardware_info.get("cpu", {})
            ram = self.hardware_info.get("ram", {})
            gpu = self.hardware_info.get("gpu", {})

            md += f"""- **CPU:** {cpu.get('model', 'Unknown')} ({cpu.get('cores', 'N/A')} cores)
- **RAM:** {ram.get('total_gb', 'N/A')} GB
- **GPU:** {gpu.get('model', 'None')} ({gpu.get('vram_mb', 0)} MB VRAM)

"""

        md += "## Results\n\n"

        for bench_name, bench_data in self.results.items():
            md += f"### {bench_name.replace('_', ' ').title()}\n\n"

            if isinstance(bench_data, dict):
                md += "| Metric | Value |\n|--------|-------|\n"
                for metric, value in bench_data.items():
                    if isinstance(value, dict) and "estimate" in value:
                        formatted = self._format_time(value["estimate"])
                    else:
                        formatted = str(value)
                    md += f"| {metric} | `{formatted}` |\n"

            md += "\n"

        # Regressions
        if self.baseline:
            regressions = self.detect_regressions()
            md += "## Regression Analysis\n\n"

            if not regressions:
                md += "✓ No performance regressions detected\n\n"
            else:
                md += f"⚠ {len(regressions)} regression(s) detected:\n\n"
                md += "| Benchmark | Metric | Baseline | Current | Change |\n"
                md += "|-----------|--------|----------|---------|--------|\n"

                for reg in regressions:
                    md += f"| {reg['benchmark']} | {reg['metric']} | {self._format_time(reg['baseline'])} | {self._format_time(reg['current'])} | +{reg['change_pct']:.1f}% |\n"

        return md

    def generate_json_report(self) -> str:
        """Generate JSON report"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "hardware": self.hardware_info,
            "results": self.results,
            "baseline_comparison": self.compare_with_baseline() if self.baseline else None,
            "regressions": self.detect_regressions() if self.baseline else []
        }

        return json.dumps(report, indent=2)


def main():
    parser = argparse.ArgumentParser(description="Generate benchmark reports")
    parser.add_argument("--output-dir", type=Path, default=Path("reports"),
                        help="Output directory for results")
    parser.add_argument("--format", default="html,markdown,json",
                        help="Output formats (comma-separated)")
    parser.add_argument("--compare-baseline", type=Path,
                        help="Compare against baseline file")
    parser.add_argument("--save-baseline", type=Path,
                        help="Save current results as baseline")
    parser.add_argument("--detect-regressions", action="store_true",
                        help="Detect and report regressions")
    parser.add_argument("--threshold", type=float, default=10.0,
                        help="Regression threshold percentage")

    args = parser.parse_args()

    generator = BenchmarkReportGenerator(args.output_dir)
    generator.load_hardware_info()
    generator.parse_criterion_results()
    generator.parse_integration_results()

    if args.compare_baseline:
        generator.load_baseline(args.compare_baseline)

    # Generate reports
    formats = args.format.split(",")

    if "html" in formats:
        html_report = generator.generate_html_report()
        output_file = args.output_dir / "benchmark_report.html"
        with open(output_file, "w") as f:
            f.write(html_report)
        print(f"HTML report: {output_file}")

    if "markdown" in formats or "md" in formats:
        md_report = generator.generate_markdown_report()
        output_file = args.output_dir / "benchmark_report.md"
        with open(output_file, "w") as f:
            f.write(md_report)
        print(f"Markdown report: {output_file}")

    if "json" in formats:
        json_report = generator.generate_json_report()
        output_file = args.output_dir / "benchmark_report.json"
        with open(output_file, "w") as f:
            f.write(json_report)
        print(f"JSON report: {output_file}")

    # Regression detection
    if args.detect_regressions and generator.baseline:
        regressions = generator.detect_regressions(args.threshold)

        if regressions:
            print("\n⚠ REGRESSION DETECTED ⚠")
            print(f"\nFound {len(regressions)} performance regression(s):\n")

            for reg in regressions:
                print(f"  {reg['benchmark']} / {reg['metric']}")
                print(f"    Baseline: {generator._format_time(reg['baseline'])}")
                print(f"    Current:  {generator._format_time(reg['current'])}")
                print(f"    Change:   +{reg['change_pct']:.1f}%\n")

            sys.exit(1)
        else:
            print("\n✓ No regressions detected")

    # Save baseline
    if args.save_baseline:
        baseline_data = {
            "metadata": {
                "created": datetime.now().isoformat(),
                "hardware": generator.hardware_info
            },
            "benchmarks": generator.results,
            "thresholds": {
                "regression_percentage": args.threshold
            }
        }

        with open(args.save_baseline, "w") as f:
            json.dump(baseline_data, f, indent=2)

        print(f"Baseline saved: {args.save_baseline}")


if __name__ == "__main__":
    main()
