# Contributing to Academic Workflow Suite

First off, thank you for considering contributing to the Academic Workflow Suite! It's people like you that make this project a great tool for the academic community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Documentation Requirements](#documentation-requirements)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to conduct@academic-workflow-suite.org.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [existing issues](../../issues) to avoid duplicates. When you create a bug report, include as many details as possible:

- Use the bug report template
- Provide a clear and descriptive title
- Describe the exact steps to reproduce the problem
- Provide specific examples to demonstrate the steps
- Describe the behavior you observed and what you expected
- Include screenshots if applicable
- Include your environment details (OS, Python version, etc.)

### Suggesting Features

Feature suggestions are welcome! Please:

- Use the feature request template
- Provide a clear and detailed explanation of the feature
- Explain why this feature would be useful to most users
- List any alternative solutions or features you've considered
- Be open to discussion and feedback

### Asking Questions

- Check the [documentation](../../wiki) first
- Search [existing discussions](../../discussions)
- Use the question template when creating an issue
- Join our community channels for real-time help

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:

- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed
- `documentation` - Documentation improvements

### Pull Requests

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Write or update tests
5. Update documentation
6. Submit a pull request

## Getting Started

### Prerequisites

- Python 3.8 or higher
- Git
- Virtual environment tool (venv, conda, etc.)
- Text editor or IDE

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:

```bash
git clone https://github.com/YOUR-USERNAME/academic-workflow-suite.git
cd academic-workflow-suite
```

3. Add the upstream repository:

```bash
git remote add upstream https://github.com/academic-workflow-suite/academic-workflow-suite.git
```

## Development Setup

### 1. Create a Virtual Environment

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install Development Dependencies

```bash
pip install -e ".[dev]"
# or
pip install -r requirements-dev.txt
```

### 3. Install Pre-commit Hooks

```bash
pre-commit install
```

### 4. Verify Installation

```bash
python -m pytest
```

### Development Tools

We use the following tools:

- **pytest**: Testing framework
- **black**: Code formatting
- **isort**: Import sorting
- **flake8**: Linting
- **mypy**: Type checking
- **pre-commit**: Git hooks

## Coding Standards

### Python Style Guide

We follow [PEP 8](https://www.python.org/dev/peps/pep-0008/) with some modifications:

- Line length: 100 characters (not 79)
- Use type hints for function signatures
- Use docstrings for all public functions and classes

### Code Formatting

Use Black for code formatting:

```bash
black .
```

### Import Sorting

Use isort for import sorting:

```bash
isort .
```

### Linting

Run flake8 before committing:

```bash
flake8 .
```

### Type Checking

Run mypy for type checking:

```bash
mypy .
```

### Example Code Style

```python
"""Module docstring describing the module's purpose."""

from typing import List, Optional

import external_library

from academic_workflow_suite import internal_module


class ExampleClass:
    """Class docstring describing the class.

    Attributes:
        attribute_name: Description of the attribute.
    """

    def __init__(self, param: str) -> None:
        """Initialize the class.

        Args:
            param: Description of the parameter.
        """
        self.attribute_name = param

    def public_method(self, arg: int) -> Optional[str]:
        """Public method with type hints and docstring.

        Args:
            arg: Description of the argument.

        Returns:
            Description of the return value.

        Raises:
            ValueError: Description of when this is raised.
        """
        if arg < 0:
            raise ValueError("arg must be non-negative")

        return str(arg) if arg > 0 else None

    def _private_method(self) -> None:
        """Private methods should also have docstrings."""
        pass
```

## Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring without changing functionality
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Changes to build system or dependencies
- `ci`: Changes to CI configuration
- `chore`: Other changes that don't modify src or test files

### Examples

```
feat(citation): add BibTeX export functionality

Implement BibTeX export for citation manager. Users can now
export their citations in BibTeX format for use with LaTeX.

Closes #123
```

```
fix(parser): handle edge case in date parsing

Fix bug where dates in DD/MM/YYYY format were incorrectly parsed.
Add test cases for various date formats.

Fixes #456
```

```
docs(readme): update installation instructions

Add section on installing with conda and update Python version requirements.
```

### Best Practices

- Use the imperative mood ("Add feature" not "Added feature")
- Keep the subject line under 50 characters
- Capitalize the subject line
- Don't end the subject line with a period
- Use the body to explain what and why, not how
- Reference issues and pull requests in the footer

## Pull Request Process

### Before Submitting

1. **Update from main**: Ensure your branch is up to date

```bash
git fetch upstream
git rebase upstream/main
```

2. **Run tests**: Ensure all tests pass

```bash
pytest
```

3. **Check code style**: Run linters and formatters

```bash
black .
isort .
flake8 .
mypy .
```

4. **Update documentation**: Update relevant documentation

5. **Update CHANGELOG.md**: Add your changes to the Unreleased section

### Creating a Pull Request

1. Push your branch to your fork:

```bash
git push origin feature/your-feature-name
```

2. Go to the repository on GitHub and click "New Pull Request"

3. Fill out the pull request template completely

4. Link related issues using keywords (Fixes #123, Closes #456)

5. Request review from maintainers

### Pull Request Checklist

- [ ] Code follows the project's style guidelines
- [ ] Self-review completed
- [ ] Comments added for hard-to-understand areas
- [ ] Documentation updated
- [ ] Tests added or updated
- [ ] All tests pass
- [ ] No new warnings or errors
- [ ] CHANGELOG.md updated
- [ ] Commit messages follow conventions

### Review Process

1. **Automated checks**: CI/CD runs tests and linters
2. **Code review**: Maintainers review your code
3. **Feedback**: Address any feedback or requested changes
4. **Approval**: At least one maintainer approves
5. **Merge**: Maintainer merges your PR

### After Merge

- Delete your feature branch
- Update your local repository
- Celebrate! You're now a contributor!

## Testing Requirements

### Writing Tests

- Write tests for all new features
- Update tests when modifying existing features
- Aim for high code coverage (target: 80%+)
- Test edge cases and error conditions

### Test Structure

```python
"""Tests for the example module."""

import pytest

from academic_workflow_suite.example import ExampleClass


class TestExampleClass:
    """Tests for ExampleClass."""

    def test_initialization(self):
        """Test that ExampleClass initializes correctly."""
        obj = ExampleClass("test")
        assert obj.attribute_name == "test"

    def test_public_method_positive(self):
        """Test public_method with positive integer."""
        obj = ExampleClass("test")
        result = obj.public_method(5)
        assert result == "5"

    def test_public_method_zero(self):
        """Test public_method with zero."""
        obj = ExampleClass("test")
        result = obj.public_method(0)
        assert result is None

    def test_public_method_negative(self):
        """Test public_method raises ValueError for negative input."""
        obj = ExampleClass("test")
        with pytest.raises(ValueError):
            obj.public_method(-1)
```

### Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=academic_workflow_suite

# Run specific test file
pytest tests/test_example.py

# Run specific test
pytest tests/test_example.py::TestExampleClass::test_initialization

# Run with verbose output
pytest -v
```

### Test Coverage

Check code coverage:

```bash
pytest --cov=academic_workflow_suite --cov-report=html
open htmlcov/index.html
```

## Documentation Requirements

### Code Documentation

- Add docstrings to all public modules, classes, and functions
- Use Google-style or NumPy-style docstrings
- Include type hints in function signatures
- Add inline comments for complex logic

### User Documentation

Update relevant documentation:

- **README.md**: For major features or changes
- **Wiki pages**: For detailed guides and tutorials
- **API documentation**: For API changes
- **CHANGELOG.md**: For all user-facing changes

### Documentation Example

```python
def parse_citation(citation_text: str, format: str = "bibtex") -> dict:
    """Parse a citation string into a structured format.

    This function takes a citation in various formats and converts it
    into a standardized dictionary representation.

    Args:
        citation_text: The citation text to parse.
        format: The format of the input citation. Supported formats
            are "bibtex", "endnote", and "ris". Defaults to "bibtex".

    Returns:
        A dictionary containing the parsed citation with keys:
        - title: The title of the work
        - authors: List of author names
        - year: Publication year
        - journal: Journal name (if applicable)

    Raises:
        ValueError: If the citation format is not supported.
        ParseError: If the citation text cannot be parsed.

    Example:
        >>> citation = "@article{doe2020, title={Example}, ...}"
        >>> parsed = parse_citation(citation, format="bibtex")
        >>> print(parsed['title'])
        'Example'
    """
    # Implementation here
    pass
```

## Community

### Communication Channels

- **GitHub Discussions**: For questions and discussions
- **GitHub Issues**: For bugs and feature requests
- **Discord/Slack**: For real-time chat (if available)
- **Mailing List**: For announcements (if available)

### Getting Help

- Ask questions in GitHub Discussions
- Join community chat channels
- Tag your questions appropriately
- Be patient and respectful

### Helping Others

- Answer questions in discussions
- Review pull requests
- Improve documentation
- Share your use cases and examples

## Recognition

Contributors are recognized in:

- [CONTRIBUTORS.md](CONTRIBUTORS.md)
- Release notes
- Project website (if applicable)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see [LICENSE](LICENSE)).

## Questions?

If you have questions about contributing, please:

1. Check this document and other documentation
2. Search existing issues and discussions
3. Ask in GitHub Discussions
4. Contact maintainers if needed

Thank you for contributing to the Academic Workflow Suite!

---

**Last Updated**: 2025-11-22
