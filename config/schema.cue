package config

// Academic Workflow Suite Configuration Schema
// This file defines the complete configuration structure for the application

#Config: {
	// Application metadata and settings
	application: #Application

	// Core engine configuration
	core: #Core

	// Backend service configuration
	backend: #Backend

	// Office add-in configuration
	officeAddin: #OfficeAddin

	// AI jail configuration for sandboxed execution
	aiJail: #AIJail

	// Academic tools configuration
	academicTools: #AcademicTools

	// Monitoring and observability
	monitoring: #Monitoring

	// Logging configuration
	logging: #Logging

	// Security settings
	security: #Security
}

// Application metadata
#Application: {
	name:        string & !="" // Application name
	version:     string & =~"^\\d+\\.\\d+\\.\\d+(-[a-z0-9]+)?$" // Semantic version
	environment: #Environment // Current environment
	description: string | *"Academic Workflow Suite - Streamlining academic tasks"
}

// Environment types
#Environment: "production" | "staging" | "development" | "test"

// Core engine configuration
#Core: {
	// Database configuration
	database: #Database

	// Event store for event sourcing
	eventStore: #EventStore

	// Anonymization settings
	anonymization: #Anonymization

	// Cache configuration
	cache: #Cache
}

// Database configuration
#Database: {
	type:     "postgresql" | "mysql" | "sqlite" // Database type
	host:     string & !=""
	port:     int & >=1 & <=65535
	database: string & !=""
	username: string & !=""
	password: string // Should be provided via env var or secret
	ssl:      bool | *true
	poolSize: {
		min: int & >=1 | *2
		max: int & >=1 & <=100 | *10
	}
	timeout: {
		connect: int & >=1000 | *5000 // milliseconds
		query:   int & >=1000 | *30000
	}
	migrations: {
		enabled:   bool | *true
		directory: string | *"./migrations"
	}
}

// Event store configuration
#EventStore: {
	enabled: bool | *true
	backend: "postgresql" | "kafka" | "memory"
	retention: {
		days:        int & >=1 | *90
		compression: bool | *true
	}
	snapshotting: {
		enabled:  bool | *true
		interval: int & >=1 | *100 // events
	}
}

// Anonymization settings
#Anonymization: {
	enabled: bool | *true
	strategies: {
		students: #AnonymizationStrategy
		faculty:  #AnonymizationStrategy
		research: #AnonymizationStrategy
	}
	hashSalt: string // Should be provided securely
}

#AnonymizationStrategy: {
	fields: [...string] // Fields to anonymize
	method: "hash" | "redact" | "pseudonymize" | "encrypt"
	retain: [...string] | *[] // Fields to retain
}

// Cache configuration
#Cache: {
	enabled:  bool | *true
	backend:  "redis" | "memcached" | "memory"
	host:     string
	port:     int & >=1 & <=65535
	ttl:      int & >=60 | *3600 // seconds
	maxSize:  string | *"500MB" // e.g., "1GB", "500MB"
	keyPrefix: string | *"aws:"
}

// Backend service configuration
#Backend: {
	server:     #Server
	api:        #API
	auth:       #Auth
	moodle:     #MoodleIntegration
	plugins:    #Plugins
	jobs:       #Jobs
}

// Server configuration
#Server: {
	host:         string | *"0.0.0.0"
	port:         int & >=1024 & <=65535 | *8080
	readTimeout:  int & >=1000 | *30000 // milliseconds
	writeTimeout: int & >=1000 | *30000
	maxBodySize:  string | *"10MB"
	cors: {
		enabled:         bool | *true
		allowedOrigins:  [...string] | *["*"]
		allowedMethods:  [...string] | *["GET", "POST", "PUT", "DELETE", "OPTIONS"]
		allowedHeaders:  [...string] | *["*"]
		exposeHeaders:   [...string] | *[]
		allowCredentials: bool | *true
		maxAge:          int | *86400 // seconds
	}
	tls: {
		enabled:  bool | *false
		certFile: string
		keyFile:  string
	}
}

// API configuration
#API: {
	version:     string & =~"^v\\d+$" | *"v1"
	basePath:    string | *"/api"
	rateLimit: {
		enabled:     bool | *true
		maxRequests: int & >=1 | *100
		window:      int & >=1 | *60 // seconds
		byIP:        bool | *true
		byUser:      bool | *true
	}
	pagination: {
		defaultPageSize: int & >=1 & <=1000 | *25
		maxPageSize:     int & >=1 & <=10000 | *100
	}
	webhooks: {
		enabled:      bool | *false
		maxRetries:   int & >=0 | *3
		timeout:      int & >=1000 | *10000 // milliseconds
		secretHeader: string | *"X-Webhook-Secret"
	}
}

// Authentication configuration
#Auth: {
	jwt: {
		enabled:          bool | *true
		secret:           string // Should be provided securely
		issuer:           string | *"academic-workflow-suite"
		audience:         string | *"aws-users"
		accessTokenTTL:   int & >=60 | *3600 // seconds
		refreshTokenTTL:  int & >=3600 | *604800 // 7 days
		algorithm:        "HS256" | "HS384" | "HS512" | "RS256" | *"HS256"
	}
	oauth2: {
		enabled: bool | *false
		providers: {
			google?: #OAuth2Provider
			microsoft?: #OAuth2Provider
			github?: #OAuth2Provider
		}
	}
	saml: {
		enabled:     bool | *false
		idpMetadata: string
		spEntityID:  string
		callbackURL: string
	}
	session: {
		enabled:  bool | *true
		backend:  "memory" | "redis" | "database" | *"redis"
		ttl:      int & >=60 | *86400 // seconds
		cookieName: string | *"aws_session"
		secure:   bool | *true
		httpOnly: bool | *true
		sameSite: "strict" | "lax" | "none" | *"lax"
	}
}

#OAuth2Provider: {
	clientID:     string
	clientSecret: string
	redirectURL:  string
	scopes:       [...string]
}

// Moodle integration configuration
#MoodleIntegration: {
	enabled:  bool | *false
	baseURL:  string & =~"^https?://.+" // Must be valid URL
	apiToken: string
	version:  string | *"3.11"
	sync: {
		enabled:  bool | *false
		interval: int & >=60 | *3600 // seconds
		entities: [...("courses" | "users" | "assignments" | "grades")]
	}
	webhooks: {
		enabled:  bool | *false
		endpoint: string
		secret:   string
	}
}

// Plugins configuration
#Plugins: {
	enabled:    bool | *true
	directory:  string | *"./plugins"
	autoload:   bool | *true
	whitelist:  [...string] | *[]
	blacklist:  [...string] | *[]
}

// Background jobs configuration
#Jobs: {
	enabled:   bool | *true
	backend:   "redis" | "database" | "memory" | *"redis"
	workers:   int & >=1 & <=100 | *4
	queues: {
		default:  #JobQueue
		priority: #JobQueue
		batch:    #JobQueue
	}
}

#JobQueue: {
	maxRetries:    int & >=0 | *3
	timeout:       int & >=1000 | *300000 // milliseconds
	backoffDelay:  int & >=100 | *1000 // milliseconds
	concurrency:   int & >=1 | *2
}

// Office add-in configuration
#OfficeAddin: {
	enabled:  bool | *true
	features: #OfficeFeatures
	ui:       #OfficeUI
	sync:     #OfficeSync
}

#OfficeFeatures: {
	citationManager:    bool | *true
	rubricIntegration:  bool | *true
	gradeSync:          bool | *true
	commentTemplates:   bool | *true
	autoSave:           bool | *true
	offlineMode:        bool | *false
	realTimeCollaboration: bool | *false
}

#OfficeUI: {
	theme:         "light" | "dark" | "auto" | *"auto"
	compactMode:   bool | *false
	showTooltips:  bool | *true
	language:      string | *"en-US"
	customCSS:     string | *""
}

#OfficeSync: {
	enabled:       bool | *true
	autoSync:      bool | *true
	interval:      int & >=30 | *300 // seconds
	conflictResolution: "server" | "client" | "manual" | *"manual"
}

// AI jail configuration for sandboxed code execution
#AIJail: {
	enabled:  bool | *true
	models:   #AIModels
	runtime:  #ContainerRuntime
	resources: #ResourceLimits
	security: #JailSecurity
}

#AIModels: {
	enabled: [...string] | *["gpt-4", "claude-3", "local"]
	default: string | *"gpt-4"
	providers: {
		openai?: {
			apiKey:      string
			baseURL:     string | *"https://api.openai.com/v1"
			maxTokens:   int & >=1 | *4096
			temperature: number & >=0 & <=2 | *0.7
		}
		anthropic?: {
			apiKey:      string
			baseURL:     string | *"https://api.anthropic.com"
			maxTokens:   int & >=1 | *4096
			temperature: number & >=0 & <=1 | *0.7
		}
		local?: {
			modelPath:   string
			backend:     "ollama" | "llama.cpp" | "vllm"
			host:        string | *"localhost"
			port:        int & >=1 & <=65535 | *11434
		}
	}
}

#ContainerRuntime: {
	backend:      "docker" | "podman" | "containerd" | *"docker"
	socketPath:   string | *"/var/run/docker.sock"
	network:      "bridge" | "host" | "none" | *"bridge"
	image:        string | *"python:3.11-slim"
	timeout:      int & >=1000 | *60000 // milliseconds
	autoRemove:   bool | *true
}

#ResourceLimits: {
	cpu: {
		cores:   number & >0 & <=32 | *1
		shares:  int & >=1 | *1024
	}
	memory: {
		limit:   string | *"512MB" // e.g., "1GB", "512MB"
		swap:    string | *"0"
	}
	disk: {
		limit:   string | *"1GB"
		tmpfs:   string | *"100MB"
	}
	network: {
		enabled:       bool | *false
		bandwidthLimit: string | *"10MB"
	}
	time: {
		maxExecutionTime: int & >=1000 | *30000 // milliseconds
		maxIdleTime:      int & >=1000 | *5000
	}
}

#JailSecurity: {
	readOnlyRootFS:    bool | *true
	noNewPrivileges:   bool | *true
	dropCapabilities:  [...string] | *["ALL"]
	seccompProfile:    string | *"default"
	apparmorProfile:   string | *""
	allowedSyscalls:   [...string] | *[]
}

// Academic tools configuration
#AcademicTools: {
	citations:  #Citations
	rubrics:    #Rubrics
	plagiarism: #PlagiarismDetection
	analytics:  #Analytics
}

#Citations: {
	enabled: bool | *true
	formats: [...#CitationFormat] | *["APA", "MLA", "Chicago", "Harvard"]
	styles: {
		default: #CitationFormat | *"APA"
		custom:  [...#CustomCitationStyle]
	}
	bibliography: {
		autoGenerate: bool | *true
		format:       "bibtex" | "ris" | "endnote" | *"bibtex"
	}
	integrations: {
		zotero:     bool | *false
		mendeley:   bool | *false
		refWorks:   bool | *false
	}
}

#CitationFormat: "APA" | "MLA" | "Chicago" | "Harvard" | "IEEE" | "AMA" | "Vancouver"

#CustomCitationStyle: {
	name:      string
	template:  string
	fields:    [...string]
}

#Rubrics: {
	enabled:   bool | *true
	templates: [...#RubricTemplate]
	grading: {
		scale:         "percentage" | "points" | "letter" | *"percentage"
		roundingMode:  "up" | "down" | "nearest" | *"nearest"
		decimalPlaces: int & >=0 & <=4 | *2
	}
	export: {
		formats: [...("pdf" | "excel" | "csv" | "json")] | *["pdf", "excel"]
	}
}

#RubricTemplate: {
	id:          string
	name:        string
	description: string
	criteria:    [...#RubricCriterion]
	maxScore:    number & >0
}

#RubricCriterion: {
	name:        string
	description: string
	weight:      number & >=0 & <=1
	levels:      [...#RubricLevel]
}

#RubricLevel: {
	name:        string
	description: string
	score:       number & >=0
}

#PlagiarismDetection: {
	enabled:   bool | *false
	provider:  "turnitin" | "copyscape" | "local" | *"local"
	threshold: number & >=0 & <=100 | *20 // percentage
	api?: {
		endpoint: string
		apiKey:   string
		timeout:  int & >=1000 | *30000
	}
	local?: {
		algorithm:  "cosine" | "jaccard" | "levenshtein" | *"cosine"
		nGramSize:  int & >=1 & <=10 | *3
		minLength:  int & >=1 | *50 // words
	}
}

#Analytics: {
	enabled: bool | *true
	dashboards: {
		student:     bool | *true
		instructor:  bool | *true
		admin:       bool | *true
	}
	metrics: {
		performance:    bool | *true
		engagement:     bool | *true
		completion:     bool | *true
		timeTracking:   bool | *false
	}
	export: {
		enabled:  bool | *true
		formats:  [...("csv" | "excel" | "json" | "pdf")] | *["csv", "excel"]
		schedule: string | *"weekly" // cron expression or simple schedule
	}
}

// Monitoring configuration
#Monitoring: {
	enabled: bool | *true
	metrics: #Metrics
	tracing: #Tracing
	profiling: #Profiling
	healthCheck: #HealthCheck
}

#Metrics: {
	enabled:   bool | *true
	backend:   "prometheus" | "statsd" | "cloudwatch" | *"prometheus"
	endpoint:  string | *"/metrics"
	interval:  int & >=1 | *15 // seconds
	labels: {
		service:     string | *"academic-workflow-suite"
		environment: string
		version:     string
	}
}

#Tracing: {
	enabled:     bool | *false
	backend:     "jaeger" | "zipkin" | "tempo" | *"jaeger"
	endpoint:    string
	samplingRate: number & >=0 & <=1 | *0.1
	serviceName: string | *"academic-workflow-suite"
}

#Profiling: {
	enabled:    bool | *false
	backend:    "pprof" | "pyroscope" | *"pprof"
	endpoint:   string | *"/debug/pprof"
	continuous: bool | *false
}

#HealthCheck: {
	enabled:  bool | *true
	endpoint: string | *"/health"
	checks:   [...#HealthCheckItem]
}

#HealthCheckItem: {
	name:     string
	type:     "database" | "cache" | "external" | "custom"
	timeout:  int & >=100 | *5000 // milliseconds
	critical: bool | *true
}

// Logging configuration
#Logging: {
	level:      "debug" | "info" | "warn" | "error" | "fatal" | *"info"
	format:     "json" | "text" | "console" | *"json"
	output:     [...#LogOutput]
	structured: bool | *true
	caller:     bool | *false
	stackTrace: bool | *false
	sampling: {
		enabled: bool | *false
		initial: int & >=1 | *100
		thereafter: int & >=1 | *100
	}
}

#LogOutput: {
	type: "stdout" | "file" | "syslog" | "elasticsearch" | "loki"
	if type == "file" {
		path:       string
		maxSize:    string | *"100MB"
		maxAge:     int & >=1 | *30 // days
		maxBackups: int & >=0 | *7
		compress:   bool | *true
	}
	if type == "syslog" {
		network:  "tcp" | "udp"
		address:  string
		priority: string | *"info"
	}
	if type == "elasticsearch" {
		addresses: [...string]
		index:     string
		username:  string
		password:  string
	}
	if type == "loki" {
		url:    string
		labels: [string]: string
	}
}

// Security configuration
#Security: {
	encryption: #Encryption
	secrets:    #SecretsManagement
	cors:       #CORS
	csp:        #ContentSecurityPolicy
	rateLimit:  #GlobalRateLimit
	audit:      #AuditLog
}

#Encryption: {
	atRest: {
		enabled:   bool | *true
		algorithm: "AES-256-GCM" | "ChaCha20-Poly1305" | *"AES-256-GCM"
		keyRotation: {
			enabled:  bool | *true
			interval: int & >=86400 | *2592000 // seconds (30 days)
		}
	}
	inTransit: {
		enabled:      bool | *true
		minTLSVersion: "1.2" | "1.3" | *"1.2"
		cipherSuites: [...string]
	}
}

#SecretsManagement: {
	backend:   "env" | "vault" | "aws-secrets" | "azure-keyvault" | *"env"
	if backend == "vault" {
		address:   string
		token:     string
		mountPath: string | *"secret"
	}
	if backend == "aws-secrets" {
		region:    string
		prefix:    string | *"aws/"
	}
	if backend == "azure-keyvault" {
		vaultURL:  string
		tenantID:  string
		clientID:  string
	}
}

#CORS: {
	enabled:         bool | *true
	allowedOrigins:  [...string]
	allowedMethods:  [...string] | *["GET", "POST", "PUT", "DELETE", "OPTIONS"]
	allowedHeaders:  [...string] | *["Content-Type", "Authorization"]
	exposeHeaders:   [...string] | *[]
	allowCredentials: bool | *true
	maxAge:          int & >=0 | *86400
}

#ContentSecurityPolicy: {
	enabled:       bool | *true
	defaultSrc:    [...string] | *["'self'"]
	scriptSrc:     [...string] | *["'self'"]
	styleSrc:      [...string] | *["'self'", "'unsafe-inline'"]
	imgSrc:        [...string] | *["'self'", "data:", "https:"]
	connectSrc:    [...string] | *["'self'"]
	fontSrc:       [...string] | *["'self'"]
	objectSrc:     [...string] | *["'none'"]
	mediaSrc:      [...string] | *["'self'"]
	frameSrc:      [...string] | *["'none'"]
	reportURI:     string | *""
}

#GlobalRateLimit: {
	enabled:     bool | *true
	maxRequests: int & >=1 | *1000
	window:      int & >=1 | *60 // seconds
	blockDuration: int & >=0 | *300 // seconds
	whitelist:   [...string] | *[]
}

#AuditLog: {
	enabled:   bool | *true
	backend:   "database" | "file" | "elasticsearch" | "loki" | *"database"
	retention: int & >=1 | *365 // days
	events:    [...#AuditEvent]
}

#AuditEvent: "login" | "logout" | "create" | "update" | "delete" | "access" | "export" | "admin_action"
