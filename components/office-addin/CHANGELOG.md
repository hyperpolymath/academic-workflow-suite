# Changelog

All notable changes to the AWAP Office Add-in will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Batch TMA processing
- Offline mode support
- Enhanced plagiarism visualization
- LMS integration (Canvas, Moodle, Blackboard)
- Mobile companion app
- Analytics dashboard

## [1.0.0] - 2025-11-22

### Added
- Initial release of AWAP Office Add-in
- ReScript-based type-safe implementation
- Ribbon commands for TMA management:
  - Mark TMA button
  - Generate Feedback button
  - Settings button
- Task pane with:
  - TMA selection dropdown
  - Feedback preview
  - Settings configuration
  - Progress indicators
- Office.js API bindings for Word integration
- Backend HTTP client with:
  - TMA submission
  - Feedback retrieval
  - Feedback generation requests
  - TMA listing
  - Health check
- WebSocket support for real-time updates
- localStorage-based settings persistence
- Comprehensive type definitions for:
  - TMAs
  - Feedback
  - Plagiarism results
  - Settings
  - UI state
- Error handling with Result types
- Accessible UI with ARIA labels
- Webpack bundling configuration
- Development server with hot-reloading
- Test suite with rescript-jest:
  - Types tests
  - OfficeAPI tests
  - BackendClient tests
- Documentation:
  - README with setup instructions
  - CONTRIBUTING guidelines
  - Assets documentation
  - Code examples

### Technical Details
- Built with ReScript 11.0.1
- Targets Office.js API version 1.3+
- Compatible with Word Online and Word Desktop
- Webpack 5 for bundling
- Babel for transpilation
- Self-signed certificates for local HTTPS

### Known Limitations
- Requires manual selection of content for document-wide operations
- WebSocket support is optional and disabled by default
- Icons are placeholders (need custom design)
- API key stored in localStorage (not encrypted)

## [0.1.0] - Development

### Added
- Project initialization
- Basic structure and configuration
- ReScript setup
- Office.js integration proof of concept

---

## Version History

- **1.0.0**: First production-ready release
- **0.1.0**: Development preview

## Upgrade Guide

### From 0.1.0 to 1.0.0

1. Install new dependencies:
   ```bash
   npm install
   ```

2. Update manifest.xml with new ribbon commands

3. Clear browser/Office cache:
   ```bash
   npx office-addin-dev-settings clear
   ```

4. Rebuild and restart:
   ```bash
   npm run build
   npm start
   ```

## Breaking Changes

### 1.0.0
- Initial release - no breaking changes from development version

## Deprecations

None currently.

## Security

Report security vulnerabilities to: security@academic-workflow-suite.example.com

## Links

- [Repository](https://github.com/academic-workflow-suite)
- [Issues](https://github.com/academic-workflow-suite/issues)
- [Documentation](https://github.com/academic-workflow-suite/wiki)
