param(
    [string]$TargetDir = ".",
    [ValidateSet("quota-saver", "balanced", "speed-first")]
    [string]$Preset = "quota-saver",
    [switch]$Update,
    [switch]$Uninstall,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$RepoZipUrl = "https://github.com/Anuphap2/antigravity-swarm-router/archive/refs/heads/main.zip"
$RouterSkills = @("swarm-router", "board-updater", "test-runner", "system-architect", "deep-coder")
$PresetMap = @{
    "quota-saver" = "gemini-4-argon-low"
    "balanced"    = "claude-sonnet-5-5-low"
    "speed-first" = "gemini-3.8-flash-low"
}
$TierLowModel = $PresetMap[$Preset]
$PresetExplicit = $PSBoundParameters.ContainsKey("Preset")

if ($Uninstall) {
    if (-not (Test-Path -LiteralPath $TargetDir)) {
        throw "Target directory does not exist: $TargetDir"
    }
    $ResolvedTarget = (Resolve-Path -LiteralPath $TargetDir).Path

    foreach ($Skill in $RouterSkills) {
        $SkillDir = Join-Path $ResolvedTarget ".agent\skills\$Skill"
        if (Test-Path -LiteralPath $SkillDir) {
            Remove-Item -LiteralPath $SkillDir -Recurse -Force
            Write-Host "[OK] Removed $SkillDir"
        }
    }

    $SkillsRoot = Join-Path $ResolvedTarget ".agent\skills"
    $AgentRoot = Join-Path $ResolvedTarget ".agent"
    if ((Test-Path -LiteralPath $SkillsRoot) -and ((Get-ChildItem -LiteralPath $SkillsRoot -Force | Measure-Object).Count -eq 0)) {
        Remove-Item -LiteralPath $SkillsRoot -Force
    }
    if ((Test-Path -LiteralPath $AgentRoot) -and ((Get-ChildItem -LiteralPath $AgentRoot -Force | Measure-Object).Count -eq 0)) {
        Remove-Item -LiteralPath $AgentRoot -Force
    }

    $TargetAgents = Join-Path $ResolvedTarget "AGENTS.md"
    if (Test-Path -LiteralPath $TargetAgents) {
        if ($Force) {
            Remove-Item -LiteralPath $TargetAgents -Force
            Write-Host "[OK] Removed $TargetAgents"
        } else {
            $Answer = Read-Host "[WARN] Remove $TargetAgents? [y/N]"
            if ($Answer -match "^[Yy]$") {
                Remove-Item -LiteralPath $TargetAgents -Force
                Write-Host "[OK] Removed $TargetAgents"
            } else {
                Write-Host "[SKIP] Kept $TargetAgents"
            }
        }
    }

    Write-Host "[DONE] Uninstalled antigravity-swarm-router from $ResolvedTarget"
    exit 0
}

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

    $TargetAgents = Join-Path $ResolvedTarget "AGENTS.md"
    $SourceAgents = Join-Path $SourceDir "AGENTS.md"
    $InstalledAgents = $false

    if ($Update) {
        Write-Host "[INFO] Update mode: preserving existing AGENTS.md"
    } elseif ((Test-Path -LiteralPath $TargetAgents) -and -not $Force) {
        $Answer = Read-Host "[WARN] $TargetAgents already exists. Overwrite? [y/N]"
        if ($Answer -match "^[Yy]$") {
            Copy-Item -LiteralPath $SourceAgents -Destination $TargetAgents -Force
            $InstalledAgents = $true
            Write-Host "[OK] Overwrote $TargetAgents"
        } else {
            Write-Host "[SKIP] Kept existing $TargetAgents"
        }
    } else {
        Copy-Item -LiteralPath $SourceAgents -Destination $TargetAgents -Force
        $InstalledAgents = $true
        Write-Host "[OK] Installed $TargetAgents"
    }

    if ($InstalledAgents -and ($TierLowModel -ne "gemini-4-argon-low")) {
        $Content = [System.IO.File]::ReadAllText($TargetAgents)
        [System.IO.File]::WriteAllText($TargetAgents, $Content.Replace("gemini-4-argon-low", $TierLowModel), [System.Text.UTF8Encoding]::new($false))
        Write-Host "[OK] Applied preset '$Preset' ($TierLowModel) to AGENTS.md"
    }

    $TargetSkillsRoot = Join-Path $ResolvedTarget ".agent\skills"
    New-Item -ItemType Directory -Path $TargetSkillsRoot -Force | Out-Null

    foreach ($Skill in $RouterSkills) {
        $SrcSkill = Join-Path $SourceDir ".agent\skills\$Skill"
        $DstSkill = Join-Path $TargetSkillsRoot $Skill
        if (Test-Path -LiteralPath $SrcSkill) {
            if (-not (Test-Path -LiteralPath $DstSkill)) {
                New-Item -ItemType Directory -Path $DstSkill -Force | Out-Null
            }
            Copy-Item -Path (Join-Path $SrcSkill "*") -Destination $DstSkill -Recurse -Force
            if (($TierLowModel -ne "gemini-4-argon-low") -and ($Skill -in @("swarm-router", "board-updater", "test-runner"))) {
                if (-not $Update -or $PresetExplicit) {
                    $SkillMd = Join-Path $DstSkill "SKILL.md"
                    $SkillText = [System.IO.File]::ReadAllText($SkillMd)
                    [System.IO.File]::WriteAllText($SkillMd, $SkillText.Replace("gemini-4-argon-low", $TierLowModel), [System.Text.UTF8Encoding]::new($false))
                }
            }
            Write-Host "[OK] Installed $DstSkill"
        }
    }

    $ModeLabel = if ($Update) { "update" } else { "install" }
    Write-Host "[DONE] antigravity-swarm-router ($ModeLabel, preset=$Preset) applied to $ResolvedTarget"
}
finally {
    if ($TempDir -and (Test-Path -LiteralPath $TempDir)) {
        Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
