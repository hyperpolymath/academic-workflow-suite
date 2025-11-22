#!/usr/bin/env python3
"""
Example: Mark a TMA using the AWAP Python SDK

This demonstrates the simplest way to use the SDK to mark a TMA.
"""

import sys
import os
from pathlib import Path

# Add parent directory to path for local development
sys.path.insert(0, str(Path(__file__).parent.parent))

from awap_sdk import AwapClient, AwapError


def main():
    if len(sys.argv) < 2:
        print("Usage: python mark_tma.py <tma_file.pdf> [student_id] [rubric]")
        sys.exit(1)

    tma_file = sys.argv[1]
    student_id = sys.argv[2] if len(sys.argv) > 2 else "student001"
    rubric = sys.argv[3] if len(sys.argv) > 3 else "default"

    print("Academic Workflow Suite - Python SDK Example")
    print("=" * 50)
    print()

    # Create client
    client = AwapClient()

    try:
        print(f"Marking TMA: {tma_file}")
        print(f"Student ID: {student_id}")
        print(f"Rubric: {rubric}")
        print()

        # Mark TMA (upload, submit, wait, get results - all in one call)
        result = client.mark_tma(
            file_path=tma_file,
            student_id=student_id,
            rubric=rubric
        )

        # Display results
        print("Results:")
        print("=" * 50)
        print(f"Score: {result.score}")
        print(f"Grade: {result.grade}")
        print()

        print("Feedback Summary:")
        print(result.feedback.summary)
        print()

        print("Strengths:")
        for strength in result.feedback.strengths:
            print(f"  • {strength}")
        print()

        print("Areas for Improvement:")
        for area in result.feedback.areas_for_improvement:
            print(f"  • {area}")
        print()

        # Save feedback to file
        output_file = Path(tma_file).with_suffix('.feedback.json')
        import json

        feedback_dict = {
            'tma_id': result.tma_id,
            'student_id': result.student_id,
            'score': result.score,
            'grade': result.grade,
            'feedback': {
                'summary': result.feedback.summary,
                'strengths': result.feedback.strengths,
                'areas_for_improvement': result.feedback.areas_for_improvement,
                'detailed_comments': result.feedback.detailed_comments
            },
            'marked_at': result.marked_at
        }

        with open(output_file, 'w') as f:
            json.dump(feedback_dict, f, indent=2)

        print(f"Full feedback saved to: {output_file}")

    except AwapError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
