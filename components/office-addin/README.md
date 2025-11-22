# AWAP Office Add-in

A Microsoft Office Add-in for the Academic Workflow Suite (AWAP), built with ReScript for type-safe development.

## Overview

This Office Add-in integrates with Microsoft Word to provide automated assessment and plagiarism detection capabilities for academic work. It allows instructors to:

- Mark and submit Tutor-Marked Assignments (TMAs) directly from Word documents
- Generate AI-powered feedback for student submissions
- View plagiarism detection results
- Manage settings and configurations through an intuitive task pane

## Features

### Ribbon Commands

- **Mark TMA**: Extract selected content from the document and send it to the backend for processing
- **Generate Feedback**: Trigger AI-powered feedback generation for the current TMA
- **Settings**: Open the task pane to configure the add-in

### Task Pane

- TMA selection dropdown with filtering by module code
- Real-time feedback preview
- Settings management:
  - Backend URL configuration
  - API key authentication
  - Module code filtering
  - Auto-save preferences
  - WebSocket support for real-time updates
- Progress indicators for long-running operations

## Technology Stack

- **ReScript**: Type-safe language that compiles to JavaScript
- **Office.js**: Microsoft Office JavaScript API
- **Webpack**: Module bundler
- **Babel**: JavaScript transpiler
- **WebSocket**: Real-time communication (optional)

## Project Structure

```
office-addin/
├── src/
│   ├── Types.res              # Type definitions
│   ├── OfficeAPI.res          # Office.js bindings
│   ├── BackendClient.res      # HTTP client and WebSocket
│   ├── RibbonCommands.res     # Ribbon button handlers
│   ├── TaskPane.res           # Task pane UI logic
│   └── AWAPAddin.res          # Main entry point
├── tests/
│   ├── Types_test.res
│   ├── OfficeAPI_test.res
│   └── BackendClient_test.res
├── public/
│   ├── taskpane.html          # Task pane HTML template
│   ├── commands.html          # Commands page HTML
│   └── assets/                # Icons and images
├── manifest.xml               # Office Add-in manifest
├── package.json               # Dependencies
├── bsconfig.json              # ReScript configuration
├── webpack.config.js          # Webpack configuration
└── README.md                  # This file
```

## Getting Started

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Microsoft Word (Desktop or Online)
- AWAP backend server running

### Installation

1. Install dependencies:
   ```bash
   npm install
   ```

2. Build the ReScript code:
   ```bash
   npm run build
   ```

### Development

1. Start the development server:
   ```bash
   npm run dev
   ```

2. Generate self-signed certificates for HTTPS (first time only):
   ```bash
   npx office-addin-dev-certs install
   ```

3. Sideload the add-in in Word:
   ```bash
   npm start
   ```

4. The add-in will be loaded in Word with hot-reloading enabled

### Building for Production

```bash
npm run build
```

This will:
- Compile ReScript to JavaScript
- Bundle all assets with Webpack
- Generate optimized production files in `dist/`

### Testing

Run tests with:
```bash
npm test
```

Tests are written in ReScript using rescript-jest.

## Configuration

### manifest.xml

The manifest defines:
- Add-in metadata (name, description, icons)
- Required Office.js API version
- Ribbon button configurations
- Task pane settings
- Permissions required

Update the following in `manifest.xml`:
- `<Id>`: Generate a unique GUID for your add-in
- `<ProviderName>`: Your organization name
- URLs: Update localhost URLs to your deployment domain

### Backend Configuration

Configure the backend URL in the task pane settings:

1. Open Word and load the add-in
2. Click the "Settings" button in the ribbon
3. Enter your backend URL (e.g., `http://localhost:8080`)
4. Optionally enter an API key for authentication
5. Click "Save Settings"

## Usage

### Marking a TMA

1. Select the content in your Word document that represents a TMA submission
2. Click the "Mark TMA" button in the AWAP ribbon
3. The content will be sent to the backend with metadata
4. You'll receive a confirmation with the TMA ID

### Generating Feedback

1. After marking a TMA, click the "Generate Feedback" button
2. The backend will process the TMA and generate AI-powered feedback
3. Feedback will appear in the document after processing completes
4. View detailed feedback in the task pane

### Using the Task Pane

1. Click the "Settings" button to open the task pane
2. Select a previously submitted TMA from the dropdown
3. View feedback, scores, and plagiarism detection results
4. Configure settings as needed

## API Reference

### Types (Types.res)

Core type definitions:
- `tma`: TMA data structure
- `feedback`: Feedback data structure
- `settings`: Configuration settings
- `plagiarismResult`: Plagiarism detection results

### OfficeAPI (OfficeAPI.res)

Office.js wrapper functions:
- `getSelectedData`: Get selected content from document
- `setSelectedData`: Insert content into document
- `insertText`: Insert plain text
- `insertHtml`: Insert HTML content
- `initialize`: Initialize Office.js

### BackendClient (BackendClient.res)

Backend API client:
- `submitTma`: POST TMA to backend
- `getFeedback`: GET feedback for a TMA
- `requestFeedbackGeneration`: Trigger feedback generation
- `listTmas`: List all TMAs
- `healthCheck`: Check backend health
- `WebSocket.connect`: Establish WebSocket connection

### RibbonCommands (RibbonCommands.res)

Ribbon button handlers:
- `markTMA`: Handle Mark TMA button click
- `generateFeedback`: Handle Generate Feedback button click
- `loadSettings`: Load settings from localStorage
- `saveSettings`: Save settings to localStorage

### TaskPane (TaskPane.res)

Task pane UI logic:
- `initialize`: Initialize task pane
- `loadTmasList`: Load and display TMAs
- `updateFeedbackPreview`: Show feedback in preview
- `connectWebSocket`: Establish WebSocket connection
- `showStatus`: Display status messages

## Architecture

### Type Safety

ReScript provides compile-time type checking, ensuring:
- No runtime type errors
- Exhaustive pattern matching
- Safe null handling with `option<'a>`
- Type-safe async/await with promises

### Error Handling

All async operations return `result<'a, string>`:
- `Ok(value)`: Successful operation
- `Error(message)`: Failed operation with error message

### State Management

The add-in uses a simple state management approach:
- Settings stored in localStorage
- UI state managed in task pane
- WebSocket for real-time updates (optional)

### Communication Flow

```
User Action → Ribbon Command → Office.js API → Document
                ↓
         Backend Client → HTTP/WebSocket → AWAP Backend
                ↓
         Task Pane ← Feedback Response ← Backend
```

## Deployment

### Local Development

1. Use `npm run dev` for development with hot-reloading
2. Add-in runs on `https://localhost:3000`

### Production Deployment

1. Build production bundle: `npm run build`
2. Deploy `dist/` folder to a web server with HTTPS
3. Update `manifest.xml` with production URLs
4. Distribute manifest to users or publish to AppSource

### Office Add-in Store

To publish to Microsoft AppSource:
1. Create a Partner Center account
2. Prepare app package with manifest and icons
3. Submit for certification
4. Follow Microsoft's validation process

## Troubleshooting

### Office.js not loading

- Ensure you're running in a supported Office application
- Check that Office.js CDN is accessible
- Verify manifest.xml has correct API version requirements

### Backend connection errors

- Verify backend URL in settings
- Check CORS configuration on backend
- Ensure API key (if required) is correct
- Test backend health endpoint

### Add-in not appearing in Word

- Clear Office cache: `npx office-addin-dev-settings clear`
- Restart Word
- Re-sideload the add-in
- Check manifest.xml for errors: `npm run validate`

### WebSocket connection issues

- Ensure WebSocket endpoint is accessible
- Check for firewall/proxy blocking WebSocket
- Verify backend supports WebSocket protocol
- Enable WebSocket in settings

## Browser Compatibility

The add-in is tested on:
- Microsoft Word Online (latest)
- Microsoft Word Desktop (Office 2016+)
- Edge (Chromium)
- Chrome
- Safari

## Security

- All communication with backend should use HTTPS
- API keys are stored in localStorage (consider encryption)
- Never commit API keys to version control
- Validate all user input before sending to backend
- Follow OWASP security best practices

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:
- Open an issue on GitHub
- Contact: academic-workflow-suite@example.com
- Documentation: https://github.com/academic-workflow-suite

## Roadmap

- [ ] Batch TMA processing
- [ ] Offline mode support
- [ ] Enhanced plagiarism visualization
- [ ] Integration with Learning Management Systems
- [ ] Support for Excel and PowerPoint
- [ ] Mobile app companion
- [ ] Advanced analytics dashboard

## Acknowledgments

- Microsoft Office.js team
- ReScript community
- Academic Workflow Suite contributors
