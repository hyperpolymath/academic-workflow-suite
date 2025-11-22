"""
Custom Feedback Formatter Plugin
Formats marking feedback in various output styles
"""

from typing import Dict, Any
import json
from datetime import datetime


class FeedbackFormatterPlugin:
    """Plugin for formatting feedback in different styles"""

    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or {}
        self.format_type = self.config.get('format', 'markdown')

    def format_feedback(self, results: Dict[str, Any]) -> str:
        """Format feedback based on configured format type"""

        formatters = {
            'markdown': self._format_markdown,
            'html': self._format_html,
            'latex': self._format_latex,
            'plain': self._format_plain,
            'json': self._format_json,
        }

        formatter = formatters.get(self.format_type, self._format_markdown)
        return formatter(results)

    def _format_markdown(self, results: Dict[str, Any]) -> str:
        """Format as Markdown"""
        output = f"# Assignment Feedback\n\n"
        output += f"**Student ID:** {results['student_id']}\n"
        output += f"**Date:** {results['marked_at']}\n\n"
        output += f"## Grade\n\n"
        output += f"**Score:** {results['score']}/100\n"
        output += f"**Grade:** {results['grade']}\n\n"
        output += f"## Summary\n\n{results['feedback']['summary']}\n\n"
        output += f"## Strengths\n\n"

        for strength in results['feedback']['strengths']:
            output += f"- {strength}\n"

        output += f"\n## Areas for Improvement\n\n"

        for area in results['feedback']['areas_for_improvement']:
            output += f"- {area}\n"

        return output

    def _format_html(self, results: Dict[str, Any]) -> str:
        """Format as HTML"""
        output = f"""
<!DOCTYPE html>
<html>
<head>
    <title>Assignment Feedback</title>
    <style>
        body {{ font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }}
        h1 {{ color: #333; }}
        .grade {{ font-size: 2em; color: #4CAF50; }}
        .section {{ margin: 20px 0; }}
        ul {{ list-style-type: disc; margin-left: 20px; }}
    </style>
</head>
<body>
    <h1>Assignment Feedback</h1>
    <p><strong>Student ID:</strong> {results['student_id']}</p>
    <p><strong>Date:</strong> {results['marked_at']}</p>

    <div class="section">
        <h2>Grade</h2>
        <p class="grade">{results['grade']} ({results['score']}/100)</p>
    </div>

    <div class="section">
        <h2>Summary</h2>
        <p>{results['feedback']['summary']}</p>
    </div>

    <div class="section">
        <h2>Strengths</h2>
        <ul>
"""

        for strength in results['feedback']['strengths']:
            output += f"            <li>{strength}</li>\n"

        output += """        </ul>
    </div>

    <div class="section">
        <h2>Areas for Improvement</h2>
        <ul>
"""

        for area in results['feedback']['areas_for_improvement']:
            output += f"            <li>{area}</li>\n"

        output += """        </ul>
    </div>
</body>
</html>
"""

        return output

    def _format_latex(self, results: Dict[str, Any]) -> str:
        """Format as LaTeX"""
        output = r"""\documentclass{article}
\usepackage[utf8]{inputenc}
\usepackage{enumitem}

\title{Assignment Feedback}
\author{Academic Workflow Suite}
\date{""" + results['marked_at'] + r"""}

\begin{document}

\maketitle

\section*{Student Information}
\textbf{Student ID:} """ + results['student_id'] + r"""

\section*{Grade}
\textbf{Score:} """ + str(results['score']) + r"""/100 \\
\textbf{Grade:} """ + results['grade'] + r"""

\section*{Summary}
""" + results['feedback']['summary'] + r"""

\section*{Strengths}
\begin{itemize}
"""

        for strength in results['feedback']['strengths']:
            output += f"    \\item {strength}\n"

        output += r"""\end{itemize}

\section*{Areas for Improvement}
\begin{itemize}
"""

        for area in results['feedback']['areas_for_improvement']:
            output += f"    \\item {area}\n"

        output += r"""\end{itemize}

\end{document}
"""

        return output

    def _format_plain(self, results: Dict[str, Any]) -> str:
        """Format as plain text"""
        output = "ASSIGNMENT FEEDBACK\n"
        output += "=" * 50 + "\n\n"
        output += f"Student ID: {results['student_id']}\n"
        output += f"Date: {results['marked_at']}\n\n"
        output += f"GRADE: {results['grade']} ({results['score']}/100)\n\n"
        output += f"SUMMARY\n{'-' * 50}\n{results['feedback']['summary']}\n\n"
        output += f"STRENGTHS\n{'-' * 50}\n"

        for i, strength in enumerate(results['feedback']['strengths'], 1):
            output += f"{i}. {strength}\n"

        output += f"\nAREAS FOR IMPROVEMENT\n{'-' * 50}\n"

        for i, area in enumerate(results['feedback']['areas_for_improvement'], 1):
            output += f"{i}. {area}\n"

        return output

    def _format_json(self, results: Dict[str, Any]) -> str:
        """Format as JSON"""
        return json.dumps(results, indent=2)


# Plugin registration
def register_plugin(registry):
    """Register the plugin with the system"""
    registry.register_formatter('custom', FeedbackFormatterPlugin)


# Example usage
if __name__ == '__main__':
    sample_results = {
        'tma_id': 'tma_123456',
        'student_id': 'student001',
        'score': 85,
        'grade': 'B+',
        'marked_at': datetime.now().isoformat(),
        'feedback': {
            'summary': 'Good work overall with clear arguments and strong evidence.',
            'strengths': [
                'Clear thesis statement',
                'Good use of supporting evidence',
                'Logical structure'
            ],
            'areas_for_improvement': [
                'Citation formatting needs attention',
                'Conclusion could be stronger',
                'Consider counterarguments'
            ]
        }
    }

    # Test all formats
    for format_type in ['markdown', 'html', 'latex', 'plain', 'json']:
        plugin = FeedbackFormatterPlugin({'format': format_type})
        print(f"\n{'=' * 50}")
        print(f"Format: {format_type.upper()}")
        print('=' * 50)
        print(plugin.format_feedback(sample_results))
