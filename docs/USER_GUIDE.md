# User Guide

**Complete user manual for Academic Workflow Suite**

This guide covers everything you need to know to use AWS effectively for marking TMAs.

---

## Table of Contents

- [Introduction](#introduction)
- [Getting Started](#getting-started)
- [Installing the Office Add-in](#installing-the-office-add-in)
- [Marking Your First TMA](#marking-your-first-tma)
- [Understanding AI Feedback](#understanding-ai-feedback)
- [Editing and Customizing Feedback](#editing-and-customizing-feedback)
- [Working with Rubrics](#working-with-rubrics)
- [Batch Marking](#batch-marking)
- [Exporting Marked TMAs](#exporting-marked-tmas)
- [Settings and Preferences](#settings-and-preferences)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Tips and Best Practices](#tips-and-best-practices)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [Getting Support](#getting-support)

---

## Introduction

### What is AWS?

Academic Workflow Suite (AWS) is an AI-assisted marking tool designed specifically for Open University tutors. It helps you:

- **Mark TMAs faster** without sacrificing quality
- **Maintain consistency** across multiple submissions
- **Generate constructive feedback** with AI assistance
- **Track your marking progress** and analytics
- **Protect student privacy** through anonymization

### Key Benefits

1. **Time Savings**: Reduce marking time by 30-40%
2. **Consistency**: Maintain uniform standards across all students
3. **Quality Feedback**: AI suggests comprehensive, constructive comments
4. **Privacy-First**: Student data never leaves your machine
5. **Full Control**: You decide what feedback to use—AI suggests, you approve

### How AWS Works

```
1. You load a student's TMA in Word
         ↓
2. AWS extracts student ID and essay content
         ↓
3. Student ID is anonymized (SHA3-512 hash)
         ↓
4. AI analyzes essay against rubric (no PII visible)
         ↓
5. AI suggests scores and feedback
         ↓
6. You review, edit, and approve suggestions
         ↓
7. Final feedback inserted into Word document
         ↓
8. Export and submit to OU systems
```

---

## Getting Started

### System Requirements

- **Microsoft Word** 2019+ or Office 365
- **Operating System**: Windows 10+, macOS 11+, or Linux
- **RAM**: 4 GB minimum (8 GB recommended)
- **Disk Space**: 2 GB free
- **Internet**: Required for installation only

### Installation

If you haven't installed AWS yet, see the [Quick Start Guide](QUICK_START.md) or [Installation Guide](INSTALLATION_GUIDE.md).

Quick installation:

```bash
# macOS/Linux
curl -sSL https://install.aws-edu.org/install.sh | bash

# Windows PowerShell
iwr https://install.aws-edu.org/install.ps1 -useb | iex
```

---

## Installing the Office Add-in

The Office add-in should be automatically installed during setup. If not:

### Manual Installation

#### macOS/Linux

```bash
aws-addin install
```

Then restart Microsoft Word.

#### Windows

```powershell
aws-addin install
```

Then restart Microsoft Word.

### Verifying Installation

1. Open Microsoft Word
2. Look for **"AWS"** tab in the ribbon
3. If you see it, installation was successful!

```
┌─────────────────────────────────────────────────┐
│  Word Ribbon                                    │
├─────────────────────────────────────────────────┤
│  Home  Insert  Design  Layout  [AWS] ◄────────  │
└─────────────────────────────────────────────────┘
```

### Troubleshooting Installation

If you don't see the AWS tab:

1. **Check Add-ins Settings**:
   - Word → File → Options → Add-ins
   - Manage: COM Add-ins → Go
   - Ensure "Academic Workflow Suite" is checked

2. **Reinstall**:
   ```bash
   aws-addin uninstall
   aws-addin install
   ```

3. **Check Logs**:
   ```bash
   aws-core logs --component office-addin
   ```

---

## Marking Your First TMA

Let's walk through marking a complete TMA from start to finish.

### Step 1: Open the TMA Document

1. Open Microsoft Word
2. Open the student's TMA document
   - File → Open
   - Navigate to TMA location
   - Select and open

```
Example TMA structure:
┌─────────────────────────────────────────────┐
│  Student ID: A1234567                       │
│  Module: TM112                              │
│  Assignment: TMA01                          │
│                                             │
│  Question 1: Explain...                     │
│  [Student's answer]                         │
│                                             │
│  Question 2: Discuss...                     │
│  [Student's answer]                         │
└─────────────────────────────────────────────┘
```

### Step 2: Open AWS Panel

1. Click the **AWS** tab in the Word ribbon
2. Click **"Open AWS Panel"**

The AWS task pane opens on the right side:

```
┌─────────────────────────────────────┐
│  Academic Workflow Suite            │
├─────────────────────────────────────┤
│                                     │
│  Module: [Select...▾]               │
│  Assignment: [Select...▾]           │
│                                     │
│  [Load Document]                    │
│                                     │
└─────────────────────────────────────┘
```

### Step 3: Load the Document

1. **Select Module** from dropdown (e.g., "TM112")
2. **Select Assignment** from dropdown (e.g., "TMA01")
3. Click **"Load Document"**

AWS will:
- Extract student ID automatically
- Parse document structure
- Prepare for analysis

```
┌─────────────────────────────────────┐
│  Document Loaded ✓                  │
├─────────────────────────────────────┤
│  Student: A1234567                  │
│  Module: TM112                      │
│  Assignment: TMA01                  │
│  Questions: 3                       │
│                                     │
│  [Load Rubric]                      │
└─────────────────────────────────────┘
```

### Step 4: Select Rubric

1. Click **"Load Rubric"**
2. Choose from available rubrics:
   - **Official rubrics** (provided by module coordinators)
   - **Your custom rubrics**
3. Review rubric criteria

```
┌─────────────────────────────────────┐
│  Rubric: TM112 TMA01 Official       │
├─────────────────────────────────────┤
│  Total: 100 marks                   │
│                                     │
│  Criteria:                          │
│  • Understanding (30 marks)         │
│  • Critical Analysis (30 marks)     │
│  • Structure (20 marks)             │
│  • Evidence (20 marks)              │
│                                     │
│  [Analyze Submission]               │
└─────────────────────────────────────┘
```

### Step 5: Analyze the Submission

1. Click **"Analyze Submission"**
2. Wait for AI analysis (10-30 seconds)

AWS will:
- Anonymize student ID
- Send essay to AI jail
- Generate feedback suggestions
- Calculate scores

```
┌─────────────────────────────────────┐
│  Analyzing... 65%                   │
├─────────────────────────────────────┤
│  ✓ Student ID anonymized            │
│  ✓ Rubric loaded                    │
│  ⟳ AI analysis in progress          │
│                                     │
│  [████████████░░░░] 65%             │
│                                     │
│  Estimated time: 8 seconds          │
└─────────────────────────────────────┘
```

### Step 6: Review AI Suggestions

After analysis completes, you'll see suggested scores and feedback:

```
┌─────────────────────────────────────┐
│  Analysis Complete ✓                │
├─────────────────────────────────────┤
│  Understanding:      24/30 ★★★★☆    │
│  Critical Analysis:  22/30 ★★★☆☆    │
│  Structure:          17/20 ★★★★☆    │
│  Evidence:           15/20 ★★★☆☆    │
│  ──────────────────────────────     │
│  Total: 78/100 (Grade: B+)          │
│                                     │
│  [View Detailed Feedback]           │
└─────────────────────────────────────┘
```

Click **"View Detailed Feedback"** to see comments for each criterion.

### Step 7: Edit Feedback

Review each criterion's feedback:

```
┌─────────────────────────────────────┐
│  Understanding of Concepts (24/30)  │
├─────────────────────────────────────┤
│  AI Suggestion:                     │
│  "You demonstrate a solid           │
│   understanding of networking       │
│   concepts. Your TCP/IP explanation │
│   is clear. Consider expanding your │
│   OSI model discussion."            │
│                                     │
│  [✎ Edit] [✓ Accept] [✗ Reject]   │
└─────────────────────────────────────┘
```

**To Edit**:
1. Click **"✎ Edit"**
2. Modify the text as needed
3. Adjust the score if desired
4. Click **"Save Changes"**

**Example Edit**:

Before (AI suggestion):
> "You demonstrate a solid understanding..."

After (your edit):
> "Excellent work! You show a comprehensive understanding of networking concepts, particularly your TCP/IP explanation. To achieve top marks, expand your OSI model discussion with more real-world examples."

Score: 24 → 26 (adjusted)

### Step 8: Finalize All Criteria

Repeat for each criterion:
- Understanding
- Critical Analysis
- Structure & Clarity
- Use of Evidence

**Important**: You can:
- ✅ **Accept** AI suggestions as-is
- ✏️ **Edit** suggestions to match your style
- ❌ **Reject** suggestions entirely and write your own
- 🎯 **Adjust** scores based on your judgment

### Step 9: Insert Feedback into Document

Once satisfied with all feedback:

1. Click **"Insert Feedback into Document"**
2. AWS will:
   - Add comments throughout the essay
   - Insert score breakdown
   - Add overall feedback summary

Your document now looks like this:

```
┌─────────────────────────────────────────────┐
│  TM112 TMA01 - Student A1234567             │
├─────────────────────────────────────────────┤
│  ╔════════════════════════════════════════╗ │
│  ║  Overall Mark: 80/100                  ║ │
│  ║  Grade: B+                             ║ │
│  ╚════════════════════════════════════════╝ │
│                                             │
│  Question 1: Networking Concepts            │
│                                             │
│  [Student's answer with inline comments]    │
│   "Good explanation" "Expand this"          │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ Feedback:                           │   │
│  │ Excellent work! You show a          │   │
│  │ comprehensive understanding...      │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

### Step 10: Export and Submit

1. Click **"Export"** in AWS panel
2. Choose format:
   - **PDF** (most common)
   - **Word with tracked changes**
   - **Text feedback only**
3. Save to your exports folder
4. Upload to OU TutorHome/StudentHome

---

## Understanding AI Feedback

### How AI Generates Feedback

The AI:

1. **Analyzes** the essay against each rubric criterion
2. **Identifies** strengths and weaknesses
3. **Compares** to typical responses at different grade levels
4. **Generates** constructive, personalized feedback
5. **Suggests** a score based on rubric levels

### Confidence Levels

Each suggestion includes a confidence score:

| Confidence | Meaning | Action |
|------------|---------|--------|
| **90-100%** ★★★★★ | Very confident | Usually accurate, but still review |
| **80-89%** ★★★★☆ | Confident | Good starting point, may need tweaking |
| **70-79%** ★★★☆☆ | Moderate | Significant review recommended |
| **<70%** ★★☆☆☆ | Low | Treat as initial draft only |

**Example**:

```
Understanding: 24/30 (Confidence: 85% ★★★★☆)

Interpretation:
- AI is fairly confident in this assessment
- Likely accurate, but review carefully
- Score may need ±1-2 mark adjustment
```

### Feedback Structure

AI feedback typically includes:

1. **Opening**: Overall assessment
2. **Strengths**: What the student did well
3. **Areas for Improvement**: Specific suggestions
4. **Examples**: Concrete instances from the essay
5. **Closing**: Encouragement and next steps

**Example**:

```
Opening:
"You demonstrate a solid understanding of networking concepts."

Strengths:
"Your explanation of TCP/IP is particularly clear and accurate."

Areas for Improvement:
"To improve, consider expanding your discussion of the OSI model
and how it relates to real-world protocols."

Closing:
"Overall, a strong foundation—work on adding more depth."
```

### Common AI Patterns

**Positive Feedback**:
- "Well done..."
- "You demonstrate..."
- "Your analysis shows..."
- "A strength of your essay is..."

**Constructive Criticism**:
- "Consider..."
- "To improve..."
- "You could strengthen this by..."
- "Future assignments would benefit from..."

**Specific Guidance**:
- "For example, you could discuss..."
- "Try expanding on..."
- "Include more details about..."

---

## Editing and Customizing Feedback

### Why Edit AI Feedback?

Even though AI generates helpful suggestions, you should always edit to:

1. **Match your teaching style**
2. **Add personal touches**
3. **Include course-specific references**
4. **Correct any AI errors or misconceptions**
5. **Adjust tone** (more/less formal, more/less encouraging)

### Editing Best Practices

#### 1. Personalize the Feedback

**AI Suggestion**:
> "Your essay demonstrates understanding of the concepts."

**Your Edit**:
> "Great work, Jane! Your essay shows a clear grasp of networking fundamentals."

#### 2. Add Specific References

**AI Suggestion**:
> "Consider using more evidence to support your claims."

**Your Edit**:
> "Consider referencing the case studies from Block 2, particularly the examples on pages 45-47."

#### 3. Adjust Tone

**AI Suggestion (formal)**:
> "The analysis requires further development."

**Your Edit (encouraging)**:
> "You're on the right track! Let's work on deepening your critical analysis—I'd love to see more of your own insights."

#### 4. Correct Errors

If AI misunderstands something:

**AI Suggestion (incorrect)**:
> "You incorrectly define TCP as a connectionless protocol."

**Your Correction (student was actually correct)**:
> "Excellent! You correctly identify TCP as a connection-oriented protocol, and your examples demonstrate this well."

#### 5. Balance Criticism with Praise

**AI Suggestion (too critical)**:
> "Your structure is poor and difficult to follow."

**Your Edit (balanced)**:
> "Your ideas are strong, but the structure could be clearer. Try using more transitional phrases between paragraphs. For example, in the transition from Question 1 to Question 2, a brief summary would help."

### Quick Edit Shortcuts

| Action | Shortcut |
|--------|----------|
| Edit feedback | Click ✎ or `Ctrl+E` |
| Accept suggestion | Click ✓ or `Ctrl+Enter` |
| Reject suggestion | Click ✗ or `Ctrl+Del` |
| Adjust score | Click score, type new value |
| Undo last edit | `Ctrl+Z` |
| Redo | `Ctrl+Shift+Z` |

---

## Working with Rubrics

### Using Official Rubrics

Official rubrics are provided by module coordinators:

1. Click **"Load Rubric"**
2. Select module and assignment
3. Choose official rubric
4. Review criteria and mark allocations

**Benefits**:
- Consistent with OU standards
- Updated annually
- Validated by module team
- Shared across all tutors

### Creating Custom Rubrics

For special cases or personal preferences:

1. Go to AWS panel → **"Rubrics"** tab
2. Click **"Create Custom Rubric"**
3. Fill in details:

```
┌─────────────────────────────────────┐
│  Create Custom Rubric               │
├─────────────────────────────────────┤
│  Name: TM112 TMA01 Custom           │
│  Module: TM112                      │
│  Assignment: TMA01                  │
│  Total Marks: 100                   │
│                                     │
│  Criteria:                          │
│  ┌────────────────────────────────┐ │
│  │ 1. Understanding (40 marks)    │ │
│  │ 2. Application (30 marks)      │ │
│  │ 3. Reflection (30 marks)       │ │
│  └────────────────────────────────┘ │
│                                     │
│  [Add Criterion] [Save Rubric]      │
└─────────────────────────────────────┘
```

4. For each criterion, define:
   - Name
   - Description
   - Maximum marks
   - Performance levels (optional)

### Rubric Performance Levels

Define what constitutes different grade levels:

```
Criterion: Critical Analysis (30 marks)

Performance Levels:
┌─────────────────────────────────────────┐
│ Excellent (27-30):                      │
│ • Thorough critical analysis            │
│ • Well-supported arguments              │
│ • Insightful evaluation                 │
│                                         │
│ Good (24-26):                           │
│ • Competent analysis                    │
│ • Some supporting evidence              │
│ • Clear reasoning                       │
│                                         │
│ Satisfactory (18-23):                   │
│ • Basic analysis                        │
│ • Limited evidence                      │
│ • Some gaps in reasoning                │
│                                         │
│ Poor (0-17):                            │
│ • Little or no critical analysis        │
│ • Unsupported claims                    │
│ • Significant gaps                      │
└─────────────────────────────────────────┘
```

### Sharing Rubrics

Share rubrics with other tutors on your module:

1. Select rubric
2. Click **"Export Rubric"**
3. Save as `.json` file
4. Share file with colleagues
5. They can import via **"Import Rubric"**

---

## Batch Marking

Mark multiple TMAs efficiently.

### Setting Up Batch Mode

1. Organize TMAs in a folder:

```
~/Documents/TM112-TMA01/
├── A1234567_TMA01.docx
├── A1234568_TMA01.docx
├── A1234569_TMA01.docx
└── ...
```

2. In AWS panel:
   - Click **"Batch Mode"**
   - Select folder
   - Choose rubric
   - Click **"Start Batch Analysis"**

### Batch Workflow

```
┌─────────────────────────────────────┐
│  Batch Analysis Progress            │
├─────────────────────────────────────┤
│  Total: 15 TMAs                     │
│  Completed: 5                       │
│  In Progress: 1                     │
│  Remaining: 9                       │
│                                     │
│  Current: A1234571_TMA01.docx       │
│  [████████░░░░░░░░░░] 40%           │
│                                     │
│  Estimated time: 12 minutes         │
└─────────────────────────────────────┘
```

AWS will:
1. Analyze all TMAs automatically
2. Save AI suggestions for each
3. Notify when complete

Then you:
1. Review each TMA individually
2. Edit AI feedback as needed
3. Approve and export

### Batch Review Mode

After batch analysis:

```
┌─────────────────────────────────────┐
│  Batch Review                       │
├─────────────────────────────────────┤
│  1. A1234567 - 78/100 ✓ Reviewed    │
│  2. A1234568 - 82/100 ⏳ Pending    │
│  3. A1234569 - 71/100 ⏳ Pending    │
│  4. A1234570 - 85/100 ⏳ Pending    │
│                                     │
│  [Next TMA] [Export All]            │
└─────────────────────────────────────┘
```

Click **"Next TMA"** to review each submission.

### Batch Export

Once all TMAs reviewed:

1. Click **"Export All"**
2. Choose format
3. All marked TMAs exported to folder:

```
~/Documents/AWS-Exports/TM112-TMA01/
├── A1234567-marked.pdf
├── A1234568-marked.pdf
├── A1234569-marked.pdf
└── ...
```

---

## Exporting Marked TMAs

### Export Formats

#### 1. PDF (Recommended)

**Use when**: Submitting to OU systems

**Contents**:
- Student essay
- Inline comments
- Score breakdown
- Overall feedback
- Professional formatting

**Example**:
```bash
aws-core export --document-id uuid-123 --format pdf
```

Output: `A1234567-TM112-TMA01-marked.pdf`

#### 2. Word Document with Tracked Changes

**Use when**: Student wants to see revision suggestions

**Contents**:
- Original essay
- Tracked changes showing suggested edits
- Comments for feedback
- Scores in margin

#### 3. Text Feedback Only

**Use when**: Copying feedback to OU StudentHome

**Contents**:
- Plain text feedback for each criterion
- Overall score
- No formatting

**Example output**:

```
TM112 TMA01 - Student A1234567
Overall Mark: 80/100 (Grade: B+)

Understanding of Concepts: 26/30
Excellent work! You demonstrate a comprehensive understanding...

Critical Analysis: 23/30
Your analysis shows promise. To improve, consider...

[... other criteria ...]
```

#### 4. JSON (Advanced)

**Use when**: Integrating with other systems

**Contents**:
- Structured data export
- All feedback and scores
- Metadata and timestamps

### Export Settings

Configure export preferences:

1. AWS panel → **Settings** → **Export**
2. Set defaults:

```
┌─────────────────────────────────────┐
│  Export Settings                    │
├─────────────────────────────────────┤
│  Default Format: [PDF ▾]            │
│                                     │
│  Destination:                       │
│  ~/Documents/AWS-Exports/           │
│  [Browse...]                        │
│                                     │
│  Filename Template:                 │
│  {student_id}-{module}-{assignment} │
│                                     │
│  Include:                           │
│  ☑ Rubric                           │
│  ☑ Scores                           │
│  ☑ Comments                         │
│  ☑ Overall feedback                 │
│                                     │
│  [Save Settings]                    │
└─────────────────────────────────────┘
```

### Uploading to OU Systems

After exporting:

1. **Log in to TutorHome**
2. Navigate to assignment
3. Find student
4. **Upload marked PDF**
5. **Enter scores** (if required separately)
6. **Submit**

---

## Settings and Preferences

### Accessing Settings

1. AWS panel → ⚙️ icon
2. Or: `Ctrl+,` (keyboard shortcut)

### General Settings

```
┌─────────────────────────────────────┐
│  General Settings                   │
├─────────────────────────────────────┤
│  Language: [English ▾]              │
│  Theme: [Auto ▾]                    │
│    • Auto (follows system)          │
│    • Light                          │
│    • Dark                           │
│                                     │
│  Auto-save: [Every 5 minutes ▾]     │
│                                     │
│  ☑ Check for updates automatically  │
│  ☐ Send anonymous usage statistics  │
│                                     │
│  [Save]                             │
└─────────────────────────────────────┘
```

### AI Settings

```
┌─────────────────────────────────────┐
│  AI Settings                        │
├─────────────────────────────────────┤
│  Model: [Standard ▾]                │
│    • Fast (quicker, simpler)        │
│    • Standard (balanced)            │
│    • High Quality (slower, better)  │
│                                     │
│  Feedback Tone:                     │
│    ( ) Very Formal                  │
│    (•) Formal                       │
│    ( ) Friendly                     │
│    ( ) Very Friendly                │
│                                     │
│  Feedback Length:                   │
│    ( ) Concise                      │
│    (•) Standard                     │
│    ( ) Detailed                     │
│                                     │
│  ☑ Include specific examples        │
│  ☑ Suggest improvements             │
│  ☐ Include positive-only feedback   │
│                                     │
│  [Save]                             │
└─────────────────────────────────────┘
```

### Privacy Settings

```
┌─────────────────────────────────────┐
│  Privacy Settings                   │
├─────────────────────────────────────┤
│  Student Data:                      │
│  ☑ Anonymize student IDs            │
│    (always enabled for AI)          │
│                                     │
│  Audit Logging:                     │
│  ☑ Log all actions                  │
│  ☑ Log AI suggestions               │
│  ☑ Log tutor edits                  │
│                                     │
│  Data Retention:                    │
│  Delete data after:                 │
│  [1 year ▾]                         │
│                                     │
│  [View Privacy Policy]              │
│  [Export My Data]                   │
│  [Delete All Data]                  │
└─────────────────────────────────────┘
```

### Notification Settings

```
┌─────────────────────────────────────┐
│  Notifications                      │
├─────────────────────────────────────┤
│  ☑ Analysis complete                │
│  ☑ Batch marking complete           │
│  ☑ Updates available                │
│  ☐ Daily marking summary            │
│                                     │
│  Notification Method:               │
│  ( ) System notifications           │
│  (•) In-app only                    │
│  ( ) None                           │
│                                     │
│  [Save]                             │
└─────────────────────────────────────┘
```

---

## Keyboard Shortcuts

### Global Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+A` | Open AWS panel |
| `Ctrl+Alt+L` | Load document |
| `Ctrl+Alt+R` | Load rubric |
| `Ctrl+,` | Open settings |
| `Ctrl+Alt+H` | Open help |

### Marking Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+Enter` | Analyze submission |
| `Ctrl+E` | Edit current feedback |
| `Ctrl+Enter` | Accept suggestion |
| `Ctrl+Del` | Reject suggestion |
| `Ctrl+S` | Save current edits |
| `Ctrl+Alt+I` | Insert feedback into document |
| `Ctrl+Alt+X` | Export marked TMA |

### Navigation Shortcuts

| Shortcut | Action |
|----------|--------|
| `Tab` | Next criterion |
| `Shift+Tab` | Previous criterion |
| `Ctrl+Alt+N` | Next TMA (batch mode) |
| `Ctrl+Alt+P` | Previous TMA (batch mode) |

### Customizing Shortcuts

1. Settings → **Keyboard Shortcuts**
2. Click shortcut to change
3. Press new key combination
4. Click **"Save"**

---

## Tips and Best Practices

### Marking Efficiently

1. **Use Batch Mode** for similar assignments
2. **Create feedback templates** for common issues
3. **Review AI suggestions before deep editing** (accept good ones quickly)
4. **Set aside dedicated marking time** (AI allows for focused sessions)
5. **Take breaks** (AWS saves your progress automatically)

### Improving Feedback Quality

1. **Always personalize** AI suggestions with student names
2. **Add specific examples** from the essay
3. **Balance criticism** with positive feedback
4. **Be constructive**, not just critical
5. **Include actionable advice** for improvement
6. **Reference course materials** when relevant

### Maintaining Consistency

1. **Use the same rubric** for all students in an assignment
2. **Review your first few TMAs** after completing all to check consistency
3. **Use comparison view** (AWS feature) to see score distributions
4. **Track your marking patterns** with AWS analytics
5. **Discuss edge cases** with module coordinator

### Privacy & Security

1. **Keep AWS updated** to latest version
2. **Use strong passwords** on your laptop (full-disk encryption recommended)
3. **Delete old marking data** at end of academic year
4. **Don't share screenshots** containing student information
5. **Log out** when leaving your computer unattended

### Working Offline

AWS works offline after initial setup:

1. **AI models downloaded** during installation
2. **Rubrics cached** locally
3. **No internet needed** for marking
4. **Only updates** require internet

To prepare for offline work:
```bash
# Download all rubrics for your modules
aws-core download-rubrics --module TM112 --module M250

# Download latest AI models
aws-core download-models
```

---

## FAQ

### General Questions

#### Q: Does AWS replace my judgment as a tutor?

**A**: No. AWS assists you by suggesting feedback and scores, but you review, edit, and approve everything. You remain in full control.

#### Q: How accurate are AI suggestions?

**A**: AI suggestions are typically 80-90% accurate for clear rubric criteria. They work best as a starting point that you refine based on your expertise.

#### Q: Can students tell that AI was used?

**A**: Only if you leave AI-generated feedback unedited. Always personalize feedback—add student names, specific examples, and your own insights.

#### Q: Does AWS work for all OU modules?

**A**: AWS works for any module where you can define a rubric. Some modules have pre-configured rubrics; for others, you can create custom ones.

### Privacy Questions

#### Q: Is student data sent to the cloud?

**A**: No. All student data stays on your local machine. The AI runs locally in an isolated container.

#### Q: Can the AI identify students?

**A**: No. Student IDs are hashed (SHA3-512) before AI analysis. The AI only sees anonymous hashes and essay content.

#### Q: What data does AWS collect?

**A**: By default, AWS collects no data. Optionally, you can enable anonymous usage statistics (no student information, just feature usage counts).

#### Q: How long is student data retained?

**A**: You control retention. We recommend deleting data at the end of each academic year. Configure in Settings → Privacy → Data Retention.

### Technical Questions

#### Q: Why does analysis take so long sometimes?

**A**: Analysis time depends on:
- Essay length (longer = slower)
- AI model (High Quality model is slower)
- Computer resources (more RAM/CPU = faster)
- First run (model loading takes extra time)

Typical times:
- Short essay (500 words): 5-10 seconds
- Medium essay (1500 words): 10-20 seconds
- Long essay (3000+ words): 20-30 seconds

#### Q: Can I use AWS on multiple computers?

**A**: Yes, but each installation is independent. To sync:
1. Export data: `aws-core export-data`
2. Transfer to other computer
3. Import data: `aws-core import-data`

#### Q: What if my laptop crashes mid-marking?

**A**: AWS auto-saves every 5 minutes (configurable). When you restart, you can resume from the last save point.

### Troubleshooting

#### Q: AI suggestions seem off-topic or incorrect

**A**: This can happen if:
- Rubric is poorly defined (try adding more detail)
- Essay is ambiguous
- AI model needs updating

**Solution**: Always review and edit AI suggestions. Report persistent issues to support@aws-edu.org.

#### Q: AWS panel disappeared in Word

**A**:
1. Click AWS tab → "Open AWS Panel"
2. Or restart Word
3. If still missing, reinstall: `aws-addin install`

#### Q: "AI Jail Not Ready" error

**A**:
1. Check Docker is running: `docker ps`
2. Restart AWS: `aws-core restart`
3. Check logs: `aws-core logs --component ai-jail`

---

## Troubleshooting

### Common Issues

#### Issue 1: AWS Tab Not Showing in Word

**Symptoms**: No AWS tab in Word ribbon

**Solutions**:

1. **Check if add-in is enabled**:
   - Word → File → Options → Add-ins
   - Manage: COM Add-ins → Go
   - Ensure "Academic Workflow Suite" is checked

2. **Reinstall add-in**:
   ```bash
   aws-addin uninstall
   aws-addin install
   ```
   Restart Word.

3. **Clear Office cache** (Windows):
   - Close Word
   - Delete: `%LOCALAPPDATA%\Microsoft\Office\16.0\Wef\`
   - Restart Word

4. **Clear Office cache** (macOS):
   ```bash
   rm -rf ~/Library/Containers/com.microsoft.Word/Data/Library/Caches/*
   ```

#### Issue 2: Analysis Fails or Times Out

**Symptoms**: "Analysis failed" or "Timeout" error

**Solutions**:

1. **Check AI jail status**:
   ```bash
   aws-core status
   ```
   Should show "AI Jail: Ready"

2. **Restart AI jail**:
   ```bash
   aws-core restart-ai
   ```

3. **Increase timeout** (for very long essays):
   - Settings → AI → Timeout: 60 seconds

4. **Try simpler model**:
   - Settings → AI → Model: Fast

5. **Check system resources**:
   - Close other applications
   - Ensure 4+ GB RAM available

#### Issue 3: Slow Performance

**Symptoms**: UI lags, analysis takes very long

**Solutions**:

1. **Check system requirements**:
   - RAM: 8 GB recommended
   - CPU: 4+ cores recommended
   - Disk: SSD recommended

2. **Close other applications**

3. **Use Fast AI model**:
   - Settings → AI → Model: Fast

4. **Disable auto-save**:
   - Settings → General → Auto-save: Disabled

5. **Clear cache**:
   ```bash
   aws-core clear-cache
   ```

#### Issue 4: Feedback Not Inserting into Document

**Symptoms**: Click "Insert Feedback" but nothing happens

**Solutions**:

1. **Check document permissions**:
   - Ensure document is not read-only
   - Save document before inserting feedback

2. **Try manual insertion**:
   - Copy feedback text
   - Paste into Word manually

3. **Restart Word and try again**

4. **Check logs for errors**:
   ```bash
   aws-core logs --component office-addin
   ```

#### Issue 5: Export Fails

**Symptoms**: "Export failed" error

**Solutions**:

1. **Check export folder exists**:
   - Settings → Export → Destination
   - Ensure folder exists and is writable

2. **Check disk space**:
   - Ensure sufficient space for PDF

3. **Try different format**:
   - PDF failed? Try Word format

4. **Export manually**:
   - Word → File → Save As PDF

### Getting Diagnostic Information

When contacting support, include:

```bash
# Generate diagnostic report
aws-core diagnose --output ~/aws-diagnostic.txt
```

This includes:
- AWS version
- System information
- Recent errors
- Configuration (no student data)

---

## Getting Support

### Documentation

- **Quick Start**: [QUICK_START.md](QUICK_START.md)
- **Installation Guide**: [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)
- **FAQ**: See [FAQ](#faq) section above
- **Video Tutorials**: https://aws-edu.org/videos

### Community Support

- **Forum**: https://discuss.aws-edu.org
  - Search existing topics
  - Ask questions
  - Share tips and best practices

- **Discord**: https://discord.gg/aws-users
  - Real-time chat
  - #help channel for questions
  - #feedback for suggestions

### Email Support

- **General**: support@aws-edu.org
  - Questions about using AWS
  - Bug reports
  - Feature requests

- **Technical**: tech@aws-edu.org
  - Installation issues
  - Technical problems
  - Integration questions

- **Privacy/Security**: security@aws-edu.org
  - Privacy concerns
  - Security questions
  - Data protection issues

**Response Times**:
- General: 24-48 hours (weekdays)
- Technical: 48-72 hours
- Security: 24 hours

### Reporting Bugs

When reporting bugs, include:

1. **AWS version**: `aws-core --version`
2. **Operating system**: Windows/macOS/Linux version
3. **Office version**: Word 2019/2021/365
4. **Steps to reproduce**: Detailed steps
5. **Expected vs. actual behavior**
6. **Diagnostic report**: `aws-core diagnose`
7. **Screenshots** (if relevant, no student data)

### Feature Requests

Submit feature requests via:
- **Forum**: https://discuss.aws-edu.org/c/feature-requests
- **GitHub**: https://github.com/academic-workflow-suite/aws/issues

Include:
- **Description**: What you want to do
- **Use case**: Why it's useful
- **Current workaround**: How you handle it now
- **Priority**: How important it is

---

## Conclusion

Congratulations! You now know how to use AWS effectively for marking TMAs.

### Key Takeaways

1. **AI assists, you decide**: Always review and edit AI suggestions
2. **Privacy first**: Student data stays on your machine
3. **Customize everything**: Rubrics, feedback tone, export formats
4. **Work efficiently**: Batch mode, templates, shortcuts
5. **Get support**: Forum, email, documentation

### Next Steps

1. **Mark your first TMA** using the [Quick Start Guide](QUICK_START.md)
2. **Join the community** at https://discuss.aws-edu.org
3. **Share feedback** to help improve AWS
4. **Explore advanced features** as you get comfortable

### Staying Updated

- **Enable auto-updates**: Settings → General → Auto-update
- **Check changelog**: https://aws-edu.org/changelog
- **Subscribe to newsletter**: https://aws-edu.org/newsletter

---

**Happy Marking!** 🎓

We hope AWS makes your TMA marking more efficient and enjoyable. Your feedback helps us improve the tool for all OU tutors.

For questions or support: support@aws-edu.org

---

**Last Updated**: 2025-11-22
**User Guide Version**: 1.0
