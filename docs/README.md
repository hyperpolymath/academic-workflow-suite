# Academic Workflow Suite (AWS)

**Privacy-First AI-Assisted TMA Marking System for The Open University**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.0-green.svg)](https://github.com/academic-workflow-suite)
[![Security](https://img.shields.io/badge/security-verified-brightgreen.svg)](SECURITY.md)

---

## Table of Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Components](#components)
- [Technology Stack](#technology-stack)
- [Security & Privacy](#security--privacy)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

---

## Overview

The **Academic Workflow Suite (AWS)** is an innovative, privacy-first platform designed specifically for Open University (OU) tutors to streamline the Tutor-Marked Assignment (TMA) marking process. By combining cutting-edge AI assistance with rigorous privacy controls, AWS enables tutors to provide faster, more consistent, and higher-quality feedback to students while maintaining complete control over student data.

### What is AWS?

AWS is not a replacement for human judgment in academic assessment. Instead, it's a **powerful assistant** that:

- **Analyzes** student submissions against customizable marking rubrics
- **Suggests** feedback and identifies common issues
- **Accelerates** the marking workflow without compromising quality
- **Ensures** complete privacy through AI isolation and data anonymization
- **Maintains** full audit trails for quality assurance

### Who is it for?

- **OU Tutors**: Primary users who mark TMAs and provide student feedback
- **Module Coordinators**: Configure rubrics and marking criteria
- **Quality Assurance Teams**: Audit marking consistency and quality
- **Academic Administrators**: Monitor marking throughput and turnaround times

---

## Motivation

### The Challenge

Marking TMAs is one of the most time-consuming yet critical tasks for OU tutors. The typical challenges include:

1. **Volume**: Tutors often mark 15-20 TMAs per assignment period
2. **Consistency**: Maintaining consistent standards across multiple submissions
3. **Turnaround Time**: Balancing thorough feedback with quick turnaround
4. **Quality**: Providing detailed, constructive feedback on every submission
5. **Mental Load**: Context-switching between different student approaches

### Current Solutions Fall Short

Existing tools offer limited assistance:

- **Manual Marking**: Time-intensive, prone to fatigue-induced inconsistency
- **Generic AI Tools**: Privacy concerns, no OU-specific context
- **Simple Automation**: Cannot handle nuanced academic assessment

### The AWS Solution

AWS addresses these challenges through:

- **Privacy-First Design**: Student data never leaves your control
- **AI Isolation**: No student information reaches AI systems
- **Event Sourcing**: Complete audit trail of all actions
- **OU Integration**: Designed specifically for OU workflows and terminology
- **Tutor Control**: AI suggests, tutor decides—always

---

## Key Features

### 1. Privacy & Security

- **Zero Student Data to AI**: Complete anonymization before AI analysis
- **Local-First Architecture**: Core data stored on your machine
- **Cryptographic Hashing**: Irreversible student identifier protection
- **Audit Trails**: Every action logged for accountability
- **GDPR Compliant**: Designed to meet strict privacy regulations

### 2. Intelligent Assistance

- **Rubric-Based Analysis**: AI evaluates against your marking criteria
- **Pattern Recognition**: Identifies common errors and misconceptions
- **Feedback Suggestions**: Generates constructive feedback templates
- **Quality Checks**: Flags potential issues for tutor review
- **Learning Over Time**: Adapts to your marking style (privacy-preserved)

### 3. Workflow Optimization

- **Office Add-in**: Seamless integration with Microsoft Word
- **Batch Processing**: Mark multiple TMAs efficiently
- **Progress Tracking**: Monitor marking status across assignments
- **Export Options**: Generate reports and statistics
- **Version Control**: Track changes and revisions

### 4. Customization

- **Module-Specific Rubrics**: Configure criteria for each course
- **Feedback Templates**: Build reusable comment libraries
- **Grading Scales**: Support for percentage, letter grades, and OU scales
- **Custom Workflows**: Adapt to your marking process

### 5. Quality Assurance

- **Consistency Metrics**: Compare marking across students
- **Outlier Detection**: Flag unusual scores or patterns
- **Second Marking Support**: Tools for moderation and review
- **Statistics Dashboard**: Analyze marking trends and distributions

---

## Architecture

AWS uses a multi-component architecture designed for privacy, security, and performance:

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER ENVIRONMENT                          │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  Microsoft Word + AWS Add-in               │ │
│  │  (Office.js + ReScript)                                    │ │
│  └───────────────────────┬────────────────────────────────────┘ │
│                          │ HTTPS/REST API                       │
│  ┌───────────────────────▼────────────────────────────────────┐ │
│  │                   AWS Core Engine (Rust)                   │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │ │
│  │  │ Event Store  │  │ Anonymizer   │  │ Business Logic  │  │ │
│  │  │   (LMDB)     │  │ (SHA3-512)   │  │   (Rubrics)     │  │ │
│  │  └──────────────┘  └──────────────┘  └─────────────────┘  │ │
│  └───────────────────────┬────────────────────────────────────┘ │
│                          │ Unix Socket (Local Only)             │
│  ┌───────────────────────▼────────────────────────────────────┐ │
│  │                    AI Jail (Isolated)                      │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  Sandboxed Container (gVisor/Firecracker)           │  │ │
│  │  │  - No Network Access                                │  │ │
│  │  │  - Limited File System                              │  │ │
│  │  │  - Memory Constraints                               │  │ │
│  │  │  - Only Anonymized Data                             │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                          │
                          │ (Optional) Backend API
                          │ (Shared Rubrics, Updates)
                          ▼
            ┌─────────────────────────────┐
            │   AWS Backend (Optional)    │
            │  - Rubric Repository        │
            │  - Update Server            │
            │  - No Student Data          │
            └─────────────────────────────┘
```

### Data Flow: Student Submission to AI Analysis

```
1. Student Submission (Word Document)
   │
   ├─ Student ID: "A1234567"
   ├─ Name: "Jane Smith"
   └─ Content: "Essay text..."
         │
         ▼
2. Core Engine: Anonymization
   │
   ├─ Student ID → Hash: "7f3a2b9c8e1d..."
   ├─ Name → Removed
   └─ Content → Preserved
         │
         ▼
3. AI Jail: Analysis (No Re-identification Possible)
   │
   ├─ Anonymous Hash: "7f3a2b9c8e1d..."
   ├─ Rubric Criteria
   └─ Essay Content
         │
         ▼
4. AI Response
   │
   ├─ Feedback: "Well-structured argument..."
   ├─ Scores: [Criterion A: 8/10, Criterion B: 7/10]
   └─ Hash: "7f3a2b9c8e1d..." (unchanged)
         │
         ▼
5. Core Engine: Re-association
   │
   ├─ Hash → Student ID: "A1234567"
   ├─ Feedback → Stored in Event Log
   └─ Tutor Review → Required
         │
         ▼
6. Word Add-in: Display to Tutor
   │
   ├─ Student: "A1234567 - Jane Smith"
   ├─ Suggested Feedback (editable)
   └─ Scores (tutor confirms)
```

### Key Architectural Principles

1. **Privacy by Design**: Anonymization at the boundary
2. **AI Isolation**: No network, no persistent storage, no PII
3. **Event Sourcing**: Immutable audit trail
4. **Local-First**: Core data never leaves user's machine
5. **Fail-Safe**: Tutor override at every decision point

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Quick Start

Get AWS running in under 10 minutes:

### Installation

```bash
# One-line installer (macOS/Linux)
curl -sSL https://install.aws-edu.org/install.sh | bash

# Windows PowerShell
iwr https://install.aws-edu.org/install.ps1 -useb | iex
```

### First TMA Marking

1. **Open Microsoft Word** and load a student TMA document
2. **Launch AWS Add-in** from the Home ribbon
3. **Select Module & Assignment** (e.g., "TM112 TMA01")
4. **Load Rubric** or create a custom one
5. **Click "Analyze Submission"**
6. **Review AI Suggestions** and edit as needed
7. **Finalize Feedback** and export to OU system

For a detailed walkthrough, see [QUICK_START.md](QUICK_START.md).

---

## Documentation

### User Documentation

- **[Quick Start Guide](QUICK_START.md)**: Get started in 10 minutes
- **[User Guide](USER_GUIDE.md)**: Complete end-user manual
- **[Installation Guide](INSTALLATION_GUIDE.md)**: Detailed installation instructions

### Technical Documentation

- **[Architecture](ARCHITECTURE.md)**: System design and components
- **[API Reference](API_REFERENCE.md)**: REST API documentation
- **[Security](SECURITY.md)**: Security model and privacy guarantees
- **[Development](DEVELOPMENT.md)**: Contributing and development guide

### Additional Resources

- **[FAQ](USER_GUIDE.md#faq)**: Frequently asked questions
- **[Troubleshooting](INSTALLATION_GUIDE.md#troubleshooting)**: Common issues and solutions
- **[Changelog](../CHANGELOG.md)**: Version history and updates

---

## System Requirements

### Minimum Requirements

- **Operating System**: Windows 10+, macOS 11+, or Linux (Ubuntu 20.04+)
- **RAM**: 4 GB (8 GB recommended)
- **Disk Space**: 2 GB free space
- **Office**: Microsoft Word 2019+ or Office 365
- **Internet**: Required for initial installation only

### Recommended Requirements

- **RAM**: 16 GB (for large batch processing)
- **CPU**: 4+ cores (for faster AI analysis)
- **SSD**: For improved performance
- **Display**: 1920x1080 or higher resolution

### Software Dependencies

Automatically installed by the installer:

- **Rust** 1.70+ (for core engine)
- **Node.js** 18+ (for Office add-in)
- **Docker** or **Podman** (for AI jail isolation)

---

## Installation

### Quick Install (Recommended)

```bash
# macOS/Linux
curl -sSL https://install.aws-edu.org/install.sh | bash

# Windows
iwr https://install.aws-edu.org/install.ps1 -useb | iex
```

### Installation Modes

AWS supports three installation modes:

1. **Full Mode** (Default): All components including AI capabilities
2. **Lite Mode**: Core features without local AI (cloud AI optional)
3. **Offline Mode**: No network requirements after installation

### Manual Installation

For manual installation or advanced configuration, see the [Installation Guide](INSTALLATION_GUIDE.md).

### Verification

After installation, verify your setup:

```bash
# Check AWS version
aws-core --version

# Run system check
aws-core doctor

# Test Office add-in
aws-addin test
```

---

## Components

AWS consists of five main components:

### 1. Core Engine (`components/core`)

**Language**: Rust
**Purpose**: Business logic, event sourcing, anonymization

- Event-sourced architecture for complete audit trails
- LMDB-based local storage for fast, privacy-preserving data access
- SHA3-512 cryptographic hashing for student anonymization
- Rubric management and scoring logic
- REST API for Office add-in integration

### 2. Office Add-in (`components/office-addin`)

**Language**: ReScript (compiles to JavaScript)
**Purpose**: Microsoft Word integration

- Seamless UI within Word task pane
- Document parsing and content extraction
- Real-time feedback display and editing
- Export to OU formats (PDF, Word, text)
- Offline-capable with local caching

### 3. AI Jail (`components/ai-jail`)

**Language**: Rust + Container Runtime
**Purpose**: Isolated AI analysis environment

- Sandboxed execution (gVisor or Firecracker)
- No network access—physically isolated
- Memory-limited execution
- Read-only filesystem for AI models
- Automatic cleanup after each analysis

### 4. Backend (Optional) (`components/backend`)

**Language**: Rust + Actix-Web
**Purpose**: Shared resources and updates

- Rubric repository and sharing
- Software update distribution
- Anonymous usage statistics (opt-in)
- **No student data ever stored**

### 5. Shared Libraries (`components/shared`)

**Language**: Rust, TypeScript
**Purpose**: Common types and utilities

- Data models and schemas
- Validation logic
- Utility functions
- Cross-component interfaces

---

## Technology Stack

### Backend/Core

- **Rust**: Memory-safe, high-performance systems language
- **Tokio**: Async runtime for concurrent processing
- **LMDB** (via Heed): Embedded transactional database
- **SHA3**: Cryptographic hashing (FIPS 202 compliant)
- **Actix-Web**: Web framework for REST API

### Frontend/Add-in

- **ReScript**: Type-safe functional language (compiles to JavaScript)
- **Office.js**: Microsoft Office add-in API
- **Webpack**: Module bundling and optimization
- **Jest**: Testing framework

### Infrastructure

- **Docker/Podman**: Container isolation for AI jail
- **gVisor/Firecracker**: Lightweight VM isolation (optional)
- **systemd**: Service management (Linux)
- **launchd**: Service management (macOS)

### AI/ML (Pluggable)

- **ONNX Runtime**: Cross-platform ML inference
- **llama.cpp**: Efficient LLM inference
- **Transformers**: Various pre-trained models
- **Custom Fine-tuned Models**: OU-specific rubric understanding

---

## Security & Privacy

### Privacy Guarantees

AWS provides mathematical guarantees that student data cannot be recovered by AI systems:

1. **One-Way Hashing**: Student IDs hashed with SHA3-512 (2^512 search space)
2. **No PII to AI**: Names, emails, and identifiers removed before AI analysis
3. **Local Storage**: All student data remains on your machine
4. **Network Isolation**: AI jail has zero network access
5. **Audit Trails**: Every data access logged and timestamped

### Security Features

- **Encrypted Storage**: Database encryption at rest (AES-256)
- **Secure Communication**: TLS 1.3 for add-in ↔ core communication
- **Code Signing**: All binaries cryptographically signed
- **Regular Audits**: Third-party security assessments
- **Vulnerability Disclosure**: Responsible disclosure program

### Compliance

- **GDPR**: Full compliance with data protection regulations
- **OU Policies**: Designed to meet OU security requirements
- **ISO 27001**: Following information security best practices

For complete security documentation, see [SECURITY.md](SECURITY.md).

---

## Contributing

We welcome contributions from the community! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

### Getting Started

1. Read the [Development Guide](DEVELOPMENT.md)
2. Check the [issue tracker](https://github.com/academic-workflow-suite/issues)
3. Fork the repository
4. Create a feature branch
5. Submit a pull request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/academic-workflow-suite/aws.git
cd aws

# Install dependencies
./scripts/dev/setup.sh

# Run tests
cargo test --workspace
npm test --workspace

# Start development servers
./scripts/dev/start-all.sh
```

### Code Standards

- **Rust**: `rustfmt` and `clippy` for code formatting and linting
- **ReScript**: ReScript compiler format checker
- **Git**: Conventional commits for clear history
- **Testing**: 80%+ code coverage required
- **Documentation**: All public APIs must be documented

---

## License

Academic Workflow Suite is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2024 Academic Workflow Suite Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

See [LICENSE](../LICENSE) for full details.

---

## Support

### Documentation

- **User Guide**: [USER_GUIDE.md](USER_GUIDE.md)
- **FAQ**: [USER_GUIDE.md#faq](USER_GUIDE.md#faq)
- **Troubleshooting**: [INSTALLATION_GUIDE.md#troubleshooting](INSTALLATION_GUIDE.md#troubleshooting)

### Community

- **Discussion Forum**: https://discuss.aws-edu.org
- **Issue Tracker**: https://github.com/academic-workflow-suite/issues
- **Email Support**: support@aws-edu.org

### Reporting Issues

When reporting issues, please include:

1. AWS version (`aws-core --version`)
2. Operating system and version
3. Office version
4. Steps to reproduce
5. Expected vs. actual behavior
6. Relevant log files (`~/.aws/logs/`)

### Security Issues

For security vulnerabilities, please email security@aws-edu.org directly.
**Do not** file public issues for security concerns.

---

## Roadmap

### Version 0.2.0 (Q1 2025)

- Enhanced rubric editor with visual designer
- Batch import of TMAs from OU systems
- Statistics dashboard for marking analytics
- Mobile app for feedback review (read-only)

### Version 0.3.0 (Q2 2025)

- Multi-language support (Welsh, Gaelic)
- Voice dictation for feedback
- Integration with OU StudentHome
- Collaborative marking for team assignments

### Version 1.0.0 (Q3 2025)

- Full OU certification and endorsement
- Advanced ML models fine-tuned on OU courses
- Real-time collaboration features
- Enterprise deployment options

---

## Acknowledgments

AWS is built with support from:

- **The Open University**: For supporting innovative teaching tools
- **OU Tutors**: For invaluable feedback and testing
- **Rust Community**: For an amazing language and ecosystem
- **ReScript Community**: For functional programming excellence
- **Privacy Advocates**: For guidance on privacy-preserving design

Special thanks to all contributors who have helped make AWS a reality.

---

## Project Status

**Current Version**: 0.1.0 (Alpha)
**Status**: Active Development
**Last Updated**: 2025-11-22

AWS is currently in alpha testing with a select group of OU tutors. We expect a beta release in Q1 2025 and a stable 1.0 release in Q3 2025.

---

**Built with care for the OU teaching community** ❤️

For more information, visit [https://aws-edu.org](https://aws-edu.org)
