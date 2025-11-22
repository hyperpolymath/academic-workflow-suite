package config

// Production environment configuration
// This configuration is optimized for production deployment

config: #ProductionDefaults & #ProductionConstraints & #ConfigValidation & {
	application: {
		name:        "Academic Workflow Suite"
		version:     "1.0.0"
		environment: "production"
	}

	core: {
		database: {
			type:     "postgresql"
			host:     "db.production.example.com"
			port:     5432
			database: "academic_workflow_prod"
			username: "aws_prod_user"
			password: "" // Set via AWS_DB_PASSWORD env var
			ssl:      true
			poolSize: {
				min: 5
				max: 20
			}
		}

		eventStore: {
			enabled: true
			backend: "postgresql"
			retention: {
				days:        90
				compression: true
			}
		}

		cache: {
			enabled:  true
			backend:  "redis"
			host:     "redis.production.example.com"
			port:     6379
			ttl:      3600
			maxSize:  "1GB"
			keyPrefix: "aws:prod:"
		}
	}

	backend: {
		server: {
			host: "0.0.0.0"
			port: 8443
			tls: {
				enabled:  true
				certFile: "/etc/ssl/certs/aws-prod.crt"
				keyFile:  "/etc/ssl/private/aws-prod.key"
			}
			cors: {
				enabled:         true
				allowedOrigins:  ["https://academic.example.com", "https://app.example.com"]
				allowedMethods:  ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
				allowedHeaders:  ["Content-Type", "Authorization", "X-Request-ID"]
				exposeHeaders:   ["X-Request-ID", "X-RateLimit-Remaining"]
				allowCredentials: true
				maxAge:          86400
			}
		}

		api: {
			rateLimit: {
				enabled:     true
				maxRequests: 100
				window:      60
				byIP:        true
				byUser:      true
			}
		}

		auth: {
			jwt: {
				enabled:          true
				secret:           "" // Set via AWS_JWT_SECRET env var
				issuer:           "academic-workflow-suite"
				audience:         "aws-production-users"
				accessTokenTTL:   3600
				refreshTokenTTL:  604800
				algorithm:        "HS256"
			}
			session: {
				enabled:  true
				backend:  "redis"
				ttl:      86400
				cookieName: "aws_session_prod"
				secure:   true
				httpOnly: true
				sameSite: "strict"
			}
		}

		jobs: {
			enabled: true
			backend: "redis"
			workers: 8
		}
	}

	aiJail: {
		enabled: true
		models: {
			enabled: ["gpt-4", "local"]
			default: "gpt-4"
		}
		runtime: {
			backend:    "docker"
			network:    "bridge"
			timeout:    60000
			autoRemove: true
		}
		resources: {
			cpu: {
				cores:  2
				shares: 2048
			}
			memory: {
				limit: "1GB"
				swap:  "0"
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
				environment: "production"
				version:     "1.0.0"
			}
		}
		tracing: {
			enabled:     true
			backend:     "jaeger"
			endpoint:    "http://jaeger.monitoring.svc:14268/api/traces"
			samplingRate: 0.1
			serviceName: "academic-workflow-suite"
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
					name:     "event-store"
					type:     "database"
					timeout:  5000
					critical: false
				},
			]
		}
	}

	logging: {
		level:      "info"
		format:     "json"
		structured: true
		caller:     false
		stackTrace: false
		output: [
			{type: "stdout"},
			{
				type:       "file"
				path:       "/var/log/aws/application.log"
				maxSize:    "100MB"
				maxAge:     30
				maxBackups: 10
				compress:   true
			},
		]
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
			allowedOrigins:  ["https://academic.example.com", "https://app.example.com"]
			allowedMethods:  ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
			allowedHeaders:  ["Content-Type", "Authorization"]
			exposeHeaders:   []
			allowCredentials: true
			maxAge:          86400
		}

		csp: {
			enabled:    true
			defaultSrc: ["'self'"]
			scriptSrc:  ["'self'"]
			styleSrc:   ["'self'", "'unsafe-inline'"]
			imgSrc:     ["'self'", "data:", "https:"]
			connectSrc: ["'self'", "https://api.example.com"]
			fontSrc:    ["'self'"]
			objectSrc:  ["'none'"]
			mediaSrc:   ["'self'"]
			frameSrc:   ["'none'"]
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
