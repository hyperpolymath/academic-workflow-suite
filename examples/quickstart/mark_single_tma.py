#!/usr/bin/env python3
"""
Quick Start: Mark a Single TMA using Python
This script demonstrates how to submit a TMA for automated marking using Python.
"""

import os
import sys
import time
import json
import requests
from pathlib import Path

# Configuration
API_URL = os.getenv('AWS_API_URL', 'http://localhost:8080')
TIMEOUT = 300  # seconds

class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    RED = '\033[0;31m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'  # No Color


def print_step(step_num, message):
    """Print a colored step message"""
    print(f"{Colors.GREEN}Step {step_num}:{Colors.NC} {message}")


def print_error(message):
    """Print a colored error message"""
    print(f"{Colors.RED}Error: {message}{Colors.NC}", file=sys.stderr)


def print_success(message):
    """Print a colored success message"""
    print(f"{Colors.GREEN}✓ {message}{Colors.NC}")


def upload_tma(file_path, student_id, rubric='default'):
    """Upload a TMA file to the API"""
    print_step(1, "Uploading TMA...")

    with open(file_path, 'rb') as f:
        files = {'file': (os.path.basename(file_path), f, 'application/pdf')}
        data = {
            'student_id': student_id,
            'rubric': rubric
        }

        response = requests.post(
            f'{API_URL}/api/v1/tma/upload',
            files=files,
            data=data
        )
        response.raise_for_status()

    result = response.json()
    tma_id = result.get('tma_id')

    if not tma_id:
        raise ValueError("No TMA ID returned from upload")

    print_success("TMA uploaded successfully")
    print(f"  TMA ID: {tma_id}")
    return tma_id


def submit_for_marking(tma_id, rubric='default'):
    """Submit a TMA for marking"""
    print_step(2, "Submitting for marking...")

    response = requests.post(
        f'{API_URL}/api/v1/tma/{tma_id}/mark',
        json={'rubric': rubric, 'auto_feedback': True}
    )
    response.raise_for_status()

    result = response.json()
    job_id = result.get('job_id')

    print_success("Marking job submitted")
    print(f"  Job ID: {job_id}")
    return job_id


def wait_for_results(job_id, tma_id):
    """Wait for marking to complete and retrieve results"""
    print_step(3, "Waiting for results...")

    elapsed = 0
    while elapsed < TIMEOUT:
        response = requests.get(f'{API_URL}/api/v1/jobs/{job_id}')
        response.raise_for_status()

        status_data = response.json()
        status = status_data.get('status')

        if status == 'completed':
            print_success("Marking completed!\n")

            # Get detailed results
            result_response = requests.get(f'{API_URL}/api/v1/tma/{tma_id}/results')
            result_response.raise_for_status()
            return result_response.json()

        elif status == 'failed':
            error_msg = status_data.get('error', 'Unknown error')
            raise RuntimeError(f"Marking failed: {error_msg}")

        print('.', end='', flush=True)
        time.sleep(5)
        elapsed += 5

    raise TimeoutError("Marking took too long")


def display_results(results, output_file=None):
    """Display and optionally save results"""
    print(f"{Colors.BLUE}Results:{Colors.NC}")
    print("=" * 50)

    # Display summary
    print(f"\nScore: {results.get('score', 'N/A')}")
    print(f"Grade: {results.get('grade', 'N/A')}")

    feedback = results.get('feedback', {})

    print(f"\n{Colors.BLUE}Feedback Summary:{Colors.NC}")
    print(feedback.get('summary', 'No summary available'))

    print(f"\n{Colors.GREEN}Strengths:{Colors.NC}")
    for strength in feedback.get('strengths', []):
        print(f"  • {strength}")

    print(f"\n{Colors.YELLOW}Areas for Improvement:{Colors.NC}")
    for area in feedback.get('areas_for_improvement', []):
        print(f"  • {area}")

    # Save to file if requested
    if output_file:
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2)
        print(f"\n{Colors.GREEN}Full feedback saved to:{Colors.NC} {output_file}")


def main():
    """Main function"""
    if len(sys.argv) < 2:
        print_error("Usage: python mark_single_tma.py <tma_file.pdf> [rubric] [student_id]")
        sys.exit(1)

    tma_file = sys.argv[1]
    rubric = sys.argv[2] if len(sys.argv) > 2 else 'default'
    student_id = sys.argv[3] if len(sys.argv) > 3 else 'student001'

    # Check file exists
    if not os.path.isfile(tma_file):
        print_error(f"TMA file not found: {tma_file}")
        sys.exit(1)

    print(f"{Colors.BLUE}Academic Workflow Suite - Quick Start{Colors.NC}")
    print(f"{Colors.BLUE}======================================{Colors.NC}\n")

    try:
        # Step 1: Upload TMA
        tma_id = upload_tma(tma_file, student_id, rubric)

        # Step 2: Submit for marking
        job_id = submit_for_marking(tma_id, rubric)

        # Step 3: Wait for and retrieve results
        results = wait_for_results(job_id, tma_id)

        # Display results
        output_file = Path(tma_file).with_suffix('.feedback.json')
        display_results(results, output_file)

    except requests.exceptions.RequestException as e:
        print_error(f"API request failed: {e}")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
