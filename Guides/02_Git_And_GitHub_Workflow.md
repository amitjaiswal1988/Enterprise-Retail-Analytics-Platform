# 02 — Git and GitHub Workflow

## Complete Guide to Version Control for This Project

---

## What Is Git?

Git tracks **every change** you make to files. Think of it as "unlimited undo" + "parallel universes" for your code.

## What Is GitHub?

GitHub is where your Git repository lives **online** — like Google Drive for code, but with superpowers (PRs, issues, CI/CD).

---

## Step 1: Clone the Repository

### What
Download the entire project from GitHub to your local machine.

### Why
You need a local copy to work on. `git clone` creates this copy AND connects it to GitHub.

### When
Once — first time setting up the project.

### How

```powershell
cd C:\Users\YourName\Documents
git clone https://github.com/amitjaiswal1988/Enterprise-Retail-Analytics-Platform.git
cd Enterprise-Retail-Analytics-Platform
```

### Breakdown

| Command | What It Does |
|---------|-------------|
| `cd Documents` | Go to Documents folder |
| `git clone <url>` | Download repo + full history from GitHub |
| `cd Enterprise-...` | Enter the downloaded project folder |

### Verify

```powershell
dir
```

You should see: `Dataset/`, `Python/`, `SQL/`, `Documentation/`, `README.md`, etc.

---

## Step 2: Understand Branches

### What
Branches are "parallel versions" of your code. Think of them as drafts.

### Why
- `main` branch = production/stable code (never break this)
- Feature branches = where you develop new things safely
- If you mess up a branch, main is still safe

### Visual Explanation

```
main:        ●───●───●───●───●───●  (stable, always working)
                  │           ▲
                  │           │ merge
                  ▼           │
feature:          ●───●───●───●  (your work happens here)
```

### Commands

| Command | What It Does | When |
|---------|-------------|------|
| `git branch` | Show current branch | Check where you are |
| `git checkout main` | Switch to main | Before pulling latest |
| `git checkout -b feat/new-thing` | Create + switch to new branch | Starting new work |
| `git checkout main` | Switch back to main | When done with feature |

---

## Step 3: Pull Latest Changes

### What
Download new commits from GitHub that others (or Kiro) pushed.

### Why
Stay up-to-date. If you don't pull, you'll have conflicts later.

### When
Every time before starting work (start of day).

### How

```powershell
git checkout main
git pull origin main
```

| Command | Meaning |
|---------|---------|
| `git checkout main` | Switch to main branch |
| `git pull origin main` | Download latest changes from GitHub's main branch |
| `origin` | Name of the remote (GitHub) |
| `main` | Branch name to pull |

---

## Step 4: Create a Feature Branch

### What
A new branch where you'll make changes without affecting `main`.

### Why
Enterprise practice: never commit directly to main. Always use branches + PRs.

### When
Every time you start working on something new.

### How

```powershell
git checkout -b feat/my-new-feature
```

**Naming conventions:**
| Prefix | Use For | Example |
|--------|---------|---------|
| `feat/` | New feature | `feat/dataset-generator` |
| `fix/` | Bug fix | `fix/null-email-handling` |
| `docs/` | Documentation | `docs/setup-guide` |
| `refactor/` | Code cleanup | `refactor/sql-naming` |

---

## Step 5: Stage and Commit Changes

### What
Save a "snapshot" of your changes with a description.

### Why
Git only tracks what you explicitly tell it to. Staging → Committing is that process.

### When
After you've made meaningful progress (not every keystroke, but logical chunks).

### How

```powershell
# See what changed
git status

# Stage specific files
git add Python/generate_dataset.py
git add Documentation/new_doc.md

# Or stage everything
git add -A

# Commit with message
git commit -m "feat: add dataset generator with 12 CSV outputs"
```

### Breakdown

| Command | What It Does |
|---------|-------------|
| `git status` | Shows which files changed (red = unstaged, green = staged) |
| `git add <file>` | Marks a file for the next commit |
| `git add -A` | Marks ALL changed files |
| `git commit -m "msg"` | Creates a snapshot with a description |

### Commit Message Format (Professional)

```
type: short description (50 chars max)

Examples:
feat: add synthetic dataset generator
fix: resolve null email handling in staging
docs: update setup guide with troubleshooting
refactor: optimize order_details generation
test: add referential integrity tests
```

---

## Step 6: Push to GitHub

### What
Upload your branch (and its commits) to GitHub.

### Why
- Backup your work online
- Others can see and review your code
- Required before creating a Pull Request

### When
After committing, when ready to share/backup.

### How

```powershell
git push origin feat/my-new-feature
```

| Part | Meaning |
|------|---------|
| `git push` | Upload commits |
| `origin` | To GitHub (remote name) |
| `feat/my-new-feature` | Branch name to push |

---

## Step 7: Create a Pull Request (PR)

### What
A PR says "I have changes on my branch — please review and merge into main."

### Why
- Code review (someone checks your work)
- Discussion about changes
- Clean merge into main
- History of what was added and why

### When
After pushing your branch to GitHub.

### How

1. Go to GitHub repo: https://github.com/amitjaiswal1988/Enterprise-Retail-Analytics-Platform
2. You'll see a yellow banner: "feat/my-feature had recent pushes — **Compare & pull request**"
3. Click it
4. Fill in:
   - **Title:** Short description (e.g., "feat: Add dataset generator")
   - **Description:** What was changed and why
5. Click **"Create pull request"**

---

## Step 8: Merge the PR

### What
Combine your branch's changes into `main`.

### Why
Your feature is complete and ready for production.

### When
After review is done (or immediately for personal projects).

### How

1. On the PR page, click green **"Merge pull request"**
2. Click **"Confirm merge"**
3. Optionally click **"Delete branch"** (keeps repo clean)

---

## Step 9: Sync Local After Merge

### What
After merging on GitHub, update your local `main` to match.

### Why
Your local `main` is behind. Need to pull the merged changes.

### When
After every PR merge on GitHub.

### How

```powershell
git checkout main
git pull origin main
```

---

## Common Situations & Fixes

### Situation: "Please move or remove files before you merge"

```powershell
# Remove untracked files causing conflict
git clean -fd .
# Then pull again
git pull origin main
```

### Situation: "Your branch is behind main"

```powershell
git checkout main
git pull origin main
git checkout feat/my-feature
git merge main
```

### Situation: "I want to start fresh (match GitHub exactly)"

```powershell
git fetch origin
git reset --hard origin/main
```

⚠️ **Warning:** This discards ALL local changes. Use only when desperate.

### Situation: "I accidentally committed to main"

```powershell
# Move the commit to a new branch
git branch feat/oops
git reset --hard HEAD~1
git checkout feat/oops
# Now push the branch and create a PR
git push origin feat/oops
```

---

## Git Commands Quick Reference

| Task | Command |
|------|---------|
| Check current branch | `git branch` |
| Switch branch | `git checkout branch-name` |
| Create + switch | `git checkout -b new-branch` |
| See changes | `git status` |
| Stage all | `git add -A` |
| Commit | `git commit -m "message"` |
| Push | `git push origin branch-name` |
| Pull latest | `git pull origin main` |
| View log | `git log --oneline` |
| Discard changes | `git checkout -- filename` |
| Remove untracked | `git clean -fd .` |
| Hard reset | `git reset --hard origin/main` |

---

## Copilot Prompts for Git

```
@terminal Show me git status and current branch
@terminal Create a new branch called feat/sql-landing-layer
@terminal Stage all changes and commit with message "feat: add landing layer tables"
@terminal Push current branch to origin
```

---

*Next Guide: [03_Python_Virtual_Environment.md](./03_Python_Virtual_Environment.md)*
