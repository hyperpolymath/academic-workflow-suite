#!/usr/bin/env bash

# Build script for Academic Workflow Suite Website
# Generates optimized static site ready for deployment

set -e  # Exit on error

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
BUILD_DIR="dist"
SRC_DIR="."

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create build directory
create_build_dir() {
    log_info "Creating build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"/{pages,assets/{css,js,images},blog/posts,api/swagger-ui}
    log_success "Build directory created"
}

# Copy HTML files
copy_html() {
    log_info "Copying HTML files..."

    # Copy root HTML files
    find . -maxdepth 1 -name "*.html" -exec cp {} "$BUILD_DIR/" \;

    # Copy page HTML files
    if [ -d "pages" ]; then
        cp -r pages/*.html "$BUILD_DIR/pages/" 2>/dev/null || true
    fi

    # Copy blog files
    if [ -d "blog" ]; then
        cp blog/index.html "$BUILD_DIR/blog/" 2>/dev/null || true
        if [ -d "blog/posts" ]; then
            cp -r blog/posts/*.html "$BUILD_DIR/blog/posts/" 2>/dev/null || true
        fi
    fi

    # Copy API documentation
    if [ -d "api/swagger-ui" ]; then
        cp -r api/swagger-ui/* "$BUILD_DIR/api/swagger-ui/" 2>/dev/null || true
    fi

    log_success "HTML files copied"
}

# Optimize and copy CSS
copy_css() {
    log_info "Processing CSS files..."

    if [ -d "assets/css" ]; then
        for css_file in assets/css/*.css; do
            if [ -f "$css_file" ]; then
                filename=$(basename "$css_file")

                if command_exists cleancss; then
                    # Minify CSS
                    cleancss "$css_file" -o "$BUILD_DIR/assets/css/$filename"
                    log_success "Minified $filename"
                else
                    # Just copy if cleancss not available
                    cp "$css_file" "$BUILD_DIR/assets/css/"
                    log_warning "cleancss not found, copied $filename without minification"
                fi
            fi
        done
    fi
}

# Optimize and copy JavaScript
copy_js() {
    log_info "Processing JavaScript files..."

    if [ -d "assets/js" ]; then
        for js_file in assets/js/*.js; do
            if [ -f "$js_file" ]; then
                filename=$(basename "$js_file")

                if command_exists uglifyjs; then
                    # Minify JavaScript
                    uglifyjs "$js_file" -c -m -o "$BUILD_DIR/assets/js/$filename"
                    log_success "Minified $filename"
                else
                    # Just copy if uglifyjs not available
                    cp "$js_file" "$BUILD_DIR/assets/js/"
                    log_warning "uglifyjs not found, copied $filename without minification"
                fi
            fi
        done
    fi
}

# Copy and optimize images
copy_images() {
    log_info "Processing images..."

    if [ -d "assets/images" ]; then
        if command_exists imagemin; then
            # Optimize images
            imagemin assets/images/* --out-dir="$BUILD_DIR/assets/images"
            log_success "Images optimized"
        else
            # Just copy if imagemin not available
            cp -r assets/images/* "$BUILD_DIR/assets/images/" 2>/dev/null || true
            log_warning "imagemin not found, copied images without optimization"
        fi
    fi
}

# Copy other assets
copy_other_assets() {
    log_info "Copying other assets..."

    # Copy fonts if they exist
    if [ -d "assets/fonts" ]; then
        mkdir -p "$BUILD_DIR/assets/fonts"
        cp -r assets/fonts/* "$BUILD_DIR/assets/fonts/"
    fi

    # Copy any other files in root (like favicon, robots.txt, etc.)
    for file in favicon.ico robots.txt sitemap.xml .htaccess; do
        if [ -f "$file" ]; then
            cp "$file" "$BUILD_DIR/"
        fi
    done

    log_success "Other assets copied"
}

# Generate sitemap
generate_sitemap() {
    log_info "Generating sitemap..."

    SITEMAP_FILE="$BUILD_DIR/sitemap.xml"
    BASE_URL="https://academic-workflow.org"

    cat > "$SITEMAP_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
EOF

    # Find all HTML files and add to sitemap
    find "$BUILD_DIR" -name "*.html" | while read -r file; do
        # Get relative path
        rel_path="${file#$BUILD_DIR/}"

        # Convert index.html to directory URL
        if [[ "$rel_path" == "index.html" ]]; then
            url="$BASE_URL/"
        elif [[ "$rel_path" == */index.html ]]; then
            url="$BASE_URL/${rel_path%/index.html}/"
        else
            url="$BASE_URL/$rel_path"
        fi

        # Get last modified date
        if [[ "$OSTYPE" == "darwin"* ]]; then
            lastmod=$(stat -f "%Sm" -t "%Y-%m-%d" "$file")
        else
            lastmod=$(date -r "$file" +%Y-%m-%d)
        fi

        cat >> "$SITEMAP_FILE" << EOF
  <url>
    <loc>$url</loc>
    <lastmod>$lastmod</lastmod>
  </url>
EOF
    done

    echo "</urlset>" >> "$SITEMAP_FILE"
    log_success "Sitemap generated"
}

# Generate RSS feed for blog
generate_rss() {
    log_info "Generating RSS feed..."

    RSS_FILE="$BUILD_DIR/blog/rss.xml"
    BASE_URL="https://academic-workflow.org"

    mkdir -p "$BUILD_DIR/blog"

    cat > "$RSS_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Academic Workflow Suite Blog</title>
    <description>Tutorials, best practices, and updates from the Academic Workflow Suite community</description>
    <link>$BASE_URL/blog/</link>
    <atom:link href="$BASE_URL/blog/rss.xml" rel="self" type="application/rss+xml"/>
    <language>en-us</language>
    <lastBuildDate>$(date -R)</lastBuildDate>
    <item>
      <title>Getting Started with Academic Workflow Suite</title>
      <link>$BASE_URL/blog/posts/getting-started-guide.html</link>
      <description>Complete guide to getting started with Academic Workflow Suite - from installation to your first marked assignment.</description>
      <pubDate>Fri, 22 Nov 2025 10:00:00 +0000</pubDate>
      <guid>$BASE_URL/blog/posts/getting-started-guide.html</guid>
    </item>
  </channel>
</rss>
EOF

    log_success "RSS feed generated"
}

# Create .htaccess for Apache servers
create_htaccess() {
    log_info "Creating .htaccess..."

    cat > "$BUILD_DIR/.htaccess" << 'EOF'
# Academic Workflow Suite - Apache Configuration

# Enable compression
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
</IfModule>

# Enable browser caching
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType text/html "access plus 1 hour"
  ExpiresByType text/css "access plus 1 month"
  ExpiresByType application/javascript "access plus 1 month"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType image/jpg "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
  ExpiresByType image/svg+xml "access plus 1 year"
</IfModule>

# Security headers
<IfModule mod_headers.c>
  Header set X-Content-Type-Options "nosniff"
  Header set X-Frame-Options "SAMEORIGIN"
  Header set X-XSS-Protection "1; mode=block"
  Header set Referrer-Policy "strict-origin-when-cross-origin"
</IfModule>

# Redirect HTTP to HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Custom error pages
ErrorDocument 404 /404.html
EOF

    log_success ".htaccess created"
}

# Generate build metadata
generate_metadata() {
    log_info "Generating build metadata..."

    cat > "$BUILD_DIR/build-info.json" << EOF
{
  "build_date": "$(date -Iseconds)",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "git_branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')",
  "version": "1.0.0"
}
EOF

    log_success "Build metadata generated"
}

# Calculate and display build size
show_build_stats() {
    log_info "Build Statistics"
    echo ""
    echo "  HTML files: $(find "$BUILD_DIR" -name "*.html" | wc -l | tr -d ' ')"
    echo "  CSS files: $(find "$BUILD_DIR" -name "*.css" | wc -l | tr -d ' ')"
    echo "  JS files: $(find "$BUILD_DIR" -name "*.js" | wc -l | tr -d ' ')"
    echo "  Total size: $(du -sh "$BUILD_DIR" | cut -f1)"
    echo ""
}

# Main build process
main() {
    echo ""
    log_info "======================================"
    log_info "Academic Workflow Suite Website Build"
    log_info "======================================"
    echo ""

    create_build_dir
    copy_html
    copy_css
    copy_js
    copy_images
    copy_other_assets
    generate_sitemap
    generate_rss
    create_htaccess
    generate_metadata

    echo ""
    show_build_stats

    log_success "======================================"
    log_success "Build completed successfully!"
    log_success "Output directory: $BUILD_DIR"
    log_success "======================================"
    echo ""
}

# Run main function
main "$@"
