# Academic Workflow Suite - Examples & Demos

Comprehensive collection of examples, integrations, and demos for the Academic Workflow Suite.

## Overview

This directory contains working examples and demo applications to help you get started with the Academic Workflow Suite. All examples are production-ready and can be adapted for your specific needs.

## Quick Start

The fastest way to get started:

```bash
# Mark a TMA using shell script
cd quickstart
./mark_single_tma.sh my_essay.pdf

# Or using Python
python mark_single_tma.py my_essay.pdf student001 default

# Or using JavaScript
node mark_single_tma.js my_essay.pdf student001 default
```

## Directory Structure

```
examples/
├── quickstart/              # Quick start examples
├── api/                     # API integration examples
├── integrations/            # Third-party platform integrations
├── docker/                  # Docker deployment examples
├── automation/              # Automation workflows
├── custom-ai-models/        # Custom AI model configurations
├── plugins/                 # Plugin examples
├── tutorials/               # Step-by-step tutorials
└── demos/                   # Demo applications
```

## Contents

### 1. Quick Start Examples

Location: `/home/user/academic-workflow-suite/examples/quickstart/`

Get up and running in minutes with these copy-paste ready examples:

- **mark_single_tma.sh** - Shell script for marking a single TMA
- **mark_single_tma.py** - Python script with detailed output
- **mark_single_tma.js** - Node.js script for JavaScript developers
- **batch_marking.sh** - Process multiple TMAs in parallel
- **custom_rubric.yaml** - Example custom rubric configuration

**Usage:**
```bash
cd quickstart
./mark_single_tma.sh my_essay.pdf student001 default
```

### 2. API Integration Examples

Location: `/home/user/academic-workflow-suite/examples/api/`

#### Rust Client
Full-featured async Rust client with error handling:
```bash
cd api/rust
cargo build --release
cargo run -- --file essay.pdf --student-id student001
```

#### Python SDK
Complete Python SDK with pip installation:
```bash
cd api/python
pip install -e .
python examples/mark_tma.py essay.pdf
```

#### JavaScript SDK
Node.js SDK with npm package:
```bash
cd api/javascript
npm install
node examples/mark-tma.js essay.pdf
```

#### cURL Examples
Raw HTTP API examples for any platform:
```bash
cd api/curl
./submit_tma.sh essay.pdf student001 default
./get_feedback.sh <job_id> <tma_id>
./batch_processing.sh submissions/
```

### 3. Third-Party Integrations

Location: `/home/user/academic-workflow-suite/examples/integrations/`

#### Moodle Plugin
Native Moodle integration for automatic marking:
- Installation instructions
- PHP client library
- Automated submission processing
- Grade synchronization

**See:** [integrations/moodle/README.md](integrations/moodle/README.md)

#### Canvas LMS
Ruby-based Canvas integration:
- External tool configuration
- LTI integration
- Grade passback

**See:** [integrations/canvas/README.md](integrations/canvas/README.md)

#### Blackboard Learn
Java Building Block stub:
- REST API integration
- LTI 1.3 support
- Configuration examples

**See:** [integrations/blackboard/README.md](integrations/blackboard/README.md)

#### Zapier Workflows
Connect with 5000+ apps:
- Webhook triggers
- Email notifications
- Spreadsheet updates
- Pre-built Zap templates

**See:** [integrations/zapier/README.md](integrations/zapier/README.md)

#### n8n Workflows
Self-hosted automation:
- Complete workflow JSON
- Docker deployment
- Custom node creation

**See:** [integrations/n8n/README.md](integrations/n8n/README.md)

### 4. Docker Deployment

Location: `/home/user/academic-workflow-suite/examples/docker/`

#### Simple Setup
Minimal Docker Compose for development:
```bash
cd docker
docker-compose -f docker-compose.simple.yml up
```

Services:
- API server
- PostgreSQL database
- Redis cache

#### Full Production Setup
Complete production stack:
```bash
cd docker
docker-compose -f docker-compose.full.yml up
```

Services:
- Nginx reverse proxy
- API server (with replicas)
- Background workers
- Web UI
- PostgreSQL
- Redis
- MinIO (S3-compatible storage)
- Prometheus monitoring
- Grafana dashboards

### 5. Automation Examples

Location: `/home/user/academic-workflow-suite/examples/automation/`

#### Cron Jobs
Scheduled task examples:
- **daily_sync.sh** - Daily Moodle synchronization
- **weekly_backup.sh** - Weekly database backups

```bash
# Add to crontab
0 2 * * * /path/to/daily_sync.sh
0 3 * * 0 /path/to/weekly_backup.sh
```

#### Systemd Timers
Modern Linux scheduling:
```bash
sudo cp systemd/* /etc/systemd/system/
sudo systemctl enable awap-sync.timer
sudo systemctl start awap-sync.timer
```

#### GitHub Actions
Automated marking workflow:
- Triggers on push to submissions branch
- Processes all PDFs
- Generates markdown reports
- Commits results

**See:** [automation/github-actions/mark-assignments.yml](automation/github-actions/mark-assignments.yml)

#### GitLab CI
Continuous integration pipeline:
```yaml
# .gitlab-ci.yml
include:
  - local: '/examples/automation/gitlab-ci/.gitlab-ci.yml'
```

### 6. Custom AI Models

Location: `/home/user/academic-workflow-suite/examples/custom-ai-models/`

#### Supported Models
- **Mistral 7B Instruct** - Open-source alternative
- **Llama 2 7B** - Meta's open model
- **Custom Prompts** - Prompt engineering examples

#### Custom Prompts
Fine-tune marking behavior:
```text
examples/custom-ai-models/custom-prompts/
├── essay_marking_prompt.txt
├── lab_report_prompt.txt
├── code_review_prompt.txt
└── research_paper_prompt.txt
```

### 7. Plugin Examples

Location: `/home/user/academic-workflow-suite/examples/plugins/`

#### Custom Feedback Formatter
Format feedback in multiple styles:
- Markdown
- HTML
- LaTeX
- Plain text
- JSON

**Usage:**
```python
from plugins.custom_feedback_formatter import FeedbackFormatterPlugin

plugin = FeedbackFormatterPlugin({'format': 'html'})
formatted = plugin.format_feedback(results)
```

#### Plagiarism Checker
Integration with plagiarism detection services

#### Citation Validator
Validate citation formatting (APA, MLA, Chicago, IEEE)

### 8. Step-by-Step Tutorials

Location: `/home/user/academic-workflow-suite/examples/tutorials/`

#### Tutorial 1: Your First TMA
Complete beginner's guide to marking your first TMA
**Path:** tutorials/01_first_tma/

#### Tutorial 2: Custom Rubrics
Learn to create and use custom rubrics
**Path:** tutorials/02_custom_rubric/

#### Tutorial 3: Batch Processing
Process multiple TMAs efficiently
**Path:** tutorials/03_batch_processing/

#### Tutorial 4: Moodle Integration
Set up Moodle integration step-by-step
**Path:** tutorials/04_moodle_integration/

#### Tutorial 5: Custom Prompts
Fine-tune AI behavior with custom prompts
**Path:** tutorials/05_custom_prompts/

### 9. Demo Applications

Location: `/home/user/academic-workflow-suite/examples/demos/`

#### Web UI Demo
Simple browser-based interface:
```bash
cd demos/web-ui
python -m http.server 8000
# Open http://localhost:8000
```

Features:
- File upload
- Progress tracking
- Results display
- Feedback download

#### Terminal UI Demo
Text-based user interface using ratatui (Rust):
```bash
cd demos/terminal-ui
cargo run
```

## Environment Variables

Set these environment variables before running examples:

```bash
# Required
export AWS_API_URL="http://localhost:8080"

# Optional
export ANTHROPIC_API_KEY="your_key"
export OPENAI_API_KEY="your_key"
export MOODLE_URL="https://moodle.example.com"
export MOODLE_TOKEN="your_token"
```

## Common Use Cases

### Use Case 1: Single TMA Marking
```bash
# Quickest method
cd quickstart
./mark_single_tma.py essay.pdf student001
```

### Use Case 2: Batch Processing
```bash
# Process all PDFs in a directory
cd quickstart
./batch_marking.sh submissions/
```

### Use Case 3: Moodle Integration
```bash
# Automated daily sync
cd automation/cron
./daily_sync.sh
```

### Use Case 4: Custom Workflow
```bash
# Use n8n for custom automation
cd integrations/n8n
docker-compose up
# Import workflow.json
```

## Testing

Many examples include test data and scripts:

```bash
# Test Python SDK
cd api/python
pytest

# Test Rust client
cd api/rust
cargo test

# Test web UI locally
cd demos/web-ui
python -m http.server 8000
```

## Performance Tips

1. **Batch Processing**: Use parallel processing for multiple TMAs
2. **Caching**: Enable Redis caching for repeated requests
3. **CDN**: Use CloudFront or similar for file downloads
4. **Workers**: Scale background workers based on load
5. **Database**: Use connection pooling and indexes

## Security Best Practices

1. **API Keys**: Never commit API keys to git
2. **Environment Variables**: Use .env files (gitignored)
3. **HTTPS**: Always use HTTPS in production
4. **Authentication**: Implement OAuth2 or JWT
5. **Rate Limiting**: Protect against abuse
6. **Input Validation**: Sanitize all uploads

## Troubleshooting

### Common Issues

**Issue**: "Connection refused"
**Solution**: Verify API is running and URL is correct

**Issue**: "File upload failed"
**Solution**: Check file size limit and format (PDF only)

**Issue**: "Timeout errors"
**Solution**: Increase timeout values or check API performance

**Issue**: "Authentication failed"
**Solution**: Verify API key is set correctly

### Getting Help

- Check [Main Documentation](../docs/)
- Review [API Reference](../docs/api.md)
- See [Troubleshooting Guide](../docs/troubleshooting.md)
- Open GitHub Issues

## Contributing

We welcome contributions! To add your own examples:

1. Fork the repository
2. Create your example in the appropriate directory
3. Add documentation (README.md)
4. Include tests if applicable
5. Submit a pull request

### Example Template

```
examples/my-example/
├── README.md          # Documentation
├── example.py         # Main code
├── requirements.txt   # Dependencies
└── test.py           # Tests (optional)
```

## License

All examples are provided under the MIT License. See [LICENSE](../LICENSE) for details.

## Support

For questions or issues with these examples:

- **Documentation**: https://docs.academic-workflow-suite.example
- **GitHub Issues**: https://github.com/academic-workflow-suite/issues
- **Community Forum**: https://forum.academic-workflow-suite.example
- **Email**: support@academic-workflow-suite.example

## Changelog

### 2024-11-22
- Added comprehensive examples collection
- Created quickstart scripts
- Added SDK implementations (Rust, Python, JavaScript)
- Integrated with Moodle, Canvas, Blackboard
- Added Zapier and n8n workflows
- Created Docker deployment examples
- Added automation workflows
- Created demo applications

---

**Last Updated**: 2024-11-22
**Version**: 1.0.0
**Maintained By**: Academic Workflow Suite Team
