#Requires -Version 5.1
<#
.SYNOPSIS
    Removes the ECC-Antigravity framework from ~/.gemini/.

.PARAMETER RemoveGeminiMd
    Also remove ~/.gemini/GEMINI.md (default: leave it in place).

.PARAMETER KeepExtraSkills
    Skip running the antigravity-awesome-skills uninstall step.
#>

param(
    [switch]$RemoveGeminiMd,
    [switch]$KeepExtraSkills
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$GeminiDir     = Join-Path $env:USERPROFILE ".gemini"
$SkillsDest    = Join-Path $GeminiDir "skills"
$WorkflowsDest = Join-Path $GeminiDir "antigravity\global_workflows"
$RepoRoot      = $PSScriptRoot

function Write-Ok([string]$msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Step([string]$msg) { Write-Host "  [*] $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "ECC-Antigravity Uninstaller" -ForegroundColor Magenta
Write-Host "-------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# ─── Remove skills installed by this repo ────────────────────────────────────
Write-Step "Removing skills..."
$skills = Get-ChildItem -Path (Join-Path $RepoRoot "skills") -Directory -ErrorAction SilentlyContinue
foreach ($skill in $skills) {
    $dest = Join-Path $SkillsDest $skill.Name
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
        Write-Ok "Removed skill: $($skill.Name)"
    }
}

# ─── Remove workflows installed by this repo ─────────────────────────────────
Write-Step "Removing global workflows..."
$workflows = Get-ChildItem -Path (Join-Path $RepoRoot "global_workflows") -Filter "*.md" -ErrorAction SilentlyContinue
foreach ($wf in $workflows) {
    $dest = Join-Path $WorkflowsDest $wf.Name
    if (Test-Path $dest) {
        Remove-Item $dest -Force
        Write-Ok "Removed workflow: $($wf.Name)"
    }
}

# ─── Remove extra skills (antigravity-awesome-skills) ────────────────────────
if (-not $KeepExtraSkills) {
    Write-Step "Removing extra skills via antigravity-awesome-skills..."
    if (Get-Command npx -ErrorAction SilentlyContinue) {
        try {
            npx antigravity-awesome-skills --antigravity --uninstall
            Write-Ok "Extra skills removed successfully."
        } catch {
            Write-Warn "antigravity-awesome-skills uninstall failed: $_"
            Write-Warn "You can run it manually: npx antigravity-awesome-skills --antigravity --uninstall"
        }
    } else {
        Write-Warn "npx not found - skipping extra skills removal."
        Write-Warn "If extra skills were installed, remove them manually from: $SkillsDest"
    }
} else {
    Write-Warn "Skipping extra skills removal (-KeepExtraSkills specified)."
}

# ─── Optionally remove GEMINI.md ─────────────────────────────────────────────
if ($RemoveGeminiMd) {
    $geminiMd = Join-Path $GeminiDir "GEMINI.md"
    if (Test-Path $geminiMd) {
        Remove-Item $geminiMd -Force
        Write-Ok "Removed GEMINI.md"
    }
} else {
    Write-Warn "GEMINI.md left in place (use -RemoveGeminiMd to also remove it)."
}

Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor DarkGray
Write-Host "Uninstall complete." -ForegroundColor Green
Write-Host ""
