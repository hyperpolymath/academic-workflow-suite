# Academic Workflow Suite Website

Professional project website for Academic Workflow Suite - a privacy-first tool for automating academic workflows.

## Overview

This is a static website built with vanilla HTML, CSS, and JavaScript. It's designed to be fast, accessible, and easy to deploy on any static hosting platform.

### Features

- **Fast & Lightweight**: Pure HTML/CSS/JS, no frameworks, loads in < 2s
- **Responsive Design**: Mobile-first design that works on all devices
- **Dark Mode**: Automatic theme switching with user preference persistence
- **Accessible**: WCAG AA compliant with semantic HTML and ARIA labels
- **SEO Optimized**: Proper meta tags, sitemap, and structured data
- **Privacy-Focused**: No tracking without consent, respects user privacy

## Directory Structure

```
website/
├── index.html              # Landing page
├── pages/                  # Additional pages
│   ├── features.html       # Feature details
│   ├── installation.html   # Installation guide
│   ├── documentation.html  # Documentation hub
│   ├── security.html       # Security & privacy
│   ├── about.html          # About the project
│   └── download.html       # Download page
├── blog/                   # Blog section
│   ├── index.html          # Blog listing
│   └── posts/              # Individual blog posts
│       └── getting-started-guide.html
├── assets/                 # Static assets
│   ├── css/
│   │   └── style.css       # Main stylesheet
│   ├── js/
│   │   └── main.js         # Interactive features
│   └── images/             # Images and graphics
├── api/                    # API documentation
│   └── swagger-ui/
│       └── index.html      # Interactive API docs
├── build.sh                # Build script
├── Makefile                # Build automation
└── README.md               # This file
```

## Quick Start

### Local Development

Serve the site locally using Python's built-in server:

```bash
# Python 3
python3 -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000
```

Then open http://localhost:8000 in your browser.

### Using Make

```bash
# Show available commands
make help

# Serve locally
make serve

# Build optimized version
make build

# Build and serve
make serve-build
```

## Building for Production

### Prerequisites

For optimization features, install these tools (optional):

```bash
# Using npm
npm install -g clean-css-cli uglify-js html-minifier

# Or using the Makefile
make install
```

### Build

```bash
# Using the build script
./build.sh

# Or using Make
make build
```

This will:
1. Create a `dist/` directory
2. Copy and minify all HTML, CSS, and JS files
3. Optimize images
4. Generate sitemap.xml and RSS feed
5. Create .htaccess for Apache servers

### Build Output

The optimized site will be in the `dist/` directory, ready for deployment.

## Deployment

### GitHub Pages

```bash
make deploy-gh-pages
```

This will:
- Build the optimized site
- Create/update the `gh-pages` branch
- Push to GitHub

Then enable GitHub Pages in your repository settings.

### Netlify

1. **Using Netlify CLI:**
   ```bash
   make deploy-netlify
   ```

2. **Using Netlify UI:**
   - Connect your GitHub repository
   - Build command: `./build.sh`
   - Publish directory: `dist`

### Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel
```

### Other Hosting

Any static hosting provider works:
- AWS S3 + CloudFront
- Google Cloud Storage
- Cloudflare Pages
- Surge.sh
- Render

Just upload the contents of the `dist/` directory.

## Customization

### Colors & Branding

Edit the CSS custom properties in `assets/css/style.css`:

```css
:root {
  --color-primary: #2563eb;      /* Main brand color */
  --color-primary-dark: #1e40af; /* Darker shade */
  /* ... more variables */
}
```

### Content

All content is in HTML files. Edit the files directly:
- **Landing page**: `index.html`
- **Feature details**: `pages/features.html`
- **Documentation**: `pages/documentation.html`
- **Blog posts**: `blog/posts/*.html`

### Adding Blog Posts

1. Create a new HTML file in `blog/posts/`
2. Use `blog/posts/getting-started-guide.html` as a template
3. Add entry to `blog/index.html`
4. Update RSS feed in build script (or generate automatically)

### API Documentation

Edit the OpenAPI specification in `api/swagger-ui/index.html`:

```javascript
const spec = {
  openapi: "3.0.3",
  info: { /* ... */ },
  paths: { /* ... */ }
};
```

## Performance

### Optimization Checklist

- [x] Minified CSS and JavaScript
- [x] Optimized images
- [x] Lazy loading for images
- [x] Browser caching headers
- [x] Gzip/Brotli compression
- [x] Minimal dependencies (no frameworks)
- [x] Inline critical CSS (optional)
- [x] Preconnect to external domains

### Testing Performance

```bash
# Run Lighthouse audit
make lighthouse

# Or manually
lighthouse http://localhost:8000 --view
```

Target scores:
- Performance: 95+
- Accessibility: 100
- Best Practices: 100
- SEO: 100

## Accessibility

### Features

- Semantic HTML5 elements
- ARIA labels and roles
- Keyboard navigation support
- Focus indicators
- Skip to main content link
- Alt text for all images
- Sufficient color contrast (WCAG AA)
- Screen reader friendly

### Testing

```bash
# Using axe-core
npm install -g @axe-core/cli
axe http://localhost:8000

# Manual testing
# - Navigate with keyboard only
# - Test with screen reader (NVDA, JAWS, VoiceOver)
# - Check color contrast
```

## Browser Support

Supports all modern browsers:
- Chrome/Edge (last 2 versions)
- Firefox (last 2 versions)
- Safari (last 2 versions)
- Mobile Safari (iOS 12+)
- Chrome Mobile (Android 5+)

Progressive enhancement ensures basic functionality in older browsers.

## Development Workflow

### Adding a New Page

1. Create HTML file in `pages/`
2. Copy header/footer from existing page
3. Add navigation link in all pages
4. Update sitemap (automatic in build)
5. Test responsiveness and accessibility

### Updating Styles

1. Edit `assets/css/style.css`
2. Use CSS custom properties for consistency
3. Test in light and dark modes
4. Check mobile responsiveness

### Adding JavaScript Features

1. Edit `assets/js/main.js`
2. Follow existing module pattern
3. Ensure no errors in console
4. Test with JavaScript disabled (progressive enhancement)

## Maintenance

### Regular Tasks

- **Weekly**: Review and respond to feedback
- **Monthly**: Update blog content, check for broken links
- **Quarterly**: Update dependencies, run security audit
- **Annually**: Review and update documentation

### Updating Content

```bash
# Edit files
vim pages/features.html

# Test locally
make serve

# Build
make build

# Deploy
make deploy-gh-pages
```

## Troubleshooting

### Build fails

```bash
# Clean and rebuild
make clean
make build
```

### CSS/JS not updating

- Clear browser cache (Ctrl+Shift+R)
- Check browser console for errors
- Verify file paths are correct

### Images not loading

- Check file paths (case-sensitive on Linux)
- Ensure images are in `assets/images/`
- Verify image optimization didn't corrupt files

### Dark mode not working

- Check localStorage in browser console
- Verify theme toggle JavaScript loaded
- Check for console errors

## Contributing

### Setup Development Environment

```bash
# Clone repository
git clone https://github.com/academic-workflow-suite/academic-workflow-suite.git
cd academic-workflow-suite/website

# Serve locally
make serve
```

### Making Changes

1. Create a new branch
2. Make your changes
3. Test locally
4. Build and verify
5. Submit pull request

### Code Style

- **HTML**: Semantic, indented with 2 spaces
- **CSS**: BEM methodology, use custom properties
- **JavaScript**: ES6+, module pattern, JSDoc comments
- **Accessibility**: Always consider keyboard and screen reader users

## License

This website is part of the Academic Workflow Suite project and is released under the [MIT License](../LICENSE).

## Support

- **Issues**: [GitHub Issues](https://github.com/academic-workflow-suite/issues)
- **Discussions**: [GitHub Discussions](https://github.com/academic-workflow-suite/discussions)
- **Email**: hello@academic-workflow.org

## Credits

Built with:
- [Inter](https://rsms.me/inter/) - Font family
- [Swagger UI](https://swagger.io/tools/swagger-ui/) - API documentation
- Icons: Custom SVG icons

---

**Made with care for the academic community** 🎓
