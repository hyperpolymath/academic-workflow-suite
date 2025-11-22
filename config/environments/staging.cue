package config

// Staging environment configuration
// This configuration mirrors production but with reduced resources and relaxed constraints

config: #ProductionDefaults & #StagingOverrides & #StagingConstraints & #ConfigValidation & {
	application: {
		name:        "Academic Workflow Suite"
		version:     "1.0.0-rc"
		environment: "staging"
	}

	core: {
		database: {
			type:     "postgresql"
			host:     "db.staging.example.com"
			port:     5432
			database: "academic_workflow_staging"
			username: "aws_staging_user"
			password: "" // Set via AWS_DB_PASSWORD env var
			ssl:      true
			poolSize: {
				min: 3
				max: 15
			}
		}

		eventStore: {
			enabled: true
			backend: "postgresql"
			retention: {
				days:        30
				compression: true
			}
			snapshotting: {
				enabled:  true
				interval: 100
			}
		}

		cache: {
			enabled:  true
			backend:  "redis"
			host:     "redis.staging.example.com"
			port:     6379
			ttl:      3600
			maxSize:  "512MB"
			keyPrefix: "aws:staging:"
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
	}

	backend: {
		server: {
			host: "0.0.0.0"
			port: 8443
			tls: {
				enabled:  true
				certFile: "/etc/ssl/certs/aws-staging.crt"
				keyFile:  "/etc/ssl/private/aws-staging.key"
			}
			cors: {
				enabled:         true
				allowedOrigins:  ["https://staging.academic.example.com"]
				allowedMethods:  ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
				allowedHeaders:  ["Content-Type", "Authorization", "X-Request-ID"]
				exposeHeaders:   ["X-Request-ID"]
				allowCredentials: true
				maxAge:          86400
			}
		}

		api: {
			rateLimit: {
				enabled:     true
				maxRequests: 200 // Higher limits for testing
				window:      60
				byIP:        true
				byUser:      true
			}
			webhooks: {
				enabled:      true
				maxRetries:   3
				timeout:      10000
				secretHeader: "X-Webhook-Secret"
			}
		}

		auth: {
			jwt: {
				enabled:          true
				secret:           "" // Set via AWS_JWT_SECRET env var
				issuer:           "academic-workflow-suite-staging"
				audience:         "aws-staging-users"
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
				cookieName: "aws_session_staging"
				secure:   true
				httpOnly: true
				sameSite: "lax"
			}
		}

		moodle: {
			enabled:  true
			baseURL:  "https://moodle-staging.example.com"
			apiToken: "" // Set via env var
			version:  "3.11"
			sync: {
				enabled:  true
				interval: 7200 // 2 hours
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
					apiKey:      "" // Set via env var
					baseURL:     "https://api.openai.com/v1"
					maxTokens:   4096
					temperature: 0.7
				}
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
			timeout:    60000
			autoRemove: true
		}
		resources: {
			cpu: {
				cores:  1
				shares: 1024
			}
			memory: {
				limit: "512MB"
				swap:  "0"
			}
			disk: {
				limit: "1GB"
				tmpfs: "100MB"
			}
			time: {
				maxExecutionTime: 30000
				maxIdleTime:      5000
			}
		}
		security: {
			readOnlyRootFS:  true
			noNewPrivileges: true
			dropCapabilities: ["ALL"]
		}
	}

	academicTools: {
		citations: {
			enabled: true
			formats: ["APA", "MLA", "Chicago", "Harvard", "IEEE"]
			styles: {
				default: "APA"
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
			enabled:   true
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
				performance:  true
				engagement:   true
				completion:   true
				timeTracking: true
			}
			export: {
				enabled:  true
				formats:  ["csv", "excel"]
				schedule: "daily"
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
				environment: "staging"
				version:     "1.0.0-rc"
			}
		}
		tracing: {
			enabled:     true
			backend:     "jaeger"
			endpoint:    "http://jaeger.staging.svc:14268/api/traces"
			samplingRate: 0.5 // Higher sampling in staging
			serviceName: "academic-workflow-suite"
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
					critical: true
				},
				{
					name:     "moodle"
					type:     "external"
					timeout:  10000
					critical: false
				},
			]
		}
	}

	logging: {
		level:  "debug"
		format: "json"
		output: [
			{type: "stdout"},
			{
				type:       "file"
				path:       "/var/log/aws/staging.log"
				maxSize:    "100MB"
				maxAge:     14
				maxBackups: 5
				compress:   true
			},
		]
		structured: true
		caller:     true
		stackTrace: true
		sampling: {
			enabled: false
		}
	}

	security: {
		encryption: {
			atRest: {
				enabled:   true
				algorithm: "AES-256-GCM"
				keyRotation: {
					enabled:  true
					interval: 2592000 // 30 days
				}
			}
			inTransit: {
				enabled:      true
				minTLSVersion: "1.2"
			}
		}

		secrets: {
			backend: "env"
		}

		cors: {
			enabled:         true
			allowedOrigins:  ["https://staging.academic.example.com"]
			allowedMethods:  ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
			allowedHeaders:  ["Content-Type", "Authorization"]
			exposeHeaders:   []
			allowCredentials: true
			maxAge:          86400
		}

		csp: {
			enabled:    true
			defaultSrc: ["'self'"]
			scriptSrc:  ["'self'", "'unsafe-eval'"] // Allow eval for debugging
			styleSrc:   ["'self'", "'unsafe-inline'"]
			imgSrc:     ["'self'", "data:", "https:"]
			connectSrc: ["'self'", "https://api.staging.example.com"]
			fontSrc:    ["'self'"]
			objectSrc:  ["'none'"]
			mediaSrc:   ["'self'"]
			frameSrc:   ["'none'"]
		}

		rateLimit: {
			enabled:     true
			maxRequests: 2000
			window:      60
			blockDuration: 180
			whitelist:   []
		}

		audit: {
			enabled:   true
			backend:   "database"
			retention: 90
			events:    ["login", "logout", "create", "update", "delete", "access", "export", "admin_action"]
		}
	}
}
