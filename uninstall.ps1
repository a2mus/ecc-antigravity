#Requires -Version 5.1
<#
.SYNOPSIS
    Removes the ECC-Antigravity framework from ~/.gemini/.

.PARAMETER RemoveGeminiMd
    Also remove ~/.gemini/GEMINI.md (default: leave it in place).
#>

param(
    [switch]$RemoveGeminiMd
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$GeminiDir     = Join-Path $env:USERPROFILE ".gemini"
$SkillsDest    = Join-Path $GeminiDir "skills"
$WorkflowsDest = Join-Path $GeminiDir "antigravity\global_workflows"
$RepoRoot      = $PSScriptRoot

Write-Host ""
Write-Host "ECC-Antigravity Uninstaller" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""

# Remove skills installed by this repo
$skills = Get-ChildItem -Path (Join-Path $RepoRoot "skills") -Directory -ErrorAction SilentlyContinue
foreach ($skill in $skills) {
    $dest = Join-Path $SkillsDest $skill.Name
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
        Write-Host "  ✔ Removed skill: $($skill.Name)" -ForegroundColor Green
    }
}

# Remove workflows installed by this repo
$workflows = Get-ChildItem -Path (Join-Path $RepoRoot "global_workflows") -Filter "*.md" -ErrorAction SilentlyContinue
foreach ($wf in $workflows) {
    $dest = Join-Path $WorkflowsDest $wf.Name
    if (Test-Path $dest) {
        Remove-Item $dest -Force
        Write-Host "  ✔ Removed workflow: $($wf.Name)" -ForegroundColor Green
    }
}

# Optionally remove GEMINI.md
if ($RemoveGeminiMd) {
    $geminiMd = Join-Path $GeminiDir "GEMINI.md"
    if (Test-Path $geminiMd) {
        Remove-Item $geminiMd -Force
        Write-Host "  ✔ Removed GEMINI.md" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠ GEMINI.md left in place (use -RemoveGeminiMd to also remove it)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Uninstall complete." -ForegroundColor Green
Write-Host ""
