# Quick Start Guide

Get up and running with the AWAP Office Add-in in 5 minutes!

## Prerequisites Check

Before you begin, make sure you have:

- [ ] Node.js 16+ installed (`node --version`)
- [ ] npm or yarn installed (`npm --version`)
- [ ] Microsoft Word (Desktop or Online access)
- [ ] AWAP backend server URL (or running locally)

## Installation (2 minutes)

```bash
# 1. Navigate to the add-in directory
cd /home/user/academic-workflow-suite/components/office-addin

# 2. Install dependencies
npm install

# 3. Build the project
npm run build
```

## Development Setup (2 minutes)

### Generate HTTPS Certificates (First Time Only)

```bash
# Generate self-signed certificates for local development
npx office-addin-dev-certs install
```

### Start Development Server

```bash
# Start the dev server with hot-reloading
npm run dev
```

The server will start at `https://localhost:3000`

## Sideload in Word (1 minute)

### Option 1: Automatic (Recommended)

```bash
# This will open Word and automatically sideload the add-in
npm start
```

### Option 2: Manual

1. Open Microsoft Word
2. Go to **Insert** → **Add-ins** → **My Add-ins**
3. Click **Manage My Add-ins**
4. Select **Upload My Add-in**
5. Browse to `manifest.xml` in this directory
6. Click **Upload**

## First Use

### 1. Configure Settings

1. In Word, find the **AWAP** ribbon tab
2. Click the **Settings** button
3. Enter your backend URL (e.g., `http://localhost:8080`)
4. (Optional) Enter API key if required
5. (Optional) Enter module code to filter TMAs
6. Click **Save Settings**

### 2. Mark a TMA

1. Type or paste some sample content in Word
2. Select the content
3. Click the **Mark TMA** button in the AWAP ribbon
4. You'll see a confirmation with the TMA ID

### 3. Generate Feedback

1. After marking a TMA, click **Generate Feedback**
2. Wait for processing (check progress in task pane)
3. Feedback will be inserted into the document

## Troubleshooting

### Add-in doesn't appear

```bash
# Clear Office cache
npx office-addin-dev-settings clear

# Restart Word and try again
```

### Certificate errors

```bash
# Reinstall certificates
npx office-addin-dev-certs install --force

# Restart the dev server
npm run dev
```

### Backend connection fails

1. Check backend is running: `curl http://localhost:8080/health`
2. Verify URL in Settings (no trailing slash)
3. Check CORS settings on backend
4. Try from browser: visit backend URL

### Office.js not loading

- Ensure you're online (Office.js loads from CDN)
- Check firewall isn't blocking Microsoft domains
- Try in Word Online as a test

## Testing Your Changes

```bash
# Run tests
npm test

# Run in watch mode during development
npm run test:watch
```

## Building for Production

```bash
# Create production build
npm run build

# Output will be in dist/ directory
```

## Next Steps

1. **Customize**: Update `manifest.xml` with your details
2. **Icons**: Add custom icons to `public/assets/`
3. **Backend**: Ensure backend is properly configured
4. **Deploy**: Follow deployment guide in README.md

## Common Commands

```bash
# Development
npm run dev          # Start dev server with watch mode
npm start           # Sideload add-in in Word

# Building
npm run build       # Production build
npm run clean       # Clean build artifacts

# Testing
npm test            # Run tests once
npm run test:watch  # Run tests in watch mode

# Validation
npm run validate    # Validate manifest.xml

# Stop
npm stop            # Stop sideloaded add-in
```

## File Structure Overview

```
office-addin/
├── src/               # ReScript source code
│   ├── Types.res      # Type definitions
│   ├── OfficeAPI.res  # Office.js bindings
│   ├── BackendClient.res  # HTTP/WebSocket client
│   ├── RibbonCommands.res # Ribbon handlers
│   ├── TaskPane.res   # Task pane UI
│   └── AWAPAddin.res  # Main entry point
├── public/            # Static assets
│   ├── taskpane.html  # Task pane template
│   └── commands.html  # Commands page
├── tests/             # Test files
└── dist/              # Build output (generated)
```

## Development Tips

1. **Hot Reload**: The dev server supports hot reloading. Save a `.res` file and it will auto-rebuild.

2. **Console Debugging**: Open browser DevTools in Word Online or use F12 Developer Tools in Word Desktop.

3. **State Inspection**: The add-in exposes a global `AWAP` object for debugging:
   ```javascript
   // In browser console
   AWAP.getState()      // View current state
   AWAP.healthCheck()   // Check system health
   ```

4. **ReScript Tips**:
   - Compile errors are caught at build time
   - Check `.bs.js` files to see compiled JavaScript
   - Use `rescript build -w` for continuous compilation

## Getting Help

- **Documentation**: See [README.md](README.md)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Issues**: Open an issue on GitHub
- **Examples**: Check the test files for usage examples

## What's Next?

- Explore the codebase in `src/`
- Read the full [README.md](README.md)
- Check out [CONTRIBUTING.md](CONTRIBUTING.md) to contribute
- Join our community discussions

---

**Happy coding!** 🚀
