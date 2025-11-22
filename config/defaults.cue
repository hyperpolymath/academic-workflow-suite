package config

// Default configuration values for Academic Workflow Suite
// These defaults can be overridden by environment-specific configurations

// Production defaults
#ProductionDefaults: #Config & {
	application: {
		name:        "Academic Workflow Suite"
		version:     "1.0.0"
		environment: "production"
		description: "Academic Workflow Suite - Streamlining academic tasks"
	}

	core: {
		database: {
			type:     "postgresql"
			host:     "localhost"
			port:     5432
			database: "academic_workflow_prod"
			username: "aws_user"
			password: "" // Must be set via environment variable
			ssl:      true
			poolSize: {
				min: 5
				max: 20
			}
			timeout: {
				connect: 5000
				query:   30000
			}
			migrations: {
				enabled:   true
				directory: "./migrations"
			}
		}

		eventStore: {
			enabled: true
			backend: "postgresql"
			retention: {
				days:        90
				compression: true
			}
			snapshotting: {
				enabled:  true
				interval: 100
			}
		}

		anonymization: {
			enabled: true
			strategies: {
				students: {
					fields: ["email", "phone", "address"]
					method: "hash"
					retain: ["id", "name"]
				}
				faculty: {
					fields: ["phone", "address"]
					method: "pseudonymize"
					retain: ["id", "name", "email"]
				}
				research: {
					fields: ["participant_email", "participant_phone"]
					method: "encrypt"
					retain: ["participant_id"]
				}
			}
			hashSalt: "" // Must be set securely
		}

		cache: {
			enabled:  true
			backend:  "redis"
			host:     "localhost"
			port:     6379
			ttl:      3600
			maxSize:  "500MB"
			keyPrefix: "aws:"
		}
	}

	backend: {
		server: {
			host:         "0.0.0.0"
			port:         8080
			readTimeout:  30000
			writeTimeout: 30000
			maxBodySize:  "10MB"
			cors: {
				enabled:         true
				allowedOrigins:  ["https://academic.example.com"]
				allowedMethods:  ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
				allowedHeaders:  ["Content-Type", "Authorization", "X-Request-ID"]
				exposeHeaders:   ["X-Request-ID"]
				allowCredentials: true
				maxAge:          86400
			}
			tls: {
				enabled:  true
				certFile: "/etc/ssl/certs/server.crt"
				keyFile:  "/etc/ssl/private/server.key"
			}
		}

		api: {
			version:  "v1"
			basePath: "/api"
			rateLimit: {
				enabled:     true
				maxRequests: 100
				window:      60
				byIP:        true
				byUser:      true
			}
			pagination: {
				defaultPageSize: 25
				maxPageSize:     100
			}
			webhooks: {
				enabled:      false
				maxRetries:   3
				timeout:      10000
				secretHeader: "X-Webhook-Secret"
			}
		}

		auth: {
			jwt: {
				enabled:          true
				secret:           "" // Must be set securely
				issuer:           "academic-workflow-suite"
				audience:         "aws-users"
				accessTokenTTL:   3600
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
				cookieName: "aws_session"
				secure:   true
				httpOnly: true
				sameSite: "lax"
			}
		}

		moodle: {
			enabled:  false
			baseURL:  ""
			apiToken: ""
			version:  "3.11"
			sync: {
				enabled:  false
				interval: 3600
				entities: ["courses", "users", "assignments"]
			}
			webhooks: {
				enabled:  false
				endpoint: ""
				secret:   ""
			}
		}

		plugins: {
			enabled:    true
			directory:  "./plugins"
			autoload:   true
			whitelist:  []
			blacklist:  []
		}

		jobs: {
			enabled: true
			backend: "redis"
			workers: 4
			queues: {
				default: {
					maxRetries:    3
					timeout:       300000
					backoffDelay:  1000
					concurrency:   2
				}
				priority: {
					maxRetries:    5
					timeout:       600000
					backoffDelay:  500
					concurrency:   4
				}
				batch: {
					maxRetries:    2
					timeout:       1800000
					backoffDelay:  2000
					concurrency:   1
				}
			}
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
			offlineMode:        false
			realTimeCollaboration: false
		}
		ui: {
			theme:         "auto"
			compactMode:   false
			showTooltips:  true
			language:      "en-US"
			customCSS:     ""
		}
		sync: {
			enabled:       true
			autoSync:      true
			interval:      300
			conflictResolution: "manual"
		}
	}

	aiJail: {
		enabled: true
		models: {
			enabled: ["gpt-4", "local"]
			default: "gpt-4"
			providers: {
				openai: {
					apiKey:      "" // Must be set via environment variable
					baseURL:     "https://api.openai.com/v1"
					maxTokens:   4096
					temperature: 0.7
				}
				local: {
					modelPath:   "/models/llama-2-7b"
					backend:     "ollama"
					host:        "localhost"
					port:        11434
				}
			}
		}
		runtime: {
			backend:      "docker"
			socketPath:   "/var/run/docker.sock"
			network:      "bridge"
			image:        "python:3.11-slim"
			timeout:      60000
			autoRemove:   true
		}
		resources: {
			cpu: {
				cores:   1
				shares:  1024
			}
			memory: {
				limit:   "512MB"
				swap:    "0"
			}
			disk: {
				limit:   "1GB"
				tmpfs:   "100MB"
			}
			network: {
				enabled:       false
				bandwidthLimit: "10MB"
			}
			time: {
				maxExecutionTime: 30000
				maxIdleTime:      5000
			}
		}
		security: {
			readOnlyRootFS:    true
			noNewPrivileges:   true
			dropCapabilities:  ["ALL"]
			seccompProfile:    "default"
			apparmorProfile:   ""
			allowedSyscalls:   []
		}
	}

	academicTools: {
		citations: {
			enabled: true
			formats: ["APA", "MLA", "Chicago", "Harvard", "IEEE"]
			styles: {
				default: "APA"
				custom:  []
			}
			bibliography: {
				autoGenerate: true
				format:       "bibtex"
			}
			integrations: {
				zotero:     false
				mendeley:   false
				refWorks:   false
			}
		}

		rubrics: {
			enabled:   true
			templates: []
			grading: {
				scale:         "percentage"
				roundingMode:  "nearest"
				decimalPlaces: 2
			}
			export: {
				formats: ["pdf", "excel"]
			}
		}

		plagiarism: {
			enabled:   false
			provider:  "local"
			threshold: 20
			local: {
				algorithm:  "cosine"
				nGramSize:  3
				minLength:  50
			}
		}

		analytics: {
			enabled: true
			dashboards: {
				student:     true
				instructor:  true
				admin:       true
			}
			metrics: {
				performance:    true
				engagement:     true
				completion:     true
				timeTracking:   false
			}
			export: {
				enabled:  true
				formats:  ["csv", "excel"]
				schedule: "weekly"
			}
		}
	}

	monitoring: {
		enabled: true
		metrics: {
			enabled:   true
			backend:   "prometheus"
			endpoint:  "/metrics"
			interval:  15
			labels: {
				service:     "academic-workflow-suite"
				environment: "production"
				version:     "1.0.0"
			}
		}
		tracing: {
			enabled:     false
			backend:     "jaeger"
			endpoint:    ""
			samplingRate: 0.1
			serviceName: "academic-workflow-suite"
		}
		profiling: {
			enabled:    false
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
		level:      "info"
		format:     "json"
		output: [
			{type: "stdout"},
			{
				type:       "file"
				path:       "/var/log/aws/application.log"
				maxSize:    "100MB"
				maxAge:     30
				maxBackups: 7
				compress:   true
			},
		]
		structured: true
		caller:     false
		stackTrace: false
		sampling: {
			enabled: false
			initial: 100
			thereafter: 100
		}
	}

	security: {
		encryption: {
			atRest: {
				enabled:   true
				algorithm: "AES-256-GCM"
				keyRotation: {
					enabled:  true
					interval: 2592000
				}
			}
			inTransit: {
				enabled:      true
				minTLSVersion: "1.2"
				cipherSuites: [
					"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
					"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
				]
			}
		}

		secrets: {
			backend: "env"
		}

		cors: {
			enabled:         true
			allowedOrigins:  ["https://academic.example.com"]
			allowedMethods:  ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
			allowedHeaders:  ["Content-Type", "Authorization"]
			exposeHeaders:   []
			allowCredentials: true
			maxAge:          86400
		}

		csp: {
			enabled:       true
			defaultSrc:    ["'self'"]
			scriptSrc:     ["'self'"]
			styleSrc:      ["'self'", "'unsafe-inline'"]
			imgSrc:        ["'self'", "data:", "https:"]
			connectSrc:    ["'self'"]
			fontSrc:       ["'self'"]
			objectSrc:     ["'none'"]
			mediaSrc:      ["'self'"]
			frameSrc:      ["'none'"]
			reportURI:     ""
		}

		rateLimit: {
			enabled:     true
			maxRequests: 1000
			window:      60
			blockDuration: 300
			whitelist:   []
		}

		audit: {
			enabled:   true
			backend:   "database"
			retention: 365
			events:    ["login", "logout", "create", "update", "delete", "access", "export", "admin_action"]
		}
	}
}

// Development overrides
#DevelopmentOverrides: {
	application: environment: "development"

	core: {
		database: {
			database: "academic_workflow_dev"
			ssl:      false
			poolSize: {
				min: 2
				max: 10
			}
		}

		cache: {
			backend: "memory"
		}
	}

	backend: {
		server: {
			port: 8080
			tls: enabled: false
			cors: allowedOrigins: ["http://localhost:3000", "http://localhost:8080"]
		}

		auth: {
			jwt: {
				accessTokenTTL:  86400 // 24 hours for development
				refreshTokenTTL: 604800 // 7 days
			}
			session: {
				backend: "memory"
				secure:  false
			}
		}

		jobs: {
			backend: "memory"
			workers: 2
		}
	}

	aiJail: {
		runtime: {
			timeout: 120000 // Longer timeout for debugging
		}
		resources: {
			cpu: cores: 2
			memory: limit: "1GB"
		}
	}

	monitoring: {
		metrics: {
			labels: environment: "development"
		}
		tracing: enabled: false
		profiling: enabled: true
	}

	logging: {
		level:  "debug"
		format: "console"
		output: [{type: "stdout"}]
		caller:     true
		stackTrace: true
	}

	security: {
		encryption: {
			atRest: enabled: false // For easier debugging
		}

		cors: allowedOrigins: ["http://localhost:3000", "http://localhost:8080", "http://127.0.0.1:3000"]

		csp: {
			scriptSrc: ["'self'", "'unsafe-eval'"] // For development tools
			styleSrc:  ["'self'", "'unsafe-inline'"]
		}

		rateLimit: enabled: false
	}
}

// Test environment settings
#TestOverrides: {
	application: environment: "test"

	core: {
		database: {
			type:     "sqlite"
			database: ":memory:"
			ssl:      false
		}

		eventStore: {
			backend: "memory"
		}

		cache: {
			backend: "memory"
		}
	}

	backend: {
		server: port: 8081

		auth: {
			jwt: {
				accessTokenTTL:  3600
				refreshTokenTTL: 7200
			}
			session: backend: "memory"
		}

		jobs: {
			backend: "memory"
			workers: 1
		}
	}

	aiJail: {
		enabled: false // Disabled in tests by default
	}

	monitoring: {
		enabled: false
		metrics: {
			labels: environment: "test"
		}
	}

	logging: {
		level:  "error"
		format: "json"
		output: [{type: "stdout"}]
	}

	security: {
		encryption: atRest: enabled: false
		cors: allowedOrigins: ["*"]
		csp: enabled: false
		rateLimit: enabled: false
		audit: enabled: false
	}
}

// Staging environment settings
#StagingOverrides: {
	application: environment: "staging"

	core: {
		database: database: "academic_workflow_staging"
	}

	backend: {
		server: {
			cors: allowedOrigins: ["https://staging.academic.example.com"]
		}
	}

	monitoring: {
		metrics: {
			labels: environment: "staging"
		}
		tracing: enabled: true
	}

	logging: level: "debug"

	security: {
		cors: allowedOrigins: ["https://staging.academic.example.com"]
	}
}
