#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the ECC-Antigravity framework into the current user's ~/.gemini/ directory.

.DESCRIPTION
    Copies GEMINI.md, skills, and global_workflows to the correct locations for
    Google Antigravity to pick them up automatically.

.PARAMETER Force
    Overwrite existing files without prompting.

.PARAMETER Backup
    Back up any existing ~/.gemini/GEMINI.md before overwriting.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Force
    .\install.ps1 -Backup
#>

param(
    [switch]$Force,
    [switch]$Backup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── Paths ───────────────────────────────────────────────────────────────────
$RepoRoot      = $PSScriptRoot
$GeminiDir     = Join-Path $env:USERPROFILE ".gemini"
$SkillsDest    = Join-Path $GeminiDir "skills"
$WorkflowsDest = Join-Path $GeminiDir "antigravity\global_workflows"
$GeminiMdDest  = Join-Path $GeminiDir "GEMINI.md"

$GeminiMdSrc   = Join-Path $RepoRoot "GEMINI.md"
$SkillsSrc     = Join-Path $RepoRoot "skills"
$WorkflowsSrc  = Join-Path $RepoRoot "global_workflows"

# ─── Helpers ─────────────────────────────────────────────────────────────────
function Write-Step([string]$msg) { Write-Host "  -> $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }

# ─── Pre-flight checks ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "ECC-Antigravity Installer" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""

if (-not (Test-Path $GeminiDir)) {
    Write-Warn "~\.gemini directory not found at: $GeminiDir"
    Write-Warn "Make sure Google Antigravity is installed and has been opened at least once."
    Write-Host ""
    $confirm = Read-Host "Create the directory anyway and continue? (y/N)"
    if ($confirm -ne 'y') { exit 1 }
    New-Item -ItemType Directory -Path $GeminiDir -Force | Out-Null
}

# ─── Create target directories ───────────────────────────────────────────────
Write-Step "Creating target directories..."
New-Item -ItemType Directory -Path $SkillsDest    -Force | Out-Null
New-Item -ItemType Directory -Path $WorkflowsDest -Force | Out-Null
Write-Ok "Directories ready."

# ─── GEMINI.md ───────────────────────────────────────────────────────────────
Write-Step "Installing GEMINI.md..."

if ((Test-Path $GeminiMdDest) -and -not $Force) {
    if ($Backup) {
        $ts      = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$GeminiMdDest.backup_$ts"
        Copy-Item $GeminiMdDest $backupPath
        Write-Ok "Backed up existing GEMINI.md → $(Split-Path $backupPath -Leaf)"
    } else {
        $confirm = Read-Host "  GEMINI.md already exists. Overwrite? (y/N)"
        if ($confirm -ne 'y') {
            Write-Warn "Skipped GEMINI.md (no changes made)."
        } else {
            Copy-Item $GeminiMdSrc $GeminiMdDest -Force
            Write-Ok "GEMINI.md installed."
        }
    }
} else {
    Copy-Item $GeminiMdSrc $GeminiMdDest -Force
    Write-Ok "GEMINI.md installed."
}

# ─── Skills ──────────────────────────────────────────────────────────────────
Write-Step "Installing skills..."

$skills = Get-ChildItem -Path $SkillsSrc -Directory
$installed = 0
foreach ($skill in $skills) {
    $dest = Join-Path $SkillsDest $skill.Name
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item (Join-Path $skill.FullName "SKILL.md") $dest -Force
    $installed++
}
Write-Ok "Installed $installed skills: $($skills.Name -join ', ')."

# ─── Workflows ───────────────────────────────────────────────────────────────
Write-Step "Installing global workflows..."

$workflows = Get-ChildItem -Path $WorkflowsSrc -Filter "*.md"
foreach ($wf in $workflows) {
    Copy-Item $wf.FullName $WorkflowsDest -Force
}
Write-Ok "Installed $($workflows.Count) workflows: $($workflows.Name -join ', ')."

# ─── Extra Skills (antigravity-awesome-skills) ───────────────────────────────
Write-Step "Installing extra skills via antigravity-awesome-skills..."

if (Get-Command npx -ErrorAction SilentlyContinue) {
    try {
        npx antigravity-awesome-skills --antigravity
        Write-Ok "Extra skills installed successfully."
    } catch {
        Write-Warn "antigravity-awesome-skills failed: $_"
        Write-Warn "You can run it manually later: npx antigravity-awesome-skills --antigravity"
    }
} else {
    Write-Warn "npx not found - skipping extra skills installation."
    Write-Warn "Install Node.js from https://nodejs.org, then run:"
    Write-Warn "  npx antigravity-awesome-skills --antigravity"
}

# ─── Summary ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor DarkGray
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "What was installed:" -ForegroundColor White
Write-Host "  GEMINI.md   -> $GeminiMdDest"
Write-Host "  Skills      -> $SkillsDest"
Write-Host "  Workflows   -> $WorkflowsDest"
Write-Host ""
Write-Host "Restart Antigravity to pick up the new rules and skills." -ForegroundColor Yellow
Write-Host ""
