# Quick Start Guide

**Get AWS up and running in 10 minutes**

This guide will walk you through installing AWS and marking your first TMA with AI assistance.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation (5 minutes)](#installation-5-minutes)
- [First TMA Walkthrough (5 minutes)](#first-tma-walkthrough-5-minutes)
- [What Just Happened?](#what-just-happened)
- [Common Issues](#common-issues)
- [Next Steps](#next-steps)

---

## Prerequisites

Before you begin, ensure you have:

- **Microsoft Word** (2019 or later, or Office 365)
- **Internet connection** (for installation only)
- **Administrator access** (for software installation)
- **10 minutes** of uninterrupted time

### Operating System

- **Windows**: Windows 10 or later
- **macOS**: macOS 11 (Big Sur) or later
- **Linux**: Ubuntu 20.04+ or equivalent

---

## Installation (5 minutes)

### Step 1: Run the Installer

Open your terminal or PowerShell and run:

#### macOS/Linux

```bash
curl -sSL https://install.aws-edu.org/install.sh | bash
```

#### Windows

```powershell
iwr https://install.aws-edu.org/install.ps1 -useb | iex
```

### Step 2: Follow the Prompts

The installer will ask a few questions:

```
┌─────────────────────────────────────────────────┐
│  Academic Workflow Suite Installer             │
│  Version 0.1.0                                  │
└─────────────────────────────────────────────────┘

Select installation mode:
  1) Full (includes AI capabilities)      [Recommended]
  2) Lite (cloud AI only)
  3) Offline (no network after install)

Your choice [1]:
```

**Recommendation**: Choose **1** (Full) for the best experience.

```
Install location:
  Default: /usr/local/aws (macOS/Linux)
           C:\Program Files\AWS (Windows)

Press Enter to continue or type a custom path:
```

**Recommendation**: Press **Enter** to use the default location.

```
Installing components:
  ✓ AWS Core Engine (Rust)
  ✓ Office Add-in (ReScript)
  ✓ AI Jail Container
  ✓ System Dependencies

Estimated time: 3-4 minutes
```

Wait for the installation to complete. This may take a few minutes depending on your internet speed.

### Step 3: Verify Installation

Once complete, verify the installation:

```bash
aws-core --version
```

Expected output:

```
AWS Core Engine v0.1.0
Build: 2025-11-22-abc1234
Rust: 1.75.0
```

### Step 4: Start AWS Services

```bash
# Start the core engine
aws-core start

# Check status
aws-core status
```

Expected output:

```
✓ Core Engine:    Running (PID 12345)
✓ AI Jail:        Ready
✓ Office Add-in:  Installed
✓ Database:       OK (/Users/yourname/.aws/data)
```

### Step 5: Install Word Add-in

The installer should have automatically configured the Word add-in. To verify:

1. Open **Microsoft Word**
2. Look for **"AWS"** in the **Home** ribbon
3. If you don't see it, run:

```bash
aws-addin install
```

Then restart Word.

---

## First TMA Walkthrough (5 minutes)

Now let's mark your first TMA using AWS!

### Step 1: Prepare a Sample TMA

For this walkthrough, we'll use a sample TMA. Download it:

```bash
aws-core download-sample --module TM112 --assignment TMA01
```

This creates `~/Downloads/TM112-TMA01-Sample.docx`.

Alternatively, you can use any real TMA document you have.

### Step 2: Open TMA in Word

1. Open Microsoft Word
2. Open the TMA document (`File > Open`)
3. You should see the student's submission

```
┌─────────────────────────────────────────────────────┐
│  Microsoft Word - TM112-TMA01-Sample.docx           │
├─────────────────────────────────────────────────────┤
│  Home  Insert  Design  Layout  [AWS] ◄──────────┐   │
│                                                  │   │
│  Student ID: A1234567                            │   │
│  Module: TM112                                   │   │
│  Assignment: TMA01                               │   │
│                                                  │   │
│  Question 1: Explain the concept of...          │   │
│  [Student's essay text here...]                 │   │
│                                                  │   │
└──────────────────────────────────────────────────────┘
```

### Step 3: Launch AWS Add-in

1. Click the **AWS** tab in the ribbon
2. Click **"Open AWS Panel"**
3. The AWS task pane opens on the right side of Word

```
┌─────────────────────────────────────────────────┐
│  Word Document        │  AWS Task Pane          │
├───────────────────────┼─────────────────────────┤
│                       │  ┌───────────────────┐  │
│  Student's essay      │  │ Academic Workflow │  │
│  text appears here    │  │      Suite        │  │
│                       │  └───────────────────┘  │
│  Lorem ipsum dolor    │                         │
│  sit amet, consectetur│  Module: [Select...▾]   │
│  adipiscing elit.     │                         │
│  Sed do eiusmod       │  Assignment: [Select▾]  │
│  tempor incididunt.   │                         │
│                       │  [Load Document]        │
│  ...                  │                         │
│                       │                         │
└───────────────────────┴─────────────────────────┘
```

### Step 4: Configure Module & Assignment

In the AWS task pane:

1. **Module**: Select **"TM112"** from the dropdown
2. **Assignment**: Select **"TMA01"** from the dropdown
3. Click **"Load Document"**

AWS will analyze the document structure and extract the student submission.

```
┌─────────────────────────────────────────────────┐
│  AWS Task Pane                                  │
├─────────────────────────────────────────────────┤
│  Module: TM112                                  │
│  Assignment: TMA01                              │
│                                                 │
│  ✓ Document loaded                              │
│  ✓ Student ID detected: A1234567                │
│  ✓ Questions found: 3                           │
│                                                 │
│  Next step: Load or create rubric               │
│  [Load Rubric] [Create Custom]                  │
└─────────────────────────────────────────────────┘
```

### Step 5: Load the Marking Rubric

AWS comes with pre-configured rubrics for common OU modules.

1. Click **"Load Rubric"**
2. Select **"TM112 TMA01 Official Rubric"**
3. Review the criteria

```
┌─────────────────────────────────────────────────┐
│  Rubric: TM112 TMA01                            │
├─────────────────────────────────────────────────┤
│  Total Marks: 100                               │
│                                                 │
│  Criteria:                                      │
│  ✓ Understanding of Concepts (30 marks)         │
│  ✓ Critical Analysis (30 marks)                 │
│  ✓ Structure & Clarity (20 marks)               │
│  ✓ Use of Evidence (20 marks)                   │
│                                                 │
│  [Edit Rubric] [Analyze Submission]             │
└─────────────────────────────────────────────────┘
```

### Step 6: Analyze the Submission

This is where the magic happens!

1. Click **"Analyze Submission"**
2. AWS will:
   - Anonymize the student ID
   - Send the essay to the AI jail
   - Analyze against the rubric
   - Generate feedback suggestions

```
┌─────────────────────────────────────────────────┐
│  Analysis in Progress...                        │
├─────────────────────────────────────────────────┤
│  ✓ Anonymizing student data                     │
│  ✓ Preparing submission                         │
│  ⟳ AI analysis (this may take 10-30 seconds)    │
│                                                 │
│  [████████████░░░░░░] 60%                       │
└─────────────────────────────────────────────────┘
```

After 10-30 seconds, you'll see the results:

```
┌─────────────────────────────────────────────────┐
│  Analysis Complete                              │
├─────────────────────────────────────────────────┤
│  Suggested Scores:                              │
│                                                 │
│  Understanding of Concepts:      24/30 ★★★★☆    │
│  Critical Analysis:              22/30 ★★★☆☆    │
│  Structure & Clarity:            17/20 ★★★★☆    │
│  Use of Evidence:                15/20 ★★★☆☆    │
│  ───────────────────────────────────────        │
│  Total:                          78/100         │
│                                                 │
│  [View Detailed Feedback]                       │
└─────────────────────────────────────────────────┘
```

### Step 7: Review Feedback Suggestions

Click **"View Detailed Feedback"** to see AI-generated suggestions:

```
┌─────────────────────────────────────────────────┐
│  Detailed Feedback (Editable)                   │
├─────────────────────────────────────────────────┤
│  Understanding of Concepts (24/30)              │
│  ──────────────────────────────────────────     │
│  ✓ Good grasp of basic networking concepts      │
│  ✓ Accurate explanation of TCP/IP layers        │
│  ⚠ Could elaborate more on OSI model            │
│                                                 │
│  Suggested comment:                             │
│  "You demonstrate a solid understanding of      │
│   networking fundamentals. Your explanation of  │
│   TCP/IP is clear and accurate. To improve,     │
│   consider expanding your discussion of how     │
│   the OSI model relates to real-world protocols."
│                                                 │
│  [✎ Edit] [✓ Accept] [✗ Reject]                │
│  ─────────────────────────────────────────      │
│  Critical Analysis (22/30)                      │
│  ...                                            │
└─────────────────────────────────────────────────┘
```

### Step 8: Edit and Finalize Feedback

**Important**: AI suggestions are just that—suggestions. You're in control!

1. **Edit** any feedback to match your style and expertise
2. **Add** additional comments where needed
3. **Adjust** scores based on your judgment
4. **Remove** any suggestions you disagree with

```
┌─────────────────────────────────────────────────┐
│  Final Feedback (Your Version)                  │
├─────────────────────────────────────────────────┤
│  Understanding of Concepts (25/30) ◄─ adjusted  │
│  ──────────────────────────────────────────     │
│  "Well done! You show a good grasp of           │
│   networking concepts, particularly your        │
│   TCP/IP explanation. For even higher marks,    │
│   I'd like to see more depth in your OSI        │
│   discussion—specifically how the layers        │
│   map to protocols you mentioned."              │
│                                        ◄─ edited │
│  [Save Changes]                                 │
└─────────────────────────────────────────────────┘
```

### Step 9: Insert Feedback into Document

Once you're happy with the feedback:

1. Click **"Insert Feedback into Document"**
2. AWS will:
   - Add comments to the Word document
   - Insert scores at the appropriate locations
   - Generate a summary feedback box

Your Word document now looks like this:

```
┌─────────────────────────────────────────────────────┐
│  TM112 TMA01 - Student A1234567                     │
├─────────────────────────────────────────────────────┤
│  ╔══════════════════════════════════════════════╗   │
│  ║  Overall Mark: 81/100 (Adjusted by tutor)   ║   │
│  ║  Grade: B+                                   ║   │
│  ╚══════════════════════════════════════════════╝   │
│                                                     │
│  Question 1: Explain the concept of networking      │
│                                                     │
│  [Student's answer with inline comments] ◄─────┐    │
│   "Good point!" "Expand this" "Excellent!"    │    │
│                                               │    │
│  ┌─────────────────────────────────────────┐  │    │
│  │ Tutor Feedback:                         │  │    │
│  │ Well done! You show a good grasp of...  │◄─┘    │
│  │ [Full feedback inserted here]           │       │
│  └─────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────┘
```

### Step 10: Export and Submit

Finally, export the marked TMA:

1. Click **"Export"** in the AWS panel
2. Choose format:
   - **PDF** (most common for OU submission)
   - **Word with tracked changes**
   - **Plain text feedback**
3. Upload to OU TutorHome or StudentHome

```bash
# Exported files saved to:
~/Documents/AWS-Exports/TM112-TMA01-A1234567-marked.pdf
~/Documents/AWS-Exports/TM112-TMA01-A1234567-feedback.txt
```

---

## What Just Happened?

Let's recap what AWS did behind the scenes:

### 1. Document Analysis

- Parsed the Word document structure
- Identified student ID, module, and assignment
- Extracted question text and student responses

### 2. Anonymization (Privacy Protection)

```
Student ID: A1234567
     ↓ SHA3-512 Hash
Hash: 7f3a2b9c8e1d4a5c6f8b9e2d3c4a5b6c...
     ↓ Sent to AI Jail
```

The AI **never** sees the student ID. It only sees:
- Anonymous hash (irreversible)
- Essay content
- Rubric criteria

### 3. AI Analysis (Isolated Environment)

Inside the AI jail (no network, no storage):
- Compared essay against rubric
- Identified strengths and weaknesses
- Generated constructive feedback
- Suggested scores

### 4. Results Return

- Scores and feedback sent back to Core
- Core re-associates with student ID
- You review and edit everything
- Your decisions are final

### 5. Audit Trail

Every action logged:

```
2025-11-22 14:32:01 - Document loaded: TM112-TMA01
2025-11-22 14:32:15 - Student ID anonymized: A1234567
2025-11-22 14:32:47 - AI analysis complete
2025-11-22 14:35:22 - Tutor edited feedback
2025-11-22 14:36:10 - Feedback inserted into document
```

---

## Common Issues

### Issue 1: AWS Tab Not Showing in Word

**Symptom**: You don't see the "AWS" tab in the Word ribbon.

**Solution**:

```bash
# Reinstall the add-in
aws-addin install

# Restart Word
```

If still not working:

1. Open Word
2. Go to **File > Options > Add-ins**
3. Click **"Manage: COM Add-ins"** → **Go**
4. Ensure **"Academic Workflow Suite"** is checked

### Issue 2: "AI Jail Not Ready" Error

**Symptom**: Error when trying to analyze a submission.

**Solution**:

```bash
# Check if Docker/Podman is running
docker ps

# If not, start it
# macOS: Open Docker Desktop
# Linux: sudo systemctl start docker

# Restart AWS core
aws-core restart
```

### Issue 3: Slow AI Analysis

**Symptom**: Analysis takes longer than 30 seconds.

**Possible causes**:
- First run (AI model loading)
- Low RAM (< 4GB available)
- Large document (> 5000 words)

**Solutions**:
- Wait for first analysis to complete (models cached)
- Close other applications to free RAM
- For large documents, analyze question-by-question

### Issue 4: "Rubric Not Found" Error

**Symptom**: Can't load rubric for your module.

**Solution**:

```bash
# Download latest rubric repository
aws-core update-rubrics

# Or create a custom rubric
# (See USER_GUIDE.md for instructions)
```

### Issue 5: Installation Failed on Windows

**Symptom**: Installer exits with error.

**Common cause**: Execution policy restrictions.

**Solution**:

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Re-run installer
iwr https://install.aws-edu.org/install.ps1 -useb | iex
```

### Issue 6: "Permission Denied" on macOS/Linux

**Symptom**: Installer fails with permission error.

**Solution**:

```bash
# Option 1: Run with sudo (not recommended)
curl -sSL https://install.aws-edu.org/install.sh | sudo bash

# Option 2: Install to user directory
curl -sSL https://install.aws-edu.org/install.sh | bash -s -- --prefix ~/.local
```

---

## Next Steps

Congratulations! You've marked your first TMA with AWS. Here's what to explore next:

### 1. Learn the Full Feature Set

Read the [User Guide](USER_GUIDE.md) to discover:
- Creating custom rubrics
- Batch marking multiple TMAs
- Advanced feedback customization
- Statistics and analytics
- Keyboard shortcuts

### 2. Configure Your Preferences

Customize AWS to match your marking style:

```bash
# Open settings
aws-core config edit
```

Common settings:
- Feedback tone (formal/friendly)
- Scoring strictness
- Auto-save interval
- Theme (light/dark)

### 3. Import Your Module Rubrics

If you teach a module not yet in AWS:

```bash
# Create custom rubric
aws-core rubric create --module M250 --assignment TMA02

# Follow the interactive wizard
```

### 4. Join the Community

- **Forum**: https://discuss.aws-edu.org
- **Issue Tracker**: https://github.com/academic-workflow-suite/issues
- **Monthly Webinars**: Tips and tricks from experienced users

### 5. Explore Advanced Features

Once comfortable with basics, try:
- **Batch Mode**: Mark multiple TMAs in one session
- **Comparison View**: Compare student submissions side-by-side
- **Statistics Dashboard**: Analyze marking patterns
- **Voice Dictation**: Speak your feedback instead of typing

---

## Quick Reference Card

### Essential Commands

```bash
# Start/stop AWS
aws-core start
aws-core stop
aws-core restart

# Check status
aws-core status
aws-core doctor

# Update rubrics and software
aws-core update-rubrics
aws-core update

# View logs
aws-core logs
aws-core logs --tail 50

# Configuration
aws-core config edit
aws-core config show
```

### Keyboard Shortcuts (in Word)

| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+A` | Open AWS panel |
| `Ctrl+Alt+L` | Load document |
| `Ctrl+Alt+R` | Load rubric |
| `Ctrl+Alt+Enter` | Analyze submission |
| `Ctrl+Alt+S` | Save current feedback |
| `Ctrl+Alt+I` | Insert feedback into document |
| `Ctrl+Alt+E` | Export marked TMA |

### File Locations

| Item | Location |
|------|----------|
| Configuration | `~/.aws/config.toml` |
| Database | `~/.aws/data/` |
| Logs | `~/.aws/logs/` |
| Rubrics | `~/.aws/rubrics/` |
| Exports | `~/Documents/AWS-Exports/` |
| Cache | `~/.aws/cache/` |

---

## Troubleshooting Checklist

Before seeking help, try these steps:

- [ ] Check AWS is running: `aws-core status`
- [ ] Restart AWS: `aws-core restart`
- [ ] Check logs: `aws-core logs --tail 50`
- [ ] Verify Word add-in is enabled
- [ ] Update to latest version: `aws-core update`
- [ ] Run system diagnostics: `aws-core doctor`

If issues persist:

1. Check the [User Guide FAQ](USER_GUIDE.md#faq)
2. Search the [Forum](https://discuss.aws-edu.org)
3. File an [Issue](https://github.com/academic-workflow-suite/issues)

---

## Getting Help

### Documentation

- **[User Guide](USER_GUIDE.md)**: Comprehensive manual
- **[Installation Guide](INSTALLATION_GUIDE.md)**: Detailed install instructions
- **[FAQ](USER_GUIDE.md#faq)**: Common questions answered

### Community Support

- **Forum**: https://discuss.aws-edu.org
  - Search existing topics
  - Ask questions
  - Share tips and tricks

### Email Support

- **General**: support@aws-edu.org
- **Technical**: tech@aws-edu.org
- **Security**: security@aws-edu.org

Response time: Usually within 24 hours (weekdays)

---

## Feedback Welcome!

This is the first release of AWS, and we're eager to improve. Please share:

- What worked well?
- What was confusing?
- What features would you like to see?
- Any bugs or issues?

Submit feedback:
- **Survey**: https://survey.aws-edu.org/quick-start
- **Email**: feedback@aws-edu.org
- **GitHub**: https://github.com/academic-workflow-suite/discussions

---

**Happy Marking!** 🎓

You're now ready to supercharge your TMA marking workflow while maintaining complete privacy and control.

For more details, continue to the [User Guide](USER_GUIDE.md).

---

**Last Updated**: 2025-11-22
**Guide Version**: 1.0
