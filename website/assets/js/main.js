/**
 * Academic Workflow Suite - Main JavaScript
 * Handles navigation, dark mode, smooth scrolling, and interactive features
 */

(function() {
  'use strict';

  // ==================
  // Theme Management
  // ==================
  const ThemeManager = {
    init() {
      this.themeToggle = document.querySelector('.theme-toggle');
      this.currentTheme = localStorage.getItem('theme') || 'light';

      // Apply saved theme
      this.applyTheme(this.currentTheme);

      // Setup event listener
      if (this.themeToggle) {
        this.themeToggle.addEventListener('click', () => this.toggleTheme());
      }
    },

    applyTheme(theme) {
      document.documentElement.setAttribute('data-theme', theme);
      localStorage.setItem('theme', theme);
      this.currentTheme = theme;
    },

    toggleTheme() {
      const newTheme = this.currentTheme === 'light' ? 'dark' : 'light';
      this.applyTheme(newTheme);

      // Announce to screen readers
      this.announceThemeChange(newTheme);
    },

    announceThemeChange(theme) {
      const announcement = document.createElement('div');
      announcement.setAttribute('role', 'status');
      announcement.setAttribute('aria-live', 'polite');
      announcement.className = 'sr-only';
      announcement.textContent = `Theme changed to ${theme} mode`;
      document.body.appendChild(announcement);
      setTimeout(() => announcement.remove(), 1000);
    }
  };

  // ==================
  // Navigation
  // ==================
  const Navigation = {
    init() {
      this.navToggle = document.querySelector('.nav-toggle');
      this.navMenu = document.querySelector('.nav-menu');
      this.header = document.querySelector('.header');

      if (this.navToggle && this.navMenu) {
        this.navToggle.addEventListener('click', () => this.toggleMenu());

        // Close menu when clicking outside
        document.addEventListener('click', (e) => {
          if (!e.target.closest('.nav')) {
            this.closeMenu();
          }
        });

        // Close menu on escape key
        document.addEventListener('keydown', (e) => {
          if (e.key === 'Escape') {
            this.closeMenu();
          }
        });
      }

      // Highlight active nav item based on current page
      this.highlightActiveNav();

      // Sticky header effect
      this.handleStickyHeader();
    },

    toggleMenu() {
      const isExpanded = this.navToggle.getAttribute('aria-expanded') === 'true';
      this.navToggle.setAttribute('aria-expanded', !isExpanded);
      this.navMenu.classList.toggle('active');
    },

    closeMenu() {
      this.navToggle.setAttribute('aria-expanded', 'false');
      this.navMenu.classList.remove('active');
    },

    highlightActiveNav() {
      const currentPath = window.location.pathname;
      const navLinks = document.querySelectorAll('.nav-menu a:not(.btn)');

      navLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (href && (currentPath === href || currentPath.startsWith(href) && href !== '/')) {
          link.classList.add('active');
        }
      });
    },

    handleStickyHeader() {
      let lastScroll = 0;

      window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;

        if (currentScroll <= 0) {
          this.header.classList.remove('scroll-up');
          return;
        }

        if (currentScroll > lastScroll && !this.header.classList.contains('scroll-down')) {
          // Scrolling down
          this.header.classList.remove('scroll-up');
          this.header.classList.add('scroll-down');
        } else if (currentScroll < lastScroll && this.header.classList.contains('scroll-down')) {
          // Scrolling up
          this.header.classList.remove('scroll-down');
          this.header.classList.add('scroll-up');
        }

        lastScroll = currentScroll;
      });
    }
  };

  // ==================
  // Smooth Scrolling
  // ==================
  const SmoothScroll = {
    init() {
      document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', (e) => {
          const href = anchor.getAttribute('href');

          // Skip if href is just "#"
          if (href === '#') return;

          const target = document.querySelector(href);
          if (target) {
            e.preventDefault();
            this.scrollToElement(target);

            // Update URL without triggering scroll
            if (history.pushState) {
              history.pushState(null, null, href);
            }

            // Focus the target for accessibility
            target.setAttribute('tabindex', '-1');
            target.focus({ preventScroll: true });
          }
        });
      });
    },

    scrollToElement(element) {
      const headerOffset = 80;
      const elementPosition = element.getBoundingClientRect().top;
      const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

      window.scrollTo({
        top: offsetPosition,
        behavior: 'smooth'
      });
    }
  };

  // ==================
  // Form Validation
  // ==================
  const FormValidation = {
    init() {
      const forms = document.querySelectorAll('form[data-validate]');
      forms.forEach(form => {
        form.addEventListener('submit', (e) => this.handleSubmit(e, form));
      });
    },

    handleSubmit(e, form) {
      e.preventDefault();

      // Clear previous errors
      this.clearErrors(form);

      // Validate
      const isValid = this.validateForm(form);

      if (isValid) {
        // Form is valid, could submit via AJAX here
        console.log('Form is valid');
        // form.submit(); // Uncomment to actually submit
      }
    },

    validateForm(form) {
      const inputs = form.querySelectorAll('input[required], textarea[required]');
      let isValid = true;

      inputs.forEach(input => {
        if (!input.value.trim()) {
          this.showError(input, 'This field is required');
          isValid = false;
        } else if (input.type === 'email' && !this.isValidEmail(input.value)) {
          this.showError(input, 'Please enter a valid email address');
          isValid = false;
        }
      });

      return isValid;
    },

    showError(input, message) {
      const error = document.createElement('div');
      error.className = 'form-error';
      error.textContent = message;
      error.setAttribute('role', 'alert');

      input.classList.add('error');
      input.parentNode.appendChild(error);
    },

    clearErrors(form) {
      form.querySelectorAll('.form-error').forEach(error => error.remove());
      form.querySelectorAll('.error').forEach(input => input.classList.remove('error'));
    },

    isValidEmail(email) {
      return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }
  };

  // ==================
  // Tabs (for Download page)
  // ==================
  const Tabs = {
    init() {
      const tabButtons = document.querySelectorAll('.tab-button');

      tabButtons.forEach(button => {
        button.addEventListener('click', (e) => {
          const tabId = button.getAttribute('data-tab');
          this.switchTab(tabId, button);
        });
      });
    },

    switchTab(tabId, button) {
      // Remove active class from all buttons and contents
      document.querySelectorAll('.tab-button').forEach(btn => btn.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));

      // Add active class to clicked button and corresponding content
      button.classList.add('active');
      const content = document.getElementById(tabId);
      if (content) {
        content.classList.add('active');
      }
    }
  };

  // ==================
  // Accordion (for Installation page)
  // ==================
  const Accordion = {
    init() {
      const accordionHeaders = document.querySelectorAll('.accordion-header');

      accordionHeaders.forEach(header => {
        header.addEventListener('click', () => this.toggleAccordion(header));
      });
    },

    toggleAccordion(header) {
      const item = header.parentElement;
      const content = item.querySelector('.accordion-content');
      const isExpanded = header.getAttribute('aria-expanded') === 'true';

      // Toggle this item
      header.setAttribute('aria-expanded', !isExpanded);
      content.style.maxHeight = isExpanded ? '0' : content.scrollHeight + 'px';
    }
  };

  // ==================
  // Search Functionality (Documentation page)
  // ==================
  const Search = {
    init() {
      const searchInput = document.querySelector('input[type="search"]');

      if (searchInput) {
        let debounceTimer;
        searchInput.addEventListener('input', (e) => {
          clearTimeout(debounceTimer);
          debounceTimer = setTimeout(() => {
            this.performSearch(e.target.value);
          }, 300);
        });
      }
    },

    performSearch(query) {
      // This would integrate with a search service or static search index
      console.log('Searching for:', query);

      // Placeholder for search functionality
      // In production, this could use Algolia, Lunr.js, or similar
    }
  };

  // ==================
  // Copy Code Button
  // ==================
  const CodeCopy = {
    init() {
      const codeBlocks = document.querySelectorAll('.code-block');

      codeBlocks.forEach(block => {
        const button = this.createCopyButton();
        block.style.position = 'relative';
        block.appendChild(button);

        button.addEventListener('click', () => {
          const code = block.querySelector('code').textContent;
          this.copyToClipboard(code, button);
        });
      });
    },

    createCopyButton() {
      const button = document.createElement('button');
      button.className = 'copy-code-btn';
      button.textContent = 'Copy';
      button.setAttribute('aria-label', 'Copy code to clipboard');
      return button;
    },

    async copyToClipboard(text, button) {
      try {
        await navigator.clipboard.writeText(text);
        button.textContent = 'Copied!';
        button.classList.add('copied');

        setTimeout(() => {
          button.textContent = 'Copy';
          button.classList.remove('copied');
        }, 2000);
      } catch (err) {
        console.error('Failed to copy:', err);
        button.textContent = 'Failed';
      }
    }
  };

  // ==================
  // Lazy Loading Images
  // ==================
  const LazyLoad = {
    init() {
      const images = document.querySelectorAll('img[data-src]');

      if ('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver((entries) => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              const img = entry.target;
              img.src = img.dataset.src;
              img.removeAttribute('data-src');
              imageObserver.unobserve(img);
            }
          });
        });

        images.forEach(img => imageObserver.observe(img));
      } else {
        // Fallback for older browsers
        images.forEach(img => {
          img.src = img.dataset.src;
          img.removeAttribute('data-src');
        });
      }
    }
  };

  // ==================
  // Analytics (Privacy-focused)
  // ==================
  const Analytics = {
    init() {
      // Check if user has consented to analytics
      const hasConsent = localStorage.getItem('analytics-consent') === 'true';

      if (hasConsent) {
        this.setupAnalytics();
      } else {
        this.showConsentBanner();
      }
    },

    setupAnalytics() {
      // Integrate with privacy-focused analytics like Plausible or Fathom
      // Example for Plausible:
      // const script = document.createElement('script');
      // script.defer = true;
      // script.dataset.domain = 'academic-workflow.org';
      // script.src = 'https://plausible.io/js/plausible.js';
      // document.head.appendChild(script);

      console.log('Analytics initialized (privacy-focused)');
    },

    showConsentBanner() {
      // Only show if banner hasn't been dismissed
      if (localStorage.getItem('analytics-consent-dismissed')) return;

      // Create and show consent banner
      // This is a placeholder - implement actual UI
      console.log('Show analytics consent banner');
    }
  };

  // ==================
  // Scroll Reveal Animations
  // ==================
  const ScrollReveal = {
    init() {
      const elements = document.querySelectorAll('[data-reveal]');

      if ('IntersectionObserver' in window) {
        const observer = new IntersectionObserver((entries) => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              entry.target.classList.add('revealed');
              observer.unobserve(entry.target);
            }
          });
        }, {
          threshold: 0.1
        });

        elements.forEach(el => observer.observe(el));
      }
    }
  };

  // ==================
  // Initialize Everything
  // ==================
  function init() {
    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initializeFeatures);
    } else {
      initializeFeatures();
    }
  }

  function initializeFeatures() {
    ThemeManager.init();
    Navigation.init();
    SmoothScroll.init();
    FormValidation.init();
    Tabs.init();
    Accordion.init();
    Search.init();
    CodeCopy.init();
    LazyLoad.init();
    ScrollReveal.init();

    // Only initialize analytics if user has opted in
    // Analytics.init();

    console.log('Academic Workflow Suite website initialized');
  }

  // Start initialization
  init();

  // Export for testing or external use if needed
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
      ThemeManager,
      Navigation,
      SmoothScroll,
      FormValidation,
      Tabs,
      Accordion,
      Search,
      CodeCopy,
      LazyLoad,
      Analytics,
      ScrollReveal
    };
  }
})();
