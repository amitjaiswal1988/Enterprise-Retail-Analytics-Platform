# 03 — Python Virtual Environment

## Creating, Activating, and Managing Your Python Environment

---

## What Is a Virtual Environment?

A **virtual environment** (venv) is a separate Python "box" for your project.


## Why Do We Need It?

| Without venv | With venv |
|-------------|-----------|
| All projects share same packages | Each project has its own packages |
| Version conflicts between projects | No conflicts — isolated |
| Upgrading one project breaks another | Safe — changes stay in one project |
| Hard to reproduce on another machine | Easy — `requirements.txt` has exact versions |

---

## Step 1: Create Virtual Environment

### What
Creates a `.venv` folder in your project with its own Python copy.

### Why
Isolates packages for this project only.

### When
Once — after cloning the repo.

### How

```powershell
# Make sure you're in the project root
cd C:\Users\Amit\Documents\Enterprise-Retail-Analytics-Platform

# Create the virtual environment
python -m venv .venv
```

### Breakdown

| Part | Meaning |
|------|---------|
| `python` | Use Python interpreter |
| `-m venv` | Run the "venv" module (built into Python) |
| `.venv` | Create folder named ".venv" (dot = hidden folder) |

### What Gets Created

```
.venv/
├── Scripts/         ← Python executables (activate, pip, python)
│   ├── python.exe
│   ├── pip.exe
│   ├── activate     (for Git Bash)
│   ├── Activate.ps1 (for PowerShell)
│   └── activate.bat (for CMD)
├── Lib/             ← Installed packages go here
└── pyvenv.cfg       ← Configuration file
```

---

## Step 2: Activate Virtual Environment

### What
"Turns on" the virtual environment so all commands use PROJECT Python, not system Python.

### Why
Without activation, `pip install` puts packages in system Python (bad practice).

### When
Every time you open a new terminal.

### How — PowerShell (Recommended for Windows)

```powershell
.venv\Scripts\Activate.ps1
```

### How — Git Bash

```bash
source .venv/Scripts/activate
```

### How — CMD (Command Prompt)

```cmd
.venv\Scripts\activate.bat
```

### Success Indicator

Terminal prompt changes to show `(.venv)`:
```
(.venv) C:\Users\Amit\Documents\Enterprise-Retail-Analytics-Platform>
```

### Common Error: "cannot be loaded because running scripts is disabled"

This happens in PowerShell. Fix:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Then try activation again.

---

## Step 3: Install Packages

### What
Download and install Python libraries needed by our project.

### Why
`generate_dataset.py` uses numpy, pandas, faker. Tests use pytest.

### When
After activation (once). Or when requirements.txt changes.

### How

```bash
pip install -r Python/requirements.txt
```

Or directly:
```bash
pip install numpy pandas faker pytest
```

### What Each Package Does

| Package | Version | Purpose in Our Project |
|---------|---------|----------------------|
| `numpy` | >=1.24 | Random number generation with seeds for reproducibility |
| `pandas` | >=2.0 | Create DataFrames and export to CSV |
| `faker` | >=18.0 | Generate realistic names, emails, addresses, companies |
| `pytest` | >=7.4 | Run 68 automated data quality tests |

### Verify Installation

```bash
pip list
```

Should show numpy, pandas, faker, pytest with versions.

---

## Step 4: Deactivate (When Done)

### What
"Turns off" the virtual environment, goes back to system Python.

### Why
Not strictly necessary, but good practice when switching projects.

### When
When you're done working on this project for the day.

### How

```bash
deactivate
```

The `(.venv)` prefix disappears from terminal prompt.

---

## VS Code Interpreter Selection

### What
Tell VS Code which Python to use for IntelliSense, debugging, etc.

### Why
VS Code might default to system Python — we want it to use our .venv Python.

### How

1. Press `Ctrl+Shift+P`
2. Type: **"Python: Select Interpreter"**
3. Choose: `.venv\Scripts\python.exe` (has your project path)

### Result
Bottom-left of VS Code shows: `Python 3.12.x ('.venv': venv)`

---

## Troubleshooting

### "pip: command not found"

```bash
# Use python -m pip instead
python -m pip install numpy pandas faker pytest
```

### "No module named X" when running script

```bash
# Make sure venv is activated (look for (.venv) in prompt)
# If not activated:
.venv\Scripts\Activate.ps1   # PowerShell
source .venv/Scripts/activate  # Git Bash
```

### "venv was deleted / corrupted"

```bash
# Delete and recreate
rm -rf .venv            # Git Bash
# OR
rmdir /s /q .venv       # PowerShell/CMD

# Recreate
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r Python/requirements.txt
```

---

## Copilot Prompts

```
@terminal Create a fresh Python virtual environment and install project requirements
@terminal Activate the virtual environment and verify numpy and pandas are installed
@terminal Show me all installed packages in the current environment
```

---

*Next Guide: [04_Dataset_Generation.md](./04_Dataset_Generation.md)*
