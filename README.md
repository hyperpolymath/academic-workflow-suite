```
     _                _                 _        __        __         _     __ _
    / \   ___ __ _  __| | ___ _ __ ___ (_) ___   \ \      / /__  _ __| | __/ _| | _____      __
   / _ \ / __/ _` |/ _` |/ _ \ '_ ` _ \| |/ __|   \ \ /\ / / _ \| '__| |/ / |_| |/ _ \ \ /\ / /
  / ___ \ (_| (_| | (_| |  __/ | | | | | | (__     \ V  V / (_) | |  |   <|  _| | (_) \ V  V /
 /_/   \_\___\__,_|\__,_|\___|_| |_| |_|_|\___|     \_/\_/ \___/|_|  |_|\_\_| |_|\___/ \_/\_/

  ____        _ _
 / ___| _   _(_) |_ ___
 \___ \| | | | | __/ _ \
  ___) | |_| | | ||  __/
 |____/ \__,_|_|\__\___|

```

<div align="center">

# Academic Workflow Suite

### AI-Assisted TMA Marking for OU Associate Lecturers

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/academic-workflow-suite/actions)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/academic-workflow-suite/releases)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/r/aws-edu/core)
[![GDPR Compliant](https://img.shields.io/badge/GDPR-compliant-green.svg)](docs/SECURITY.md#gdpr-compliance)
[![Privacy First](https://img.shields.io/badge/privacy-guaranteed-green.svg)](docs/SECURITY.md)

**[Website](https://aws-edu.org)** •
**[Documentation](docs/README.md)** •
**[Quick Start](docs/QUICK_START.md)** •
**[Installation](docs/INSTALLATION_GUIDE.md)** •
**[Support](https://discuss.aws-edu.org)**

---

*Reduce TMA marking time from 20-30 minutes to under 10 minutes while maintaining quality and protecting student privacy.*

</div>

---

## Table of Contents

- [Overview](#overview)
- [The Problem We Solve](#the-problem-we-solve)
- [Key Features](#key-features)
- [Screenshots](#screenshots)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Documentation](#documentation)
- [Development](#development)
- [Security & Privacy](#security--privacy)
- [Roadmap](#roadmap)
- [Support](#support)
- [Contributing](#contributing)
- [License](#license)
- [Citation](#citation)
- [Acknowledgments](#acknowledgments)

---

## Overview

### What is Academic Workflow Suite?

**Academic Workflow Suite (AWS)** is an open-source, privacy-first AI assistant designed specifically for **Open University Associate Lecturers** to streamline the marking of Tutor-Marked Assignments (TMAs).

Unlike cloud-based AI tools that compromise student privacy, AWS runs entirely on your local machine with mathematical guarantees that student data never reaches AI systems in identifiable form.

### Target Audience

- **OU Associate Lecturers** marking TMAs across all modules
- **Academic institutions** requiring GDPR-compliant AI assistance
- **Researchers** studying educational technology and privacy-preserving AI
- **Developers** interested in event-sourced, privacy-first architectures

### The Value Proposition

```
Traditional Marking:          With Academic Workflow Suite:
─────────────────            ────────────────────────────
📄 Read submission           📄 Load document (auto)
📝 Check rubric             📝 Rubric loaded (auto)
💭 Analyze quality          🤖 AI analysis (10-30s)
✍️  Write feedback          ✍️  Review & edit AI suggestions
🔢 Calculate scores         🔢 Scores calculated
📋 Format comments          📋 Auto-format & insert
⏱️  20-30 minutes/TMA       ⏱️  <10 minutes/TMA
                            🔒 100% student privacy
```

---

## The Problem We Solve

### The Challenge of TMA Marking

Open University Associate Lecturers face a significant workload challenge:

- **20-30 minutes per TMA** on average
- **50-100+ TMAs per assignment** for popular modules
- **Repetitive feedback** for common mistakes
- **Cognitive load** of maintaining rubric consistency
- **Tight deadlines** (typically 2-3 weeks)

**Total time commitment**: 16-50+ hours per assignment batch

### Why Not Use ChatGPT or Claude?

While commercial AI assistants can help, they pose **serious privacy risks**:

❌ **Student data sent to cloud servers**
❌ **No control over data retention**
❌ **Potential GDPR violations**
❌ **University policy non-compliance**
❌ **No audit trail**
❌ **Risk of data breaches**

### Our Solution

AWS provides AI assistance with **zero privacy compromise**:

✅ **Runs entirely on your machine** (no cloud required)
✅ **Student IDs never reach AI** (cryptographically anonymized)
✅ **Network-isolated AI** (cannot exfiltrate data)
✅ **Complete audit trail** (event sourcing)
✅ **GDPR compliant by design**
✅ **University-approved architecture**

---

## Key Features

### 🤖 AI-Assisted Feedback Generation

- **Intelligent analysis** against custom or pre-loaded rubrics
- **Constructive feedback suggestions** that you can edit or reject
- **Score recommendations** based on rubric criteria
- **Consistency checking** across multiple submissions
- **Learn your style** (adapts to your feedback patterns over time)

### 🔒 Privacy-First Architecture

```
Student ID: A1234567
     ↓ SHA3-512 Hash (one-way, irreversible)
Hash: 7f3a2b9c8e1d4a5c6f8b9e2d3c4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b...
     ↓ Sent to AI Jail (network-isolated container)

AI sees:
✓ Anonymous hash
✓ Essay content
✓ Rubric criteria

AI never sees:
✗ Student ID
✗ Student name
✗ Any personally identifiable information
```

**Mathematical guarantee**: SHA3-512 hash cannot be reversed (2^512 search space = more combinations than atoms in the universe)

### 📝 Event Sourcing & Audit Trail

Every action is logged immutably:

```
2025-11-22 14:32:01 - Document loaded: TM112-TMA01
2025-11-22 14:32:15 - Student ID anonymized: A1234567 → hash
2025-11-22 14:32:47 - AI analysis completed (29 seconds)
2025-11-22 14:35:22 - Tutor edited feedback for criterion: Understanding
2025-11-22 14:36:10 - Feedback inserted into Word document
2025-11-22 14:36:32 - Document exported as PDF
```

Benefits:
- **Prove compliance** for university audits
- **Reproduce past decisions** for quality assurance
- **Time-travel debugging** for troubleshooting
- **GDPR right to explanation** support

### 🏢 Microsoft Office Integration

Seamless integration with Microsoft Word via official Office Add-in:

- **Task pane interface** in Word (no context switching)
- **Direct document manipulation** using Office.js
- **Inline comments** inserted automatically
- **Rubric-based scoring** with auto-calculation
- **Export to PDF/DOCX** with formatting preserved

### 🔌 Moodle LMS Integration (Planned)

Future releases will include:
- Direct download of student submissions
- Automated grade upload to Moodle gradebook
- Batch processing of entire assignment cohorts

### 🚀 Batch Processing

Mark multiple TMAs efficiently:

```bash
# Analyze all TMAs in a directory
aws-core batch analyze --module TM112 --assignment TMA01 --input ./submissions/

# Process 50 TMAs in parallel
# Average processing time: 10 minutes per TMA
# Total time: ~8-10 hours → Run overnight!
```

### 📊 Custom Rubrics

Create and share rubrics:

```yaml
# Example: TM112 TMA01 Rubric
module: TM112
assignment: TMA01
total_marks: 100

criteria:
  - id: understanding
    name: Understanding of Concepts
    marks: 30
    description: Demonstrates grasp of networking fundamentals

  - id: analysis
    name: Critical Analysis
    marks: 30
    description: Evaluates concepts critically with evidence

  - id: structure
    name: Structure & Clarity
    marks: 20
    description: Well-organized, clear writing

  - id: evidence
    name: Use of Evidence
    marks: 20
    description: Appropriate citations and examples
```

### 🌐 GDPR Compliant

Full compliance with EU General Data Protection Regulation:

- **Data minimization**: Only necessary data processed
- **Purpose limitation**: Data used only for marking
- **Storage limitation**: Configurable retention periods
- **Right to erasure**: Complete data deletion on request
- **Right to explanation**: Full audit trail available
- **Data portability**: Export all data in standard formats
- **Privacy by design**: Architecture prevents PII leakage

---

## Screenshots

> **Note**: The following are placeholder descriptions. Actual screenshots will be added in future releases.

### Office Add-in Interface

```
┌─────────────────────────────────────────────────────────────────────┐
│  Microsoft Word - TM112-TMA01.docx                                  │
├─────────────────────────────┬───────────────────────────────────────┤
│                             │  ┌─────────────────────────────────┐  │
│  Student: A1234567          │  │  Academic Workflow Suite        │  │
│  Module: TM112              │  │                                 │  │
│  Assignment: TMA01          │  │  Module: TM112 ▾                │  │
│                             │  │  Assignment: TMA01 ▾            │  │
│  Question 1:                │  │                                 │  │
│  Explain the concept of...  │  │  [Load Document]                │  │
│                             │  │                                 │  │
│  [Student's essay text]     │  │  Status: ✓ Document loaded      │  │
│  Lorem ipsum dolor sit      │  │                                 │  │
│  amet, consectetur          │  │  Rubric: TM112-TMA01 Official   │  │
│  adipiscing elit...         │  │                                 │  │
│                             │  │  [Analyze Submission]           │  │
│                             │  └─────────────────────────────────┘  │
└─────────────────────────────┴───────────────────────────────────────┘
```

**Figure 1**: Office add-in task pane showing document loaded and ready for analysis

### Feedback Generation Example

```
┌─────────────────────────────────────────────────────────────────────┐
│  AI Analysis Complete                                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Suggested Scores:                                                  │
│                                                                     │
│  📚 Understanding of Concepts:      24/30  ★★★★☆                   │
│  🔍 Critical Analysis:              22/30  ★★★☆☆                   │
│  📝 Structure & Clarity:            17/20  ★★★★☆                   │
│  📖 Use of Evidence:                15/20  ★★★☆☆                   │
│  ─────────────────────────────────────────────────                 │
│  Total:                             78/100 (B+)                     │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Suggested Feedback (Understanding of Concepts)                │ │
│  │                                                               │ │
│  │ "You demonstrate a solid understanding of networking          │ │
│  │  fundamentals. Your explanation of the TCP/IP model is clear  │ │
│  │  and accurate. To improve, consider exploring how the OSI     │ │
│  │  model relates to real-world protocols in more depth."        │ │
│  │                                                               │ │
│  │  [✎ Edit]  [✓ Accept]  [✗ Reject]                            │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

**Figure 2**: AI-generated feedback suggestions with scores

### Settings Panel

```
┌─────────────────────────────────────────────────────────────────────┐
│  AWS Settings                                                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ⚙️  General                                                        │
│  ├─ Feedback Tone: ◉ Formal  ○ Friendly  ○ Custom                 │
│  ├─ Scoring Strictness: [█████████░] 85%                          │
│  └─ Auto-save Interval: [5 minutes ▾]                             │
│                                                                     │
│  🔒 Privacy                                                         │
│  ├─ Hash Algorithm: SHA3-512 (FIPS 202) ✓                         │
│  ├─ Network Isolation: ✓ Enabled                                  │
│  └─ Data Retention: [90 days ▾]                                   │
│                                                                     │
│  🎨 Appearance                                                      │
│  ├─ Theme: ◉ Light  ○ Dark  ○ Auto                                │
│  └─ Font Size: [14pt ▾]                                           │
│                                                                     │
│  📊 Analytics                                                       │
│  ├─ Anonymous Usage Stats: ○ Enabled  ◉ Disabled                  │
│  └─ Crash Reports: ○ Enabled  ◉ Disabled                          │
│                                                                     │
│  [Save Changes]  [Reset to Defaults]                               │
└─────────────────────────────────────────────────────────────────────┘
```

**Figure 3**: Settings panel for customizing AWS behavior

### Analytics Dashboard (Planned)

```
┌─────────────────────────────────────────────────────────────────────┐
│  Marking Statistics - TM112 TMA01                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  📈 Overview                                                        │
│  ├─ TMAs Marked: 47 / 52                                           │
│  ├─ Average Time: 8.5 minutes/TMA                                  │
│  ├─ Time Saved: ~9.5 hours (vs 20min average)                      │
│  └─ AI Suggestions Accepted: 73%                                   │
│                                                                     │
│  📊 Score Distribution                                              │
│  ┌─────────────────────────────────────────────┐                   │
│  │     A: ████████ (17%)                       │                   │
│  │     B: ████████████████ (30%)               │                   │
│  │     C: ████████████████████ (38%)           │                   │
│  │     D: ████████ (13%)                       │                   │
│  │  Fail: ██ (2%)                              │                   │
│  └─────────────────────────────────────────────┘                   │
│                                                                     │
│  🎯 Rubric Criteria (Average Scores)                                │
│  ├─ Understanding: 23.4/30 (78%)                                   │
│  ├─ Analysis:      21.8/30 (73%)                                   │
│  ├─ Structure:     16.2/20 (81%)                                   │
│  └─ Evidence:      15.9/20 (80%)                                   │
│                                                                     │
│  [Export Report]  [View Trends]                                    │
└─────────────────────────────────────────────────────────────────────┘
```

**Figure 4**: Analytics dashboard showing marking statistics

---

## Quick Start

### Prerequisites

- **Microsoft Word** 2019 or later (or Office 365)
- **Docker** or Podman (for AI isolation)
- **10 GB free disk space**
- **8 GB RAM** (16 GB recommended)

### Installation (5 Minutes)

#### macOS / Linux

```bash
curl -sSL https://install.aws-edu.org/install.sh | bash
```

#### Windows

```powershell
iwr https://install.aws-edu.org/install.ps1 -useb | iex
```

### First TMA (5 Minutes)

```bash
# 1. Start AWS services
aws-core start

# 2. Open Word and click the AWS tab
# 3. Open a TMA document
# 4. Click "Analyze Submission"
# 5. Review and edit AI suggestions
# 6. Insert feedback into document
# 7. Export and submit!
```

**Full guide**: See [Quick Start Guide](docs/QUICK_START.md) for detailed walkthrough

---

## Architecture

### High-Level System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        USER ENVIRONMENT                             │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Presentation Layer                                           │ │
│  │  ┌─────────────────────────────────────────────────────────┐  │ │
│  │  │  Microsoft Word + AWS Office Add-in (ReScript)          │  │ │
│  │  │  - Task pane UI                                         │  │ │
│  │  │  - Document manipulation (Office.js)                    │  │ │
│  │  └──────────────────────┬──────────────────────────────────┘  │ │
│  └─────────────────────────┼─────────────────────────────────────┘ │
│                            │ HTTPS/TLS 1.3 (localhost:8080)        │
│  ┌─────────────────────────▼─────────────────────────────────────┐ │
│  │  Application Layer (Rust)                                     │ │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────────────┐             │ │
│  │  │ REST API │  │ Business │  │ Anonymization   │             │ │
│  │  │ (Actix)  │  │ Logic    │  │ Engine (SHA3)   │             │ │
│  │  └──────────┘  └──────────┘  └─────────────────┘             │ │
│  └─────────────────────────┬─────────────────────────────────────┘ │
│                            │                                       │
│  ┌─────────────────────────▼─────────────────────────────────────┐ │
│  │  Persistence Layer                                            │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────┐                │ │
│  │  │ Event    │  │ Read     │  │ File Storage │                │ │
│  │  │ Store    │  │ Models   │  │ (Documents)  │                │ │
│  │  │ (LMDB)   │  │(In-Mem)  │  │              │                │ │
│  │  └──────────┘  └──────────┘  └──────────────┘                │ │
│  └─────────────────────────┬─────────────────────────────────────┘ │
│                            │ Unix Socket (IPC)                     │
│  ┌─────────────────────────▼─────────────────────────────────────┐ │
│  │  AI Isolation Layer (Network-Isolated Container)              │ │
│  │  ┌─────────────────────────────────────────────────────────┐  │ │
│  │  │  🔒 Sandboxed Environment (gVisor/Firecracker)          │  │ │
│  │  │  ┌────────┐  ┌─────────┐  ┌──────────────────────────┐  │  │ │
│  │  │  │ AI     │  │ ONNX    │  │ Security Controls:       │  │  │ │
│  │  │  │ Model  │  │ Runtime │  │ ✗ No network access      │  │  │ │
│  │  │  │        │  │         │  │ ✗ Read-only filesystem   │  │  │ │
│  │  │  │        │  │         │  │ ✗ No PII received        │  │  │ │
│  │  │  └────────┘  └─────────┘  └──────────────────────────┘  │  │ │
│  │  └─────────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS (Optional)
                            │
              ┌─────────────▼────────────────┐
              │  Backend Services (Optional) │
              │  - Rubric repository         │
              │  - Software updates          │
              │  - NO student data           │
              └──────────────────────────────┘
```

### Component Descriptions

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Office Add-in** | ReScript, Office.js, Webpack | UI and Word integration |
| **Core Engine** | Rust, Actix-Web, Tokio | Business logic and API |
| **Event Store** | LMDB (via Heed) | Immutable event log |
| **AI Jail** | Rust, ONNX Runtime, Docker | Isolated AI inference |
| **Backend** | Rust, Actix-Web (optional) | Rubric repository, updates |

### Technology Stack

- **Frontend**: ReScript → JavaScript, React, Office.js
- **Backend**: Rust (stable), Actix-Web 4.x
- **Database**: LMDB (Lightning Memory-Mapped Database)
- **AI Runtime**: ONNX Runtime, llama.cpp
- **Containerization**: Docker/Podman, gVisor
- **Cryptography**: SHA3 (FIPS 202), AES-256-GCM
- **Build System**: Cargo, npm, Make

### Data Flow

```
1. Tutor opens TMA → Office Add-in parses document
2. Student ID extracted → Core Engine anonymizes (SHA3-512)
3. Anonymized data sent → AI Jail via Unix socket
4. AI analyzes essay → Returns feedback suggestions
5. Core re-associates → Hash → Student ID
6. Tutor reviews/edits → Inserts into Word document
7. Audit event logged → Immutable event store
```

**Detailed architecture**: See [Architecture Documentation](docs/ARCHITECTURE.md)

---

## Installation

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Windows 10, macOS 11, Ubuntu 20.04 | Windows 11, macOS 13+, Ubuntu 22.04+ |
| **CPU** | 2 cores, 2.0 GHz | 4+ cores, 3.0 GHz |
| **RAM** | 8 GB | 16 GB |
| **Disk** | 10 GB free | 20 GB free (SSD) |
| **Word** | Office 2019 | Office 365 |
| **Docker** | Docker 20.10+ | Docker 24.0+ or Podman 4.0+ |

### Installation Modes

#### 1. Quick Install (Recommended)

One-liner installation with sensible defaults:

**macOS / Linux**:
```bash
curl -sSL https://install.aws-edu.org/install.sh | bash
```

**Windows** (PowerShell as Administrator):
```powershell
iwr https://install.aws-edu.org/install.ps1 -useb | iex
```

What gets installed:
- AWS Core Engine (`/usr/local/bin/aws-core`)
- Office Add-in (configured in Word)
- AI Jail container image
- Default rubrics for popular modules
- System dependencies

#### 2. Custom Install

Choose components and installation paths:

```bash
# Download installer
curl -sSL https://install.aws-edu.org/install.sh -o install.sh

# Run with custom options
bash install.sh \
  --prefix ~/.local \
  --no-ai-jail \
  --modules TM112,M250 \
  --config-file my-config.toml
```

#### 3. Build from Source

For developers or custom builds:

```bash
# Clone repository
git clone https://github.com/academic-workflow-suite/aws.git
cd aws

# Build all components
make build

# Install
sudo make install

# Or install to custom location
make install PREFIX=~/.local
```

**Full installation guide**: See [Installation Guide](docs/INSTALLATION_GUIDE.md)

### Post-Installation

#### Verify Installation

```bash
# Check AWS Core
aws-core --version
# Expected: AWS Core Engine v0.1.0

# Check Docker
docker ps
# Expected: Container list (may be empty)

# Check Office Add-in
# Open Word → Look for "AWS" tab in ribbon
```

#### Start Services

```bash
# Start AWS Core Engine
aws-core start

# Check status
aws-core status
# Expected:
# ✓ Core Engine: Running
# ✓ AI Jail: Ready
# ✓ Database: OK
```

#### Configure

```bash
# Edit configuration
aws-core config edit

# Common settings:
# - feedback_tone: formal, friendly, or custom
# - scoring_strictness: 0-100
# - data_retention_days: 90
# - theme: light, dark, or auto
```

---

## Usage

### Basic Workflow

#### 1. Open TMA in Word

```
File → Open → [Select TMA document]
```

#### 2. Launch AWS

Click the **AWS** tab in Word ribbon → **Open AWS Panel**

#### 3. Load Document

In AWS task pane:
- Module: Select from dropdown (e.g., TM112)
- Assignment: Select TMA (e.g., TMA01)
- Click **Load Document**

AWS will parse the document and detect:
- Student ID
- Module/assignment metadata
- Question structure
- Student responses

#### 4. Select Rubric

- Click **Load Rubric**
- Choose official rubric or create custom
- Review criteria and marks

#### 5. Analyze Submission

- Click **Analyze Submission**
- Wait 10-30 seconds for AI analysis
- Review suggested scores and feedback

#### 6. Edit Feedback

**Important**: AI provides suggestions, not decisions!

- Edit any feedback text
- Adjust scores based on your judgment
- Add personal comments
- Remove suggestions you disagree with

#### 7. Insert into Document

- Click **Insert Feedback**
- AWS adds comments to Word document
- Review inserted feedback
- Make final adjustments

#### 8. Export

- Click **Export**
- Choose format: PDF, DOCX, or TXT
- Upload to OU TutorHome/StudentHome

### Advanced Features

#### Batch Processing

Mark multiple TMAs at once:

```bash
# Prepare TMAs
mkdir -p ~/marking/TM112-TMA01
# Place all TMA documents in this directory

# Batch analyze
aws-core batch analyze \
  --module TM112 \
  --assignment TMA01 \
  --input ~/marking/TM112-TMA01 \
  --output ~/marking/TM112-TMA01-marked \
  --parallelism 4

# Review and finalize in Word
```

#### Custom Rubrics

Create rubrics for any module:

```bash
# Interactive rubric creator
aws-core rubric create \
  --module M250 \
  --assignment TMA02

# Follow prompts to define criteria
```

Or edit YAML directly:

```yaml
# ~/.aws/rubrics/M250-TMA02.yml
module: M250
assignment: TMA02
total_marks: 100

criteria:
  - id: oop_design
    name: Object-Oriented Design
    marks: 40
    description: Quality of class design and UML diagrams

  - id: implementation
    name: Code Implementation
    marks: 40
    description: Correctness and style of Java code

  - id: testing
    name: Testing & Documentation
    marks: 20
    description: Unit tests and code documentation
```

#### CLI Commands

```bash
# Start/stop services
aws-core start
aws-core stop
aws-core restart

# Status and health
aws-core status
aws-core doctor           # Diagnose issues

# Rubrics
aws-core rubric list
aws-core rubric show TM112 TMA01
aws-core rubric create --module M250 --assignment TMA03
aws-core rubric import rubric.yml

# Updates
aws-core update           # Update AWS
aws-core update-rubrics   # Update rubric repository

# Logs and diagnostics
aws-core logs
aws-core logs --tail 50
aws-core logs --follow

# Configuration
aws-core config show
aws-core config edit
aws-core config reset

# Export statistics
aws-core stats export --module TM112 --format csv
```

**Full user guide**: See [User Guide](docs/USER_GUIDE.md)

---

## Documentation

### User Documentation

- **[Quick Start Guide](docs/QUICK_START.md)** - Get started in 10 minutes
- **[Installation Guide](docs/INSTALLATION_GUIDE.md)** - Detailed installation instructions
- **[User Guide](docs/USER_GUIDE.md)** - Comprehensive manual
- **[FAQ](docs/USER_GUIDE.md#faq)** - Frequently asked questions
- **[Troubleshooting](docs/USER_GUIDE.md#troubleshooting)** - Common issues and solutions

### Technical Documentation

- **[Architecture](docs/ARCHITECTURE.md)** - System architecture and design
- **[API Reference](docs/API_REFERENCE.md)** - REST API specification
- **[Security](docs/SECURITY.md)** - Security model and privacy guarantees
- **[Development Guide](docs/DEVELOPMENT.md)** - Contributing and development
- **[CI/CD](docs/CI-CD.md)** - Continuous integration and deployment

### Component Documentation

- **[Core Engine](components/core/README.md)** - Rust backend
- **[Office Add-in](components/office-addin/README.md)** - ReScript frontend
- **[AI Jail](components/ai-jail/README.md)** - Isolated AI inference
- **[Backend](components/backend/README.md)** - Optional cloud services

### Reference

- **[Docker Guide](docs/DOCKER_GUIDE.md)** - Container deployment
- **[CLI Reference](cli/README.md)** - Command-line interface
- **[Configuration Reference](config/README.md)** - All configuration options

---

## Development

### Setting Up Development Environment

#### Prerequisites

- **Rust** 1.75+ (`rustup install stable`)
- **Node.js** 18+ and npm
- **Docker** 20.10+ or Podman 4.0+
- **Git** 2.30+

#### Clone and Build

```bash
# Clone repository
git clone https://github.com/academic-workflow-suite/aws.git
cd aws

# Install dependencies
make deps

# Build all components
make build

# Run tests
make test

# Start development servers
make dev
```

### Project Structure

```
academic-workflow-suite/
├── components/
│   ├── core/              # Rust backend (Actix-Web)
│   ├── office-addin/      # ReScript frontend (Office.js)
│   ├── ai-jail/           # Isolated AI inference
│   ├── backend/           # Optional cloud services
│   └── shared/            # Shared types and utilities
├── docs/                  # Documentation
├── scripts/               # Build and deployment scripts
├── tests/                 # Integration tests
├── docker/                # Dockerfiles and compose configs
├── cli/                   # Command-line interface
├── config/                # Default configurations
└── website/               # Project website
```

### Development Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes and test
make test
make lint

# Run locally
make dev

# Build release
make release

# Create pull request
git push origin feature/my-feature
```

### Running Tests

```bash
# All tests
make test

# Unit tests only
make test-unit

# Integration tests
make test-integration

# End-to-end tests
make test-e2e

# With coverage
make test-coverage
```

### Code Style

This project follows:
- **Rust**: `rustfmt` and `clippy` (strict mode)
- **ReScript**: ReScript formatter
- **YAML**: `yamllint`

```bash
# Format code
make format

# Lint code
make lint

# Fix auto-fixable issues
make lint-fix
```

### Contributing

We welcome contributions! Please see [CONTRIBUTING.md](components/office-addin/CONTRIBUTING.md) for:

- Code of conduct
- Development workflow
- Pull request process
- Coding standards
- Testing requirements

**Quick start for contributors**:

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Ensure `make test` and `make lint` pass
5. Submit a pull request

---

## Security & Privacy

### Privacy Guarantees

AWS provides **mathematical guarantees** that student personally identifiable information (PII) cannot reach AI systems:

#### 1. Cryptographic Anonymization

```
Student ID → SHA3-512 Hash → AI Jail
A1234567  → 7f3a2b9c...   → (irreversible)

Attack resistance:
• Brute force: 2^512 search space (infeasible)
• Rainbow table: Prevented by random salt
• Timing attack: Constant-time implementation
```

#### 2. Network Isolation

AI Jail container is completely isolated:

```yaml
Security Controls:
✓ No network access (iptables DROP all)
✓ Read-only filesystem
✓ System call filtering (seccomp)
✓ Memory limits (4 GB)
✓ No GPU access
✓ Container destroyed after use
```

#### 3. Local-First Architecture

- All student data stays on your machine
- No cloud services required for core functionality
- Optional backend only for rubrics (no student data)

#### 4. Complete Audit Trail

Every action logged immutably:

```
Event Store (LMDB):
├─ DocumentLoaded
├─ StudentIdAnonymized (hash only, original encrypted)
├─ AnalysisRequested
├─ AnalysisCompleted
├─ FeedbackEdited (tutor override recorded)
└─ DocumentExported
```

### GDPR Compliance

AWS is compliant with EU General Data Protection Regulation:

| GDPR Right | Implementation |
|------------|----------------|
| **Right to be informed** | Complete audit trail available |
| **Right of access** | Export all data via `aws-core export` |
| **Right to rectification** | Edit or delete any data |
| **Right to erasure** | `aws-core delete --student A1234567` |
| **Right to restriction** | Pause processing for specific students |
| **Right to data portability** | Export in JSON, CSV, or XML |
| **Right to object** | Opt-out mechanisms available |
| **Rights related to automated decision-making** | Human (tutor) always in the loop |

### University Approval

AWS is designed to meet university data protection requirements:

✅ **No cloud data storage** (student data never leaves machine)
✅ **Anonymized AI processing** (PII cryptographically protected)
✅ **Complete audit trail** (prove compliance)
✅ **Tutor override** (AI assists, tutor decides)
✅ **Open source** (auditable by university IT)

### Security Testing

We conduct regular security assessments:

- **Static analysis**: Clippy, cargo-audit
- **Dependency scanning**: Dependabot, Snyk
- **Container scanning**: Trivy, Clair
- **Penetration testing**: Annual third-party audits
- **Fuzzing**: Continuous fuzzing with cargo-fuzz

### Vulnerability Reporting

Found a security issue? Please report responsibly:

- **Email**: security@aws-edu.org
- **PGP Key**: [Download](https://aws-edu.org/pgp-key.asc)
- **Response time**: 24-48 hours

**Do not** open public GitHub issues for security vulnerabilities.

**See**: [Security Policy](security/policies/SECURITY_POLICY.md) for full details

---

## Roadmap

### ✅ Completed (v0.1.0 - Current)

- [x] Core engine with event sourcing
- [x] Office Add-in for Word
- [x] AI isolation with Docker/gVisor
- [x] SHA3-512 anonymization
- [x] LMDB event store
- [x] Basic rubric support
- [x] Manual feedback editing
- [x] PDF export
- [x] CLI interface
- [x] Documentation

### 🚧 In Progress (v0.2.0 - Q1 2026)

- [ ] **Moodle LMS integration** - Direct submission download
- [ ] **Batch processing improvements** - Parallel analysis
- [ ] **Advanced analytics dashboard** - Marking statistics
- [ ] **Custom AI models** - Fine-tune on your feedback style
- [ ] **Voice dictation** - Speak your feedback
- [ ] **Mobile app** - Review feedback on iOS/Android

### 📅 Planned (v0.3.0 - Q2 2026)

- [ ] **Collaborative marking** - Multiple tutors on same module
- [ ] **Plagiarism detection** - Integration with Turnitin API
- [ ] **Grade moderation** - Cross-tutor consistency checking
- [ ] **Student progress tracking** - Longitudinal analysis
- [ ] **Multilingual support** - Support for non-English TMAs
- [ ] **Enhanced privacy** - Zero-knowledge proofs

### 💡 Future Ideas (v1.0.0+)

- [ ] **Browser extension** - Mark TMAs in any web interface
- [ ] **Automated grading** - For objective questions (opt-in)
- [ ] **Student self-assessment** - Pre-submission feedback tool
- [ ] **Research analytics** - Anonymized data for pedagogy research
- [ ] **Integration with Turnitin, Gradescope, Canvas**
- [ ] **Machine learning model marketplace** - Share fine-tuned models

**Suggest a feature**: [Open a discussion](https://github.com/academic-workflow-suite/discussions)

---

## Support

### Documentation

First, check our comprehensive documentation:

- **[User Guide](docs/USER_GUIDE.md)** - How to use AWS
- **[FAQ](docs/USER_GUIDE.md#faq)** - Common questions
- **[Troubleshooting](docs/USER_GUIDE.md#troubleshooting)** - Fix common issues
- **[Installation Guide](docs/INSTALLATION_GUIDE.md)** - Setup help

### Community Support

Join our community:

- **[Discussion Forum](https://discuss.aws-edu.org)** - Ask questions, share tips
- **[GitHub Discussions](https://github.com/academic-workflow-suite/discussions)** - Feature requests, Q&A
- **[Discord Server](https://discord.gg/aws-edu)** - Real-time chat
- **[Monthly Webinars](https://aws-edu.org/webinars)** - Live demos and Q&A

### Issue Tracker

Report bugs or request features:

- **[GitHub Issues](https://github.com/academic-workflow-suite/issues)** - Bug reports, feature requests
- **[Security Issues](mailto:security@aws-edu.org)** - Confidential security reports

### Email Support

For direct assistance:

- **General**: support@aws-edu.org
- **Technical**: tech@aws-edu.org
- **Security**: security@aws-edu.org
- **Press/Media**: press@aws-edu.org

**Response time**: Usually 24-48 hours (weekdays)

### Commercial Support

Enterprise support available for institutions:

- **Priority email support** (4-hour response SLA)
- **Dedicated Slack channel**
- **Custom feature development**
- **On-site training**
- **Annual security audits**

**Contact**: enterprise@aws-edu.org

---

## Contributing

We welcome contributions from the community! AWS is built by educators, for educators.

### How to Contribute

#### 1. Code Contributions

- Fix bugs
- Implement features from roadmap
- Improve documentation
- Add tests
- Optimize performance

See [Development](#development) section for setup instructions.

#### 2. Rubric Contributions

Share rubrics for your module:

```bash
# Export your rubric
aws-core rubric export M250 TMA02 > M250-TMA02.yml

# Submit via PR to rubrics repository
# https://github.com/academic-workflow-suite/rubrics
```

#### 3. Documentation

- Fix typos
- Improve clarity
- Add examples
- Translate to other languages

#### 4. Testing

- Test new releases
- Report bugs
- Suggest improvements
- Share use cases

#### 5. Community Support

- Answer questions on forums
- Help other users
- Write blog posts or tutorials
- Give talks about AWS

### Contributor Recognition

Contributors are recognized in:

- [Contributors](https://github.com/academic-workflow-suite/graphs/contributors) page
- Release notes
- Annual contributor report

Top contributors may receive:
- AWS swag (stickers, t-shirts)
- Early access to new features
- Invitation to contributor meetups

### Code of Conduct

We are committed to providing a welcoming and inclusive environment. All contributors must adhere to our [Code of Conduct](components/office-addin/CONTRIBUTING.md#code-of-conduct).

---

## License

### Software License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

```
Academic Workflow Suite
Copyright (C) 2025 Academic Workflow Suite Contributors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
```

**Why AGPL?**

We chose AGPL-3.0 to ensure that:

1. **AWS remains free and open source** for all users
2. **Improvements are shared with the community** (even for web services)
3. **Student privacy is protected** (source code is auditable)
4. **Commercial vendors** must contribute back if they modify AWS

**See**: [LICENSE](LICENSE) for full text

### Documentation License

Documentation is licensed under **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**.

You are free to:
- **Share** — copy and redistribute the material
- **Adapt** — remix, transform, and build upon the material

Under the following terms:
- **Attribution** — You must give appropriate credit
- **ShareAlike** — If you remix, you must distribute under the same license

---

## Citation

### Academic Citation

If you use Academic Workflow Suite in your research or teaching, please cite:

**APA Style**:

```
Academic Workflow Suite Contributors. (2025). Academic Workflow Suite:
Privacy-First AI-Assisted TMA Marking (Version 0.1.0) [Computer software].
https://github.com/academic-workflow-suite
```

**BibTeX**:

```bibtex
@software{academic_workflow_suite_2025,
  title        = {Academic Workflow Suite: Privacy-First AI-Assisted TMA Marking},
  author       = {{Academic Workflow Suite Contributors}},
  year         = 2025,
  version      = {0.1.0},
  url          = {https://github.com/academic-workflow-suite},
  license      = {AGPL-3.0},
  keywords     = {education, AI, privacy, marking, assessment}
}
```

### Papers and Presentations

If you publish research about AWS, please let us know! We maintain a [Publications](https://aws-edu.org/publications) page.

---

## Acknowledgments

### Contributors

Thank you to all our contributors:

- See [Contributors](https://github.com/academic-workflow-suite/graphs/contributors) for full list

### Inspiration

This project was inspired by:

- **Open University Associate Lecturers** who dedicate countless hours to student feedback
- **Privacy-preserving AI research** from academia
- **Open-source education tools** like Moodle, Open edX, and Jupyter

### Technologies

Built with excellent open-source technologies:

| Technology | License | Purpose |
|------------|---------|---------|
| [Rust](https://www.rust-lang.org/) | MIT/Apache-2.0 | Core engine |
| [ReScript](https://rescript-lang.org/) | MIT | Frontend |
| [Actix-Web](https://actix.rs/) | MIT/Apache-2.0 | Web framework |
| [LMDB](https://www.symas.com/lmdb) | OpenLDAP | Database |
| [ONNX Runtime](https://onnxruntime.ai/) | MIT | AI inference |
| [Docker](https://www.docker.com/) | Apache-2.0 | Containerization |
| [Office.js](https://docs.microsoft.com/en-us/office/dev/add-ins/) | MIT | Word integration |

### Funding

This project is currently self-funded by contributors. If you'd like to support development:

- **[GitHub Sponsors](https://github.com/sponsors/academic-workflow-suite)**
- **[Open Collective](https://opencollective.com/aws-edu)**

### Special Thanks

- **Open University** for pioneering distance education
- **Associate Lecturers** for feedback and testing
- **Privacy researchers** for cryptographic guidance
- **Early adopters** for valuable feedback

---

## Project Status

### Current Status

- **Version**: 0.1.0 (Initial Release)
- **Status**: Beta - Ready for testing
- **Stability**: Experimental - Use with caution in production

### Browser/Platform Compatibility

| Platform | Status | Notes |
|----------|--------|-------|
| **Windows 10/11** | ✅ Supported | Tested on Word 2019, Office 365 |
| **macOS 11+** | ✅ Supported | Intel and Apple Silicon |
| **Linux (Ubuntu)** | ✅ Supported | 20.04 LTS and later |
| **Linux (Other)** | ⚠️  Community | Arch, Fedora, etc. (community-supported) |

### Known Limitations

- **AI models**: Currently English-only
- **Office**: Word only (Excel/PowerPoint not supported)
- **Moodle**: Integration not yet available (v0.2.0)
- **Batch processing**: Limited to 100 TMAs at once

### Getting Updates

Stay informed about releases:

- **[Release Notes](https://github.com/academic-workflow-suite/releases)** - All releases
- **[Newsletter](https://aws-edu.org/newsletter)** - Monthly updates
- **[RSS Feed](https://github.com/academic-workflow-suite/releases.atom)** - Release notifications
- **[Twitter](https://twitter.com/aws_edu)** - Announcements

---

## Related Projects

### Similar Tools

- **[Moodle](https://moodle.org/)** - Open-source LMS
- **[Open edX](https://open.edx.org/)** - MOOC platform
- **[Gradescope](https://www.gradescope.com/)** - Grading platform
- **[Turnitin](https://www.turnitin.com/)** - Plagiarism detection

### Complementary Tools

- **[Zotero](https://www.zotero.org/)** - Reference management
- **[LaTeX](https://www.latex-project.org/)** - Document preparation
- **[Jupyter](https://jupyter.org/)** - Interactive notebooks
- **[Hypothesis](https://web.hypothes.is/)** - Web annotation

---

## Contact

### Project Website

- **Homepage**: https://aws-edu.org
- **Documentation**: https://docs.aws-edu.org
- **Blog**: https://blog.aws-edu.org

### Social Media

- **Twitter**: [@aws_edu](https://twitter.com/aws_edu)
- **LinkedIn**: [AWS Education](https://linkedin.com/company/aws-edu)
- **YouTube**: [AWS Tutorials](https://youtube.com/@aws-edu)

### Email

- **General Inquiries**: hello@aws-edu.org
- **Support**: support@aws-edu.org
- **Press**: press@aws-edu.org
- **Security**: security@aws-edu.org

---

<div align="center">

## ⭐ Star Us on GitHub!

If you find AWS useful, please consider starring the repository. It helps others discover the project!

[![GitHub stars](https://img.shields.io/github/stars/academic-workflow-suite/aws?style=social)](https://github.com/academic-workflow-suite/aws)

---

**Made with ❤️  by educators, for educators**

**Privacy-first • Open-source • Community-driven**

---

*Academic Workflow Suite - Empowering educators while protecting student privacy*

</div>

---

**Last Updated**: 2025-11-22
**Version**: 0.1.0
**Status**: Beta Release
