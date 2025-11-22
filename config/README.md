# Academic Workflow Suite - Configuration System

This directory contains the CUE-based configuration system for the Academic Workflow Suite. CUE (Configure, Unify, Execute) provides type-safe configuration with validation, making it easier to manage complex application settings across multiple environments.

## Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Getting Started](#getting-started)
- [Configuration Files](#configuration-files)
- [Environments](#environments)
- [Validation](#validation)
- [Usage Examples](#usage-examples)
- [Schema Reference](#schema-reference)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

The configuration system uses CUE to:

- **Define schemas** with strict typing and validation rules
- **Validate configurations** before deployment
- **Support multiple environments** (production, staging, development, test)
- **Export to multiple formats** (JSON, YAML)
- **Prevent configuration errors** through compile-time checks
- **Document configuration** with inline comments and constraints

## Directory Structure

```
config/
├── schema.cue              # Main configuration schema definitions
├── defaults.cue            # Default values and environment overrides
├── validation.cue          # Validation rules and constraints
├── validate.sh             # Validation and export script
├── README.md               # This file
├── cue.mod/
│   └── module.cue          # CUE module definition
├── environments/
│   ├── production.cue      # Production environment config
│   ├── staging.cue         # Staging environment config
│   ├── development.cue     # Development environment config
│   └── test.cue            # Test environment config
└── output/                 # Generated configuration files (gitignored)
    ├── production.json
    ├── production.yaml
    └── ...
```

## Getting Started

### Prerequisites

1. **Install CUE**

   ```bash
   # macOS
   brew install cue-lang/tap/cue

   # Linux (with Go installed)
   go install cuelang.org/go/cmd/cue@latest

   # Or download binary from https://github.com/cue-lang/cue/releases
   ```

2. **Verify Installation**

   ```bash
   cue version
   ```

### Quick Start

1. **Validate all configurations**

   ```bash
   ./validate.sh validate
   ```

2. **Export production configuration to JSON**

   ```bash
   ./validate.sh export production json
   ```

3. **View development configuration**

   ```bash
   ./validate.sh show development yaml
   ```

## Configuration Files

### schema.cue

The main schema file defines the complete configuration structure for the application:

- **Application Settings**: Name, version, environment
- **Core Engine**: Database, event store, cache, anonymization
- **Backend Services**: Server, API, authentication, Moodle integration
- **Office Add-in**: Features, UI preferences, sync settings
- **AI Jail**: Models, container runtime, resource limits
- **Academic Tools**: Citations, rubrics, plagiarism detection, analytics
- **Monitoring**: Metrics, tracing, profiling, health checks
- **Logging**: Output formats, levels, destinations
- **Security**: Encryption, secrets management, CORS, CSP, audit logging

### defaults.cue

Contains default values for all environments:

- **#ProductionDefaults**: Base production configuration
- **#DevelopmentOverrides**: Development-specific overrides
- **#TestOverrides**: Test environment settings
- **#StagingOverrides**: Staging environment settings

### validation.cue

Defines validation rules and constraints:

- **Type Definitions**: URLs, emails, ports, memory sizes, etc.
- **Range Validations**: Port ranges, timeouts, percentages
- **Cross-field Validations**: Dependencies between settings
- **Environment Constraints**: Environment-specific requirements
- **Warning Validations**: Non-blocking recommendations

## Environments

### Production

**File**: `environments/production.cue`

Optimized for production deployment:
- TLS/SSL enabled
- Secure session cookies
- PostgreSQL database
- Redis cache
- Full monitoring and audit logging
- Encryption at rest and in transit

**Key Settings**:
- Server port: 8443 (HTTPS)
- Database: PostgreSQL with SSL
- Cache: Redis
- Logging: JSON format to files and stdout
- Security: Maximum security settings

### Staging

**File**: `environments/staging.cue`

Mirrors production with relaxed constraints:
- Similar to production but with debug logging
- Higher rate limits for testing
- Tracing enabled with higher sampling
- Allows profiling

**Key Settings**:
- Server port: 8443 (HTTPS)
- Database: PostgreSQL with SSL
- Enhanced debugging capabilities
- Moodle integration enabled

### Development

**File**: `environments/development.cue`

Optimized for local development:
- No TLS/SSL requirement
- Relaxed security settings
- Debug logging
- Local database
- No rate limiting

**Key Settings**:
- Server port: 8080 (HTTP)
- Database: PostgreSQL without SSL
- Cache: Redis (local)
- Logging: Console format with debug level
- CORS: Permissive for localhost

### Test

**File**: `environments/test.cue`

Optimized for automated testing:
- In-memory backends
- SQLite database
- Minimal logging
- Fast startup
- No external dependencies

**Key Settings**:
- Server port: 8081
- Database: SQLite in-memory
- Cache: Memory
- Jobs: Memory backend
- Minimal features enabled

## Validation

### Running Validations

**Validate all environments**:
```bash
./validate.sh validate
```

**Validate specific environment**:
```bash
./validate.sh validate production
./validate.sh validate development
```

**Check for schema violations**:
```bash
./validate.sh check production
```

### Validation Rules

The validation system checks:

1. **Type Correctness**: All values match their schema types
2. **Range Constraints**: Ports, timeouts, percentages are within valid ranges
3. **Format Validation**: URLs, emails, versions follow correct formats
4. **Cross-field Dependencies**: Related fields are consistent
5. **Environment Constraints**: Environment-specific requirements are met
6. **Security Requirements**: Production has secure defaults

### Common Validation Errors

**Invalid port range**:
```
backend.server.port: invalid value 99999 (out of bound <=65535)
```

**Missing required field**:
```
backend.moodle.baseURL: incomplete value string
```

**Type mismatch**:
```
core.database.port: conflicting values "5432" and int
```

## Usage Examples

### Export Configurations

**Export to JSON**:
```bash
./validate.sh export production json
./validate.sh export all json
```

**Export to YAML**:
```bash
./validate.sh export staging yaml
./validate.sh export all yaml
```

### View Configurations

**Show in JSON format**:
```bash
./validate.sh show development json
```

**Show in YAML format**:
```bash
./validate.sh show production yaml
```

**Show in CUE format**:
```bash
./validate.sh show staging cue
```

### Compare Configurations

**Compare two environments**:
```bash
./validate.sh diff production staging
./validate.sh diff development test yaml
```

### Using CUE Directly

**Validate a configuration**:
```bash
cue vet environments/production.cue schema.cue validation.cue
```

**Export to JSON**:
```bash
cue export environments/production.cue --out json
```

**Evaluate and print**:
```bash
cue eval environments/development.cue
```

**Format CUE files**:
```bash
cue fmt schema.cue
cue fmt environments/*.cue
```

## Schema Reference

### Application Configuration

```cue
application: {
    name:        string              // Application name
    version:     string              // Semantic version (e.g., "1.0.0")
    environment: "production" | "staging" | "development" | "test"
    description: string              // Optional description
}
```

### Core Configuration

```cue
core: {
    database: {
        type:     "postgresql" | "mysql" | "sqlite"
        host:     string
        port:     int & >=1 & <=65535
        database: string
        username: string
        password: string
        ssl:      bool
        poolSize: {min: int, max: int}
        timeout:  {connect: int, query: int}
    }

    cache: {
        backend:  "redis" | "memcached" | "memory"
        host:     string
        port:     int
        ttl:      int        // seconds
        maxSize:  string     // e.g., "500MB"
    }

    eventStore: {
        enabled: bool
        backend: "postgresql" | "kafka" | "memory"
        retention: {days: int, compression: bool}
    }

    anonymization: {
        enabled: bool
        strategies: {...}
        hashSalt: string
    }
}
```

### Backend Configuration

```cue
backend: {
    server: {
        host: string
        port: int & >=1024 & <=65535
        tls:  {enabled: bool, certFile: string, keyFile: string}
        cors: {...}
    }

    api: {
        version:    string
        basePath:   string
        rateLimit:  {...}
        pagination: {...}
        webhooks:   {...}
    }

    auth: {
        jwt:     {...}
        oauth2:  {...}
        saml:    {...}
        session: {...}
    }

    moodle: {
        enabled:  bool
        baseURL:  string
        apiToken: string
        sync:     {...}
    }

    jobs: {
        enabled: bool
        backend: "redis" | "database" | "memory"
        workers: int
        queues:  {...}
    }
}
```

### AI Jail Configuration

```cue
aiJail: {
    enabled: bool
    models: {
        enabled: [string]
        default: string
        providers: {...}
    }
    runtime: {
        backend:    "docker" | "podman" | "containerd"
        network:    "bridge" | "host" | "none"
        timeout:    int
        autoRemove: bool
    }
    resources: {
        cpu:    {cores: number, shares: int}
        memory: {limit: string, swap: string}
        disk:   {limit: string, tmpfs: string}
        time:   {maxExecutionTime: int, maxIdleTime: int}
    }
    security: {...}
}
```

### Academic Tools Configuration

```cue
academicTools: {
    citations: {
        enabled: bool
        formats: [string]  // APA, MLA, Chicago, etc.
        styles:  {...}
    }

    rubrics: {
        enabled:   bool
        templates: [...]
        grading:   {...}
    }

    plagiarism: {
        enabled:   bool
        provider:  "turnitin" | "copyscape" | "local"
        threshold: number
    }

    analytics: {
        enabled:    bool
        dashboards: {...}
        metrics:    {...}
    }
}
```

## Best Practices

### 1. Never Commit Secrets

- Use environment variables for sensitive data
- Set `password`, `secret`, `apiKey` fields to empty strings in CUE files
- Use a secrets management system (Vault, AWS Secrets Manager, etc.)

```cue
database: {
    password: "" // Set via AWS_DB_PASSWORD environment variable
}

auth: jwt: {
    secret: "" // Set via AWS_JWT_SECRET environment variable
}
```

### 2. Validate Before Deployment

Always validate configurations before deploying:

```bash
# Before deploying to production
./validate.sh validate production

# Export validated config
./validate.sh export production json
```

### 3. Use Environment Variables

Reference the config in your application to load from environment variables:

```bash
export AWS_DB_PASSWORD="secure-password"
export AWS_JWT_SECRET="secure-jwt-secret"
export AWS_MOODLE_TOKEN="moodle-api-token"
```

### 4. Document Custom Configurations

Add comments to explain non-obvious settings:

```cue
backend: server: {
    // Use non-standard port due to corporate firewall restrictions
    port: 8443

    // Higher timeout for large file uploads
    writeTimeout: 60000
}
```

### 5. Use Staging to Test Changes

Always test configuration changes in staging first:

```bash
# 1. Update staging config
vim environments/staging.cue

# 2. Validate
./validate.sh validate staging

# 3. Compare with production
./validate.sh diff staging production

# 4. Deploy to staging and test

# 5. Apply to production
```

### 6. Version Control Configuration

- Commit all `.cue` files to version control
- Add `output/` directory to `.gitignore`
- Tag releases with semantic versions
- Document breaking changes in commit messages

### 7. Use Defaults Wisely

Override only what's necessary in environment files:

```cue
// Good: Override specific values
config: #ProductionDefaults & {
    backend: server: port: 8443
    core: database: host: "db.example.com"
}

// Avoid: Redefining entire structures unnecessarily
```

## Troubleshooting

### CUE Not Found

**Error**: `cue: command not found`

**Solution**: Install CUE:
```bash
# macOS
brew install cue-lang/tap/cue

# Linux
go install cuelang.org/go/cmd/cue@latest
```

### Validation Errors

**Error**: `conflicting values`

**Solution**: Check the error message for the field path and ensure the value matches the schema type.

**Error**: `incomplete value`

**Solution**: A required field is missing. Check the schema for required fields.

**Error**: `out of bound`

**Solution**: A numeric value is outside the allowed range. Check validation constraints.

### Export Failures

**Error**: Export fails with validation errors

**Solution**: Run validation first to see detailed error messages:
```bash
./validate.sh validate production
```

### Port Already in Use

**Error**: When running different environments simultaneously

**Solution**: Ensure each environment uses a different port:
- Production: 8443
- Staging: 8443 (different host)
- Development: 8080
- Test: 8081

### Missing Dependencies

**Error**: Configuration references missing external services

**Solution**: For development, use local or mock services. For production, ensure all external dependencies are available and configured.

## Integration with Application

### Loading Configuration

The exported JSON/YAML files can be loaded by your application:

**Go Example**:
```go
import (
    "encoding/json"
    "os"
)

type Config struct {
    Application struct {
        Name        string `json:"name"`
        Version     string `json:"version"`
        Environment string `json:"environment"`
    } `json:"application"`
    // ... other fields
}

func LoadConfig(env string) (*Config, error) {
    data, err := os.ReadFile(fmt.Sprintf("config/output/%s.json", env))
    if err != nil {
        return nil, err
    }

    var config Config
    if err := json.Unmarshal(data, &config); err != nil {
        return nil, err
    }

    return &config, nil
}
```

**Python Example**:
```python
import json
import yaml
import os

def load_config(env='production', format='json'):
    config_file = f'config/output/{env}.{format}'

    with open(config_file, 'r') as f:
        if format == 'json':
            return json.load(f)
        elif format == 'yaml':
            return yaml.safe_load(f)

config = load_config(env=os.getenv('ENV', 'production'))
```

### CI/CD Integration

Add validation to your CI/CD pipeline:

**GitHub Actions Example**:
```yaml
name: Validate Configuration

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install CUE
        run: |
          go install cuelang.org/go/cmd/cue@latest

      - name: Validate All Configurations
        run: |
          cd config
          ./validate.sh validate

      - name: Export Production Config
        run: |
          cd config
          ./validate.sh export production json
```

## Additional Resources

- [CUE Language Documentation](https://cuelang.org/docs/)
- [CUE Tutorial](https://cuelang.org/docs/tutorials/)
- [CUE Playground](https://cuelang.org/play/)
- [Academic Workflow Suite Documentation](../README.md)

## Contributing

When adding new configuration options:

1. Update `schema.cue` with new fields and types
2. Add validation rules to `validation.cue`
3. Set defaults in `defaults.cue`
4. Update environment files as needed
5. Test with `./validate.sh validate`
6. Update this README with new options
7. Add examples and documentation

## License

See the main [LICENSE](../LICENSE) file in the project root.

---

**Last Updated**: 2025-11-22
**Version**: 1.0.0
