# Contributing to AWAP Office Add-in

Thank you for your interest in contributing to the Academic Workflow Suite Office Add-in! This document provides guidelines and instructions for contributors.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Install dependencies: `npm install`
4. Create a feature branch: `git checkout -b feature/your-feature-name`

## Development Setup

### Prerequisites

- Node.js 16+
- npm or yarn
- Microsoft Word (Desktop or Online)
- Git

### Building the Project

```bash
# Install dependencies
npm install

# Build ReScript code
npm run build

# Start development server
npm run dev
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run with coverage
npm run test:coverage
```

## Code Style

### ReScript

- Use meaningful variable and function names
- Add type annotations for public APIs
- Write pure functions when possible
- Avoid mutability unless necessary
- Use pattern matching for enums and variants

### Example

```rescript
// Good
let calculateScore = (answers: array<answer>, total: int): float => {
  let correct = answers->Array.filter(a => a.isCorrect)->Array.length
  Float.fromInt(correct) /. Float.fromInt(total) *. 100.0
}

// Avoid
let calc = (a, t) => {
  let c = a->Array.filter(x => x.isCorrect)->Array.length
  Float.fromInt(c) /. Float.fromInt(t) *. 100.0
}
```

### File Organization

- One module per file
- Group related functionality
- Keep files focused and small (<500 lines)
- Use meaningful file names

### Comments

```rescript
// Use single-line comments for brief explanations
let apiKey = getApiKey() // Retrieved from settings

/* Use multi-line comments for detailed explanations
 * or to describe complex algorithms
 */
```

## Testing Guidelines

### Unit Tests

- Test pure functions thoroughly
- Mock external dependencies (Office.js, fetch)
- Test error cases and edge cases
- Aim for >80% code coverage

### Test Structure

```rescript
describe("ModuleName", () => {
  describe("functionName", () => {
    test("should do expected behavior", () => {
      // Arrange
      let input = "test"

      // Act
      let result = functionName(input)

      // Assert
      expect(result)->toBe("expected")
    })
  })
})
```

### Integration Tests

- Test complete workflows
- Verify component interactions
- Use realistic test data

## Pull Request Process

1. **Update Documentation**: Ensure README.md and code comments are current
2. **Add Tests**: All new features must include tests
3. **Pass CI**: All tests and linting must pass
4. **Update Changelog**: Add entry to CHANGELOG.md (if exists)
5. **Request Review**: Tag relevant maintainers

### PR Title Format

Use conventional commits:

- `feat: Add new feature`
- `fix: Fix bug in component`
- `docs: Update documentation`
- `test: Add missing tests`
- `refactor: Refactor module`
- `chore: Update dependencies`

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How was this tested?

## Checklist
- [ ] Tests pass locally
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] No new warnings
```

## Commit Messages

Follow conventional commits:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Example:
```
feat(ribbon): Add export TMA button

Add new ribbon button to export TMA data as JSON.
Includes error handling and user feedback.

Closes #123
```

## Architecture Guidelines

### State Management

- Keep state minimal and local when possible
- Use localStorage for persistent settings
- Document state shape with types

### Error Handling

- Always handle errors gracefully
- Return `result<'a, string>` for operations that can fail
- Provide meaningful error messages to users

### Async Operations

- Use async/await consistently
- Handle promise rejections
- Show loading states for long operations

### Office.js Integration

- Wrap Office.js calls in type-safe functions
- Handle both success and error cases
- Test in both Word Online and Desktop

## Performance

- Minimize DOM operations
- Debounce user input
- Use efficient data structures
- Avoid unnecessary re-renders
- Lazy load when appropriate

## Security

- Never commit API keys or secrets
- Validate all user input
- Use HTTPS for all backend communication
- Follow OWASP security guidelines
- Sanitize HTML content before insertion

## Accessibility

- Use semantic HTML
- Add ARIA labels to interactive elements
- Ensure keyboard navigation works
- Test with screen readers
- Maintain sufficient color contrast

## Documentation

### Code Documentation

```rescript
// Document public APIs with clear descriptions
// and type signatures

// Calculates the plagiarism similarity score
// between two text documents
// Returns a value between 0.0 (no similarity)
// and 100.0 (identical)
let calculateSimilarity = (
  text1: string,
  text2: string
): float => {
  // Implementation
}
```

### README Updates

Update README.md when:
- Adding new features
- Changing configuration
- Modifying setup process
- Updating dependencies

## Issue Reporting

### Bug Reports

Include:
- Office version and platform
- Browser (if Word Online)
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable
- Console errors

### Feature Requests

Include:
- Use case description
- Proposed solution
- Alternative solutions considered
- Additional context

## Code Review

When reviewing:
- Be constructive and respectful
- Test the changes locally
- Check for edge cases
- Verify documentation is updated
- Ensure tests are adequate

## Release Process

1. Update version in package.json
2. Update CHANGELOG.md
3. Create git tag
4. Build production bundle
5. Test in production environment
6. Create GitHub release

## Questions?

- Open a discussion on GitHub
- Contact maintainers
- Check existing issues and PRs

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT).

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Assume good intentions
- Report inappropriate behavior

Thank you for contributing to AWAP Office Add-in!
