# 07 — VS Code and GitHub Copilot

## Editor Configuration and AI-Assisted Development

---

> **WHAT:** This guide explains how we set up VS Code (our code editor) and GitHub Copilot (our AI coding assistant) for the project — the extensions, the settings, and how the AI helps us write SQL, Python, and DAX faster.
>
> **WHY:** A well-configured editor removes friction. The right extensions catch errors early, format code automatically, and let Copilot suggest correct code — which means fewer bugs and faster delivery.
>
> **WHEN:** Read this once at the start of the project (during environment setup), and come back to it whenever you install a new machine or an extension stops working.

---

## VS Code — Our Primary Tool

VS Code is where you:
- Write Python and SQL code
- Run terminal commands
- Manage Git (stage, commit, push)
- Preview Markdown documentation
- Use Copilot for assistance


---

## Recommended Settings

Create/edit `.vscode/settings.json` in project root:

```json
{
    "python.defaultInterpreterPath": ".venv/Scripts/python.exe",
    "python.testing.pytestEnabled": true,
    "python.testing.pytestArgs": ["tests/"],
    "files.exclude": {
        "**/__pycache__": true,
        "**/.pytest_cache": true,
        "**/.venv": true
    },
    "editor.formatOnSave": true,
    "terminal.integrated.defaultProfile.windows": "PowerShell"
}
```

---

## Terminal Selection

| Terminal | Best For | Activate venv |
|---------|---------|---------------|
| **PowerShell** ✅ | Python, pip, pytest, general work | `.venv\Scripts\Activate.ps1` |
| Git Bash | Git commands only | `source .venv/Scripts/activate` |
| CMD | Avoid | `.venv\Scripts\activate.bat` |

**To change default:** `Ctrl+Shift+P` → "Terminal: Select Default Profile" → PowerShell

---

## Keyboard Shortcuts You'll Use Daily

| Shortcut | Action |
|----------|--------|
| `` Ctrl+` `` | Toggle terminal |
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+Shift+X` | Extensions panel |
| `Ctrl+P` | Quick open file |
| `Ctrl+Shift+F` | Search across all files |
| `Ctrl+B` | Toggle sidebar |
| `Ctrl+/` | Comment/uncomment line |

---

## GitHub Copilot — Ready-Made Prompts

### For Git Operations

```
@terminal Show git status and current branch
@terminal Pull latest from main branch
@terminal Create a new branch called feat/my-feature
@terminal Stage all files and commit with message "feat: description"
@terminal Push current branch to GitHub
```

### For Python/Data

```
@terminal Create a Python virtual environment and install requirements
@terminal Run the dataset generator with development profile
@terminal Run all pytest data quality tests with verbose output
@terminal Count rows in Dataset/orders.csv
```

### For SQL Server

```
@terminal Check if SQL Server is running
@terminal Start SQL Server service
```

### For Understanding Code

```
@workspace Explain what Python/generate_dataset.py does
@workspace Show me all the intentional data defects in the generator
@workspace What do the pytest tests validate?
```

---

## Copilot Best Practices

| Do | Don't |
|----|-------|
| Be specific in prompts | Give vague instructions |
| Use @terminal for commands | Expect it to run commands automatically |
| Use @workspace for code questions | Ask about external topics |
| Verify suggestions before accepting | Blindly accept everything |
| Provide context ("in PowerShell...") | Assume it knows your terminal type |

---

## Project-Specific Workflow with Copilot + Kiro

```
KIRO (Browser - app.kiro.dev)     COPILOT (VS Code)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━     ━━━━━━━━━━━━━━━━━
• Generates SQL scripts           • Executes terminal commands
• Creates PRs on GitHub           • Auto-completes code
• Provides architecture           • Explains existing code
• Mentors through phases          • Quick fixes & suggestions
• Pushes code to GitHub           • Local file operations
```

---

*Next Guide: [08_Troubleshooting.md](./08_Troubleshooting.md)*
