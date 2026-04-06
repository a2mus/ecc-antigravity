# ECC-Antigravity

A portable setup of the **Everything Claude Code (ECC)** framework adapted for **Google Antigravity** on Windows. 

Installs production-grade coding rules, skills, and workflows into Antigravity with a single PowerShell command.

---

## What's Included

### Language Rules (`GEMINI.md`)
Active for the following file types (path-scoped):

| Language | Paths |
|---|---|
| Python | `*.py`, `*.pyi` |
| TypeScript / JavaScript | `*.ts`, `*.tsx`, `*.js`, `*.jsx` |
| Kotlin / Android | `*.kt`, `*.kts` |
| Universal | All files |

Universal rules cover: immutability, KISS/DRY/YAGNI, git commit format, 80% test coverage mandate, security pre-commit checklist, and agent orchestration patterns.

*(Note: Swift/Apple rules are excluded from this specific version as per request.)*

### Skills (11 total)

| Skill | Domain |
|---|---|
| `search-first` | Research before coding |
| `tdd-workflow` | RED → GREEN → REFACTOR cycle |
| `security-review` | Pre-commit OWASP checklist |
| `continuous-learning` | Pattern capture & knowledge persistence |
| `python-patterns` | Python idioms, dataclasses, QGIS patterns |
| `code-quality` | KISS/DRY/YAGNI, pre-completion checklist |
| `api-design` | REST conventions, pagination, error shapes |
| `frontend-patterns` | React/Next.js, state, performance, a11y |
| `e2e-testing` | Playwright POM, CI/CD, flaky test fixes |
| `deployment-patterns` | GitHub Actions, Docker, health checks, rollbacks |
| `docker-patterns` | Compose, networking, volumes, container security |

### Workflows (5 slash-commands)

| Command | Purpose |
|---|---|
| `/plan` | Plan a feature before writing any code |
| `/tdd` | Drive the TDD RED → GREEN → REFACTOR cycle |
| `/code-review` | Quality, security, and coverage review |
| `/security-scan` | Pre-deploy security audit |
| `/build-fix` | Diagnose and fix build or test failures |

---

## Installation

### Prerequisites
- Windows 10/11
- [Google Antigravity](https://antigravity.google/) installed and opened at least once  
  (this creates the `~\.gemini\` directory)
- PowerShell 5.1+ (built into Windows)

### Steps

```powershell
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/ecc-antigravity.git
cd ecc-antigravity

# 2. Run the installer (may need to allow script execution once)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install.ps1

# 3. Restart Antigravity
```

### Options

```powershell
# Overwrite everything without prompting
.\install.ps1 -Force

# Back up your existing GEMINI.md before overwriting
.\install.ps1 -Backup
```

---

## Uninstallation

```powershell
# Remove skills and workflows (keeps GEMINI.md)
.\uninstall.ps1

# Also remove GEMINI.md
.\uninstall.ps1 -RemoveGeminiMd
```

---

## Updating

```powershell
git pull
.\install.ps1 -Force
```

---

## Installed File Locations

```
~\.gemini\
├── GEMINI.md                          ← language rules (all sessions)
├── skills\
│   ├── search-first\SKILL.md
│   ├── tdd-workflow\SKILL.md
│   ├── security-review\SKILL.md
│   ├── continuous-learning\SKILL.md
│   ├── python-patterns\SKILL.md
│   ├── code-quality\SKILL.md
│   ├── api-design\SKILL.md
│   ├── frontend-patterns\SKILL.md
│   ├── e2e-testing\SKILL.md
│   ├── deployment-patterns\SKILL.md
│   └── docker-patterns\SKILL.md
└── antigravity\
    └── global_workflows\
        ├── plan.md
        ├── code-review.md
        ├── tdd.md
        ├── security-scan.md
        └── build-fix.md
```

---

## Origin

Adapted from the [Everything Claude Code (ECC)](https://github.com/affaan-m/everything-claude-code) framework by affaan-m, ported to Google Antigravity conventions.
