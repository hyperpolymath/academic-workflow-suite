package config

// Test environment configuration
// This configuration is optimized for automated testing

config: #ProductionDefaults & #TestOverrides & #TestConstraints & #ConfigValidation & {
	application: {
		name:        "Academic Workflow Suite"
		version:     "1.0.0-test"
		environment: "test"
	}

	core: {
		database: {
			type:     "sqlite"
			host:     ""
			port:     0
			database: ":memory:"
			username: ""
			password: ""
			ssl:      false
			poolSize: {
				min: 1
				max: 5
			}
			timeout: {
				connect: 5000
				query:   10000
			}
			migrations: {
				enabled:   true
				directory: "./migrations"
			}
		}

		eventStore: {
			enabled: true
			backend: "memory"
			retention: {
				days:        1
				compression: false
			}
			snapshotting: {
				enabled:  false
			}
		}

		cache: {
			enabled:  true
			backend:  "memory"
			host:     ""
			port:     0
			ttl:      300
			maxSize:  "100MB"
			keyPrefix: "aws:test:"
		}

		anonymization: {
			enabled: false
		}
	}

	backend: {
		server: {
			host: "127.0.0.1"
			port: 8081
			readTimeout:  10000
			writeTimeout: 10000
			tls: {
				enabled: false
			}
			cors: {
				enabled:         true
				allowedOrigins:  ["*"]
				allowedMethods:  ["*"]
				allowedHeaders:  ["*"]
				exposeHeaders:   ["*"]
				allowCredentials: true
			}
		}

		api: {
			version:  "v1"
			basePath: "/api"
			rateLimit: {
				enabled: false
			}
			pagination: {
				defaultPageSize: 10
				maxPageSize:     50
			}
			webhooks: {
				enabled: false
			}
		}

		auth: {
			jwt: {
				enabled:          true
				secret:           "test-secret-not-for-production"
				issuer:           "academic-workflow-suite-test"
				audience:         "aws-test-users"
				accessTokenTTL:   3600
				refreshTokenTTL:  7200
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
				backend:  "memory"
				ttl:      3600
				cookieName: "aws_session_test"
				secure:   false
				httpOnly: true
				sameSite: "lax"
			}
		}

		moodle: {
			enabled: false
		}

		plugins: {
			enabled:   false
			autoload:  false
		}

		jobs: {
			enabled: true
			backend: "memory"
			workers: 1
			queues: {
				default: {
					maxRetries:    1
					timeout:       10000
					backoffDelay:  100
					concurrency:   1
				}
				priority: {
					maxRetries:    1
					timeout:       10000
					backoffDelay:  100
					concurrency:   1
				}
				batch: {
					maxRetries:    1
					timeout:       10000
					backoffDelay:  100
					concurrency:   1
				}
			}
		}
	}

	officeAddin: {
		enabled: false
	}

	aiJail: {
		enabled: false // Disabled in tests by default
	}

	academicTools: {
		citations: {
			enabled: true
			formats: ["APA", "MLA"]
			styles: {
				default: "APA"
			}
			bibliography: {
				autoGenerate: false
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
				formats: ["json"]
			}
		}

		plagiarism: {
			enabled: false
		}

		analytics: {
			enabled: false
		}
	}

	monitoring: {
		enabled: false
		metrics: {
			enabled:  false
			backend:  "prometheus"
			endpoint: "/metrics"
			labels: {
				service:     "academic-workflow-suite"
				environment: "test"
				version:     "1.0.0-test"
			}
		}
		tracing: {
			enabled: false
		}
		profiling: {
			enabled: false
		}
		healthCheck: {
			enabled:  true
			endpoint: "/health"
			checks: [
				{
					name:     "database"
					type:     "database"
					timeout:  2000
					critical: true
				},
			]
		}
	}

	logging: {
		level:  "error"
		format: "json"
		output: [
			{type: "stdout"},
		]
		structured: true
		caller:     false
		stackTrace: false
		sampling: {
			enabled: false
		}
	}

	security: {
		encryption: {
			atRest: {
				enabled: false
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
		}

		csp: {
			enabled: false
		}

		rateLimit: {
			enabled: false
		}

		audit: {
			enabled:   false
			backend:   "database"
			retention: 1
			events:    []
		}
	}
}
