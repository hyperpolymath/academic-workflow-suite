# Makefile for Academic Workflow Suite Website
# Handles building, optimization, and deployment

.PHONY: help install build serve clean deploy optimize test

# Variables
BUILD_DIR := dist
SRC_DIR := .
NODE_BIN := ./node_modules/.bin

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Academic Workflow Suite Website Build System$(NC)"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

install: ## Install dependencies (if using npm for build tools)
	@echo "$(BLUE)Installing dependencies...$(NC)"
	npm install -D html-minifier clean-css-cli uglify-js imagemin-cli
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

build: clean ## Build the static site
	@echo "$(BLUE)Building static site...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@./build.sh
	@echo "$(GREEN)✓ Build complete! Output in $(BUILD_DIR)/$(NC)"

serve: ## Start local development server
	@echo "$(BLUE)Starting development server on http://localhost:8000$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	python3 -m http.server 8000 || python -m SimpleHTTPServer 8000

serve-build: build ## Serve the built site
	@echo "$(BLUE)Starting server for built site on http://localhost:8000$(NC)"
	cd $(BUILD_DIR) && python3 -m http.server 8000

clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	rm -rf $(BUILD_DIR)
	rm -f *.log
	@echo "$(GREEN)✓ Clean complete$(NC)"

optimize: ## Optimize images and assets
	@echo "$(BLUE)Optimizing assets...$(NC)"
	@# Minify CSS
	@if command -v cleancss >/dev/null 2>&1; then \
		find assets/css -name "*.css" -exec sh -c 'cleancss {} -o $${0%.css}.min.css' {} \;; \
		echo "$(GREEN)✓ CSS minified$(NC)"; \
	else \
		echo "$(YELLOW)! cleancss not found, skipping CSS minification$(NC)"; \
	fi
	@# Minify JavaScript
	@if command -v uglifyjs >/dev/null 2>&1; then \
		find assets/js -name "*.js" ! -name "*.min.js" -exec sh -c 'uglifyjs {} -c -m -o $${0%.js}.min.js' {} \;; \
		echo "$(GREEN)✓ JavaScript minified$(NC)"; \
	else \
		echo "$(YELLOW)! uglifyjs not found, skipping JS minification$(NC)"; \
	fi
	@# Optimize images (if any exist)
	@if command -v imagemin >/dev/null 2>&1 && [ -d assets/images ]; then \
		imagemin assets/images/* --out-dir=assets/images/optimized; \
		echo "$(GREEN)✓ Images optimized$(NC)"; \
	fi

validate: ## Validate HTML files
	@echo "$(BLUE)Validating HTML...$(NC)"
	@if command -v html5validator >/dev/null 2>&1; then \
		html5validator --root . --also-check-css; \
		echo "$(GREEN)✓ HTML validation complete$(NC)"; \
	else \
		echo "$(YELLOW)! html5validator not found, install with: pip install html5validator$(NC)"; \
	fi

test: ## Run tests
	@echo "$(BLUE)Running tests...$(NC)"
	@# Check for broken links
	@if command -v linkchecker >/dev/null 2>&1; then \
		make serve & SERVER_PID=$$!; \
		sleep 2; \
		linkchecker http://localhost:8000; \
		kill $$SERVER_PID; \
	else \
		echo "$(YELLOW)! linkchecker not found$(NC)"; \
	fi
	@echo "$(GREEN)✓ Tests complete$(NC)"

deploy-gh-pages: build ## Deploy to GitHub Pages
	@echo "$(BLUE)Deploying to GitHub Pages...$(NC)"
	@if [ -d .git ]; then \
		git checkout -B gh-pages; \
		cp -r $(BUILD_DIR)/* .; \
		git add .; \
		git commit -m "Deploy to GitHub Pages"; \
		git push origin gh-pages --force; \
		git checkout main; \
		echo "$(GREEN)✓ Deployed to GitHub Pages$(NC)"; \
	else \
		echo "$(RED)! Not a git repository$(NC)"; \
		exit 1; \
	fi

deploy-netlify: build ## Deploy to Netlify
	@echo "$(BLUE)Deploying to Netlify...$(NC)"
	@if command -v netlify >/dev/null 2>&1; then \
		netlify deploy --prod --dir=$(BUILD_DIR); \
		echo "$(GREEN)✓ Deployed to Netlify$(NC)"; \
	else \
		echo "$(YELLOW)! Netlify CLI not found. Install with: npm install -g netlify-cli$(NC)"; \
	fi

stats: ## Show website statistics
	@echo "$(BLUE)Website Statistics$(NC)"
	@echo ""
	@echo "HTML files: $$(find . -name "*.html" ! -path "./node_modules/*" ! -path "./$(BUILD_DIR)/*" | wc -l)"
	@echo "CSS files: $$(find assets/css -name "*.css" 2>/dev/null | wc -l)"
	@echo "JS files: $$(find assets/js -name "*.js" 2>/dev/null | wc -l)"
	@echo "Total size: $$(du -sh . 2>/dev/null | cut -f1)"
	@if [ -d $(BUILD_DIR) ]; then \
		echo "Build size: $$(du -sh $(BUILD_DIR) 2>/dev/null | cut -f1)"; \
	fi

lighthouse: ## Run Lighthouse performance audit
	@echo "$(BLUE)Running Lighthouse audit...$(NC)"
	@if command -v lighthouse >/dev/null 2>&1; then \
		make serve & SERVER_PID=$$!; \
		sleep 2; \
		lighthouse http://localhost:8000 \
			--output=html \
			--output-path=./lighthouse-report.html \
			--view; \
		kill $$SERVER_PID; \
		echo "$(GREEN)✓ Lighthouse report generated$(NC)"; \
	else \
		echo "$(YELLOW)! Lighthouse not found. Install with: npm install -g lighthouse$(NC)"; \
	fi

# Default target
.DEFAULT_GOAL := help
