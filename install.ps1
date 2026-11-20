param(
    [string]$TargetDir = ".",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$RepoZipUrl = "https://github.com/Anuphap2/antigravity-swarm-router/archive/refs/heads/main.zip"

if (-not (Test-Path -LiteralPath $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}
$ResolvedTarget = (Resolve-Path -LiteralPath $TargetDir).Path

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { "" }
$TempDir = $null
$SourceDir = $null

try {
    if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir "AGENTS.md")) -and (Test-Path (Join-Path $ScriptDir ".agent\skills"))) {
        $SourceDir = $ScriptDir
    } else {
        $TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("agy-swarm-router-" + [Guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        $ZipPath = Join-Path $TempDir "repo.zip"

        Write-Host "[INFO] Fetching antigravity-swarm-router..."
        Invoke-WebRequest -Uri $RepoZipUrl -OutFile $ZipPath -UseBasicParsing
        Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

        $Extracted = Get-ChildItem -Path $TempDir -Directory | Select-Object -First 1
        if (-not $Extracted -or -not (Test-Path (Join-Path $Extracted.FullName "AGENTS.md"))) {
            throw "Failed to locate AGENTS.md in downloaded archive."
        }
        $SourceDir = $Extracted.FullName
    }

    # Copy AGENTS.md with overwrite prompt if it already exists
    $TargetAgents = Join-Path $ResolvedTarget "AGENTS.md"
    $SourceAgents = Join-Path $SourceDir "AGENTS.md"

    if ((Test-Path -LiteralPath $TargetAgents) -and -not $Force) {
        $Answer = Read-Host "[WARN] $TargetAgents already exists. Overwrite? [y/N]"
        if ($Answer -match "^[Yy]$") {
            Copy-Item -LiteralPath $SourceAgents -Destination $TargetAgents -Force
            Write-Host "[OK] Overwrote $TargetAgents"
        } else {
            Write-Host "[SKIP] Kept existing $TargetAgents"
        }
    } else {
        Copy-Item -LiteralPath $SourceAgents -Destination $TargetAgents -Force
        Write-Host "[OK] Installed $TargetAgents"
    }

    # Copy only router skills into .agent\skills\ without touching unrelated files
    $TargetSkillsRoot = Join-Path $ResolvedTarget ".agent\skills"
    New-Item -ItemType Directory -Path $TargetSkillsRoot -Force | Out-Null

    foreach ($Skill in @("board-updater", "system-architect", "deep-coder")) {
        $SrcSkill = Join-Path $SourceDir ".agent\skills\$Skill"
        $DstSkill = Join-Path $TargetSkillsRoot $Skill
        if (Test-Path -LiteralPath $SrcSkill) {
            if (-not (Test-Path -LiteralPath $DstSkill)) {
                New-Item -ItemType Directory -Path $DstSkill -Force | Out-Null
            }
            Copy-Item -Path (Join-Path $SrcSkill "*") -Destination $DstSkill -Recurse -Force
            Write-Host "[OK] Installed $DstSkill"
        }
    }

    Write-Host "[DONE] antigravity-swarm-router installed into $ResolvedTarget"
}
finally {
    if ($TempDir -and (Test-Path -LiteralPath $TempDir)) {
        Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
