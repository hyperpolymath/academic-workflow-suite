package config

// Development environment configuration
// This configuration is optimized for local development

config: #ProductionDefaults & #DevelopmentOverrides & #DevelopmentConstraints & #ConfigValidation & {
	application: {
		name:        "Academic Workflow Suite"
		version:     "1.0.0-dev"
		environment: "development"
	}

	core: {
		database: {
			type:     "postgresql"
			host:     "localhost"
			port:     5432
			database: "academic_workflow_dev"
			username: "aws_dev_user"
			password: "dev_password" // OK for development
			ssl:      false
			poolSize: {
				min: 2
				max: 10
			}
		}

		eventStore: {
			enabled: true
			backend: "postgresql"
			retention: {
				days:        30
				compression: false
			}
		}

		cache: {
			enabled:  true
			backend:  "redis"
			host:     "localhost"
			port:     6379
			ttl:      1800
			maxSize:  "256MB"
			keyPrefix: "aws:dev:"
		}

		anonymization: {
			enabled: false // Disabled for easier development
		}
	}

	backend: {
		server: {
			host: "127.0.0.1"
			port: 8080
			tls: {
				enabled: false
			}
			cors: {
				enabled:         true
				allowedOrigins:  ["http://localhost:3000", "http://localhost:8080", "http://127.0.0.1:3000"]
				allowedMethods:  ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"]
				allowedHeaders:  ["*"]
				exposeHeaders:   ["*"]
				allowCredentials: true
				maxAge:          86400
			}
		}

		api: {
			rateLimit: {
				enabled: false // Disabled for development
			}
			webhooks: {
				enabled: false
			}
		}

		auth: {
			jwt: {
				enabled:          true
				secret:           "dev-secret-change-in-production"
				issuer:           "academic-workflow-suite-dev"
				audience:         "aws-dev-users"
				accessTokenTTL:   86400 // 24 hours for convenience
				refreshTokenTTL:  604800
				algorithm:        "HS256"
			}
			oauth2: {
				enabled: false
			}
			saml: {
				enabled: false
			}
			session: {
				enabled:  true
				backend:  "redis"
				ttl:      86400
				cookieName: "aws_session_dev"
				secure:   false
				httpOnly: true
				sameSite: "lax"
			}
		}

		moodle: {
			enabled: false
		}

		jobs: {
			enabled: true
			backend: "redis"
			workers: 2
		}
	}

	officeAddin: {
		enabled: true
		features: {
			citationManager:    true
			rubricIntegration:  true
			gradeSync:          true
			commentTemplates:   true
			autoSave:           true
			offlineMode:        true
			realTimeCollaboration: false
		}
		ui: {
			theme:         "auto"
			compactMode:   false
			showTooltips:  true
			language:      "en-US"
		}
	}

	aiJail: {
		enabled: true
		models: {
			enabled: ["local"]
			default: "local"
			providers: {
				local: {
					modelPath: "/models/llama-2-7b"
					backend:   "ollama"
					host:      "localhost"
					port:      11434
				}
			}
		}
		runtime: {
			backend:    "docker"
			network:    "bridge"
			timeout:    120000 // Longer timeout for development
			autoRemove: true
		}
		resources: {
			cpu: {
				cores:  2
				shares: 1024
			}
			memory: {
				limit: "1GB"
				swap:  "512MB"
			}
			time: {
				maxExecutionTime: 60000
				maxIdleTime:      10000
			}
		}
		security: {
			readOnlyRootFS:  false // Allow writes for debugging
			noNewPrivileges: true
			dropCapabilities: ["ALL"]
		}
	}

	academicTools: {
		citations: {
			enabled: true
			formats: ["APA", "MLA", "Chicago", "Harvard"]
			styles: {
				default: "APA"
			}
		}

		rubrics: {
			enabled: true
			grading: {
				scale:         "percentage"
				roundingMode:  "nearest"
				decimalPlaces: 2
			}
		}

		plagiarism: {
			enabled:   false
			provider:  "local"
			threshold: 20
		}

		analytics: {
			enabled: true
			dashboards: {
				student:     true
				instructor:  true
				admin:       true
			}
			metrics: {
				performance:  true
				engagement:   true
				completion:   true
				timeTracking: true
			}
		}
	}

	monitoring: {
		enabled: true
		metrics: {
			enabled:  true
			backend:  "prometheus"
			endpoint: "/metrics"
			interval: 15
			labels: {
				service:     "academic-workflow-suite"
				environment: "development"
				version:     "1.0.0-dev"
			}
		}
		tracing: {
			enabled: false // Usually not needed in development
		}
		profiling: {
			enabled:    true
			backend:    "pprof"
			endpoint:   "/debug/pprof"
			continuous: false
		}
		healthCheck: {
			enabled:  true
			endpoint: "/health"
			checks: [
				{
					name:     "database"
					type:     "database"
					timeout:  5000
					critical: true
				},
				{
					name:     "cache"
					type:     "cache"
					timeout:  3000
					critical: false
				},
			]
		}
	}

	logging: {
		level:  "debug"
		format: "console"
		output: [
			{type: "stdout"},
		]
		structured: false
		caller:     true
		stackTrace: true
		sampling: {
			enabled: false
		}
	}

	security: {
		encryption: {
			atRest: {
				enabled: false // Disabled for easier debugging
			}
			inTransit: {
				enabled: false
			}
		}

		secrets: {
			backend: "env"
		}

		cors: {
			enabled:         true
			allowedOrigins:  ["*"]
			allowedMethods:  ["*"]
			allowedHeaders:  ["*"]
			exposeHeaders:   ["*"]
			allowCredentials: true
			maxAge:          86400
		}

		csp: {
			enabled:    false // Disabled for development flexibility
		}

		rateLimit: {
			enabled: false
		}

		audit: {
			enabled:   false
			backend:   "database"
			retention: 30
			events:    ["login", "logout", "admin_action"]
		}
	}
}
