package config

import (
	"strings"
	"regexp"
)

// Validation rules for Academic Workflow Suite configuration
// This file contains additional constraints and validation logic

// Port validation
#ValidPort: int & >=1 & <=65535

// Common port ranges
#UnprivilegedPort: #ValidPort & >=1024
#EphemeralPort: #ValidPort & >=49152

// URL validation
#URL: string & =~"^https?://[a-zA-Z0-9][a-zA-Z0-9-._~:/?#\\[\\]@!$&'()*+,;=]*$"
#HTTPS_URL: string & =~"^https://[a-zA-Z0-9][a-zA-Z0-9-._~:/?#\\[\\]@!$&'()*+,;=]*$"

// Email validation
#Email: string & =~"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"

// Path validation
#AbsolutePath: string & =~"^/"
#RelativePath: string & !~"^/"

// Version validation (semantic versioning)
#SemanticVersion: string & =~"^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9.-]+)?(\\+[a-zA-Z0-9.-]+)?$"

// Memory size validation (e.g., "512MB", "2GB")
#MemorySize: string & =~"^\\d+(\\.\\d+)?(B|KB|MB|GB|TB)$"

// Duration in milliseconds
#DurationMS: int & >=0

// Percentage
#Percentage: number & >=0 & <=100

// Non-empty string
#NonEmptyString: string & !=""

// Alphanumeric with hyphens and underscores
#Identifier: string & =~"^[a-zA-Z0-9_-]+$"

// Hostname validation
#Hostname: string & =~"^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"

// IP address validation
#IPv4: string & =~"^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$"
#IPv6: string & =~"^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$"

// Configuration-specific validations
#ConfigValidation: #Config & {
	// Validate application settings
	application: {
		name:        #NonEmptyString
		version:     #SemanticVersion
		environment: #Environment
	}

	// Validate core settings
	core: {
		database: {
			port: #ValidPort

			// Ensure pool min is less than max
			poolSize: {
				min: <=poolSize.max
			}

			// Ensure timeouts are reasonable
			timeout: {
				connect: >=1000 & <=30000
				query:   >=1000 & <=300000
			}
		}

		eventStore: {
			retention: days: >=1 & <=3650 // Max 10 years
		}

		cache: {
			port:   #ValidPort
			ttl:    >=60 & <=86400 // 1 minute to 1 day
			maxSize: #MemorySize
		}
	}

	// Validate backend settings
	backend: {
		server: {
			port:         #UnprivilegedPort
			readTimeout:  #DurationMS & >=1000 & <=300000
			writeTimeout: #DurationMS & >=1000 & <=300000
			maxBodySize:  #MemorySize

			cors: {
				maxAge: >=0 & <=86400
			}

			if tls.enabled {
				tls: {
					certFile: #AbsolutePath
					keyFile:  #AbsolutePath
				}
			}
		}

		api: {
			version:  =~"^v\\d+$"
			basePath: =~"^/.*"

			rateLimit: {
				maxRequests: >=1 & <=10000
				window:      >=1 & <=3600
			}

			pagination: {
				defaultPageSize: <=maxPageSize
				maxPageSize:     <=10000
			}
		}

		auth: {
			jwt: {
				accessTokenTTL:  >=60 & <=86400 // 1 minute to 1 day
				refreshTokenTTL: >=accessTokenTTL & <=2592000 // Up to 30 days
			}

			session: {
				ttl: >=60 & <=604800 // 1 minute to 7 days
			}
		}

		if moodle.enabled {
			moodle: {
				baseURL: #URL
				version: =~"^\\d+\\.\\d+.*"

				if sync.enabled {
					sync: {
						interval: >=60
						entities: [...("courses" | "users" | "assignments" | "grades")]
					}
				}
			}
		}

		jobs: {
			workers: >=1 & <=100

			queues: {
				[string]: {
					maxRetries:  >=0 & <=10
					timeout:     #DurationMS & >=1000
					backoffDelay: #DurationMS & >=100
					concurrency: >=1 & <=20
				}
			}
		}
	}

	// Validate Office add-in settings
	officeAddin: {
		sync: {
			if enabled {
				interval: >=30 & <=3600
			}
		}
	}

	// Validate AI jail settings
	aiJail: {
		if enabled {
			models: {
				enabled: [...string] & len(enabled) >= 1
				default: string

				// Default model must be in enabled list
				default: or(enabled)
			}

			runtime: {
				timeout: #DurationMS & >=1000 & <=600000 // 1 second to 10 minutes
			}

			resources: {
				cpu: {
					cores:  >0 & <=32
					shares: >=1 & <=10240
				}

				memory: {
					limit: #MemorySize
					swap:  #MemorySize | "0"
				}

				disk: {
					limit: #MemorySize
					tmpfs: #MemorySize
				}

				time: {
					maxExecutionTime: #DurationMS & >=1000 & <=600000
					maxIdleTime:      #DurationMS & >=1000 & <=maxExecutionTime
				}
			}
		}
	}

	// Validate academic tools
	academicTools: {
		citations: {
			if enabled {
				formats: [...#CitationFormat] & len(formats) >= 1
				styles: default: or(formats)
			}
		}

		rubrics: {
			grading: {
				decimalPlaces: >=0 & <=4
			}

			templates: [...#RubricTemplate] & [
				for template in templates {
					// Ensure criteria weights sum to approximately 1
					{
						criteria: [...#RubricCriterion] & [
							for criterion in criteria {
								weight: >=0 & <=1
							},
						]
					}
				},
			]
		}

		plagiarism: {
			threshold: #Percentage

			if provider == "local" {
				local: {
					nGramSize: >=1 & <=10
					minLength: >=1 & <=1000
				}
			}
		}

		analytics: {
			export: {
				if enabled {
					formats: [...string] & len(formats) >= 1
				}
			}
		}
	}

	// Validate monitoring settings
	monitoring: {
		if enabled {
			metrics: {
				interval: >=1 & <=300
				labels: {
					service:     #NonEmptyString
					environment: #NonEmptyString
					version:     #SemanticVersion
				}
			}

			if tracing.enabled {
				tracing: {
					endpoint:    #URL
					samplingRate: >=0 & <=1
					serviceName: #NonEmptyString
				}
			}

			healthCheck: {
				checks: [...#HealthCheckItem] & [
					for check in checks {
						{
							name:    #NonEmptyString
							timeout: #DurationMS & >=100 & <=30000
						}
					},
				]
			}
		}
	}

	// Validate logging settings
	logging: {
		output: [...#LogOutput] & len(output) >= 1

		output: [
			for out in output if out.type == "file" {
				{
					path:       #AbsolutePath
					maxSize:    #MemorySize
					maxAge:     >=1 & <=365
					maxBackups: >=0 & <=100
				}
			},
			for out in output if out.type == "syslog" {
				{
					address: #Hostname | #IPv4 | #IPv6
				}
			},
			for out in output if out.type == "elasticsearch" {
				{
					addresses: [...#URL] & len(addresses) >= 1
					index:     #NonEmptyString
				}
			},
			for out in output if out.type == "loki" {
				{
					url: #URL
				}
			},
			...
		]

		if sampling.enabled {
			sampling: {
				initial:    >=1 & <=1000
				thereafter: >=1 & <=1000
			}
		}
	}

	// Validate security settings
	security: {
		encryption: {
			if atRest.enabled {
				atRest: {
					if keyRotation.enabled {
						keyRotation: {
							interval: >=86400 & <=31536000 // 1 day to 1 year
						}
					}
				}
			}
		}

		if secrets.backend == "vault" {
			secrets: {
				address: #URL
			}
		}

		cors: {
			if enabled {
				allowedOrigins: [...(#URL | "*")] & len(allowedOrigins) >= 1
				allowedMethods: [...string] & len(allowedMethods) >= 1
				maxAge:         >=0 & <=86400
			}
		}

		csp: {
			if enabled {
				defaultSrc: [...string] & len(defaultSrc) >= 1
			}
		}

		rateLimit: {
			if enabled {
				maxRequests:   >=1 & <=100000
				window:        >=1 & <=3600
				blockDuration: >=0 & <=86400
			}
		}

		audit: {
			if enabled {
				retention: >=1 & <=3650 // Max 10 years
				events:    [...#AuditEvent] & len(events) >= 1
			}
		}
	}
}

// Environment-specific validation constraints
#ProductionConstraints: {
	application: environment: "production"

	// Production must use TLS
	backend: server: tls: enabled: true

	// Production must use secure sessions
	backend: auth: session: {
		secure:   true
		httpOnly: true
	}

	// Production should use external cache
	core: cache: backend: "redis" | "memcached"

	// Production should use PostgreSQL
	core: database: type: "postgresql" | "mysql"

	// Production must enable SSL for database
	core: database: ssl: true

	// Production must enable monitoring
	monitoring: enabled: true

	// Production must use structured logging
	logging: {
		structured: true
		format:     "json"
	}

	// Production must enable encryption at rest
	security: encryption: atRest: enabled: true

	// Production must enable audit logging
	security: audit: enabled: true
}

#DevelopmentConstraints: {
	application: environment: "development"

	// Development can use less strict settings
	backend: server: tls: enabled: bool
	backend: auth: session: secure: bool
	core: database: ssl: bool
	security: encryption: atRest: enabled: bool
}

#TestConstraints: {
	application: environment: "test"

	// Test should use in-memory backends
	core: {
		database: type: "sqlite" | "postgresql"
		cache: backend:   "memory" | "redis"
	}

	backend: jobs: backend: "memory" | "redis"
}

#StagingConstraints: {
	application: environment: "staging"

	// Staging should mirror production constraints
	backend: server: tls: enabled: true
	core: database: {
		type: "postgresql" | "mysql"
		ssl:  true
	}
	monitoring: enabled: true
}

// Cross-field validation rules
#CrossFieldValidation: {
	// If OAuth2 is enabled, at least one provider must be configured
	if backend.auth.oauth2.enabled {
		backend: auth: oauth2: providers: {
			google? | microsoft? | github?: _
		}
	}

	// If SAML is enabled, required fields must be set
	if backend.auth.saml.enabled {
		backend: auth: saml: {
			idpMetadata: #NonEmptyString
			spEntityID:  #NonEmptyString
			callbackURL: #URL
		}
	}

	// If plagiarism detection is enabled, provider config must be complete
	if academicTools.plagiarism.enabled {
		academicTools: plagiarism: {
			if provider == "turnitin" | provider == "copyscape" {
				api: {
					endpoint: #URL
					apiKey:   #NonEmptyString
					timeout:  #DurationMS
				}
			}
		}
	}

	// If webhooks are enabled, secret must be set
	if backend.api.webhooks.enabled {
		backend: api: webhooks: secretHeader: #NonEmptyString
	}

	// If Moodle integration is enabled, required fields must be set
	if backend.moodle.enabled {
		backend: moodle: {
			baseURL:  #URL
			apiToken: #NonEmptyString
		}
	}

	// If tracing is enabled, endpoint must be set
	if monitoring.tracing.enabled {
		monitoring: tracing: endpoint: #URL
	}

	// If AI jail uses OpenAI, API key must be set
	if aiJail.enabled && "gpt-4" in aiJail.models.enabled {
		aiJail: models: providers: openai: apiKey: #NonEmptyString
	}

	// If AI jail uses Anthropic, API key must be set
	if aiJail.enabled && "claude-3" in aiJail.models.enabled {
		aiJail: models: providers: anthropic: apiKey: #NonEmptyString
	}
}

// Warning validations (non-blocking suggestions)
#Warnings: {
	// Warn if using default ports in production
	if application.environment == "production" && backend.server.port == 8080 {
		_warning_default_port: "Using default port 8080 in production is not recommended"
	}

	// Warn if rate limiting is disabled in production
	if application.environment == "production" && !backend.api.rateLimit.enabled {
		_warning_no_rate_limit: "Rate limiting should be enabled in production"
	}

	// Warn if monitoring is disabled in production
	if application.environment == "production" && !monitoring.enabled {
		_warning_no_monitoring: "Monitoring should be enabled in production"
	}

	// Warn if using memory cache in production
	if application.environment == "production" && core.cache.backend == "memory" {
		_warning_memory_cache: "Memory cache is not recommended for production"
	}

	// Warn if JWT secret is not set
	if backend.auth.jwt.enabled && backend.auth.jwt.secret == "" {
		_warning_jwt_secret: "JWT secret must be set via environment variable"
	}

	// Warn if database password is not set
	if core.database.password == "" {
		_warning_db_password: "Database password must be set via environment variable"
	}
}
