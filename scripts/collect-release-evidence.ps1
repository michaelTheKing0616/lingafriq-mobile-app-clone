param(
  [string]$RepoLabel = "mobile-app-main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$evidenceDir = Join-Path $PSScriptRoot "..\docs\evidence"
New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null

$logPath = Join-Path $evidenceDir ("mobile_release_evidence_{0}_{1}.log" -f $RepoLabel, $timestamp)

function Write-LogHeader([string]$text) {
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $text
  $line | Tee-Object -FilePath $logPath -Append
}

function Invoke-Step([string]$name, [string]$command, [string[]]$args) {
  Write-LogHeader ("START: {0}" -f $name)
  & $command @args 2>&1 | Tee-Object -FilePath $logPath -Append
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    Write-LogHeader ("FAIL: {0} (exit={1})" -f $name, $exitCode)
    return $false
  }

  Write-LogHeader ("PASS: {0}" -f $name)
  return $true
}

Write-LogHeader ("Evidence run started for {0}" -f $RepoLabel)

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-LogHeader "FAIL: flutter is not available on PATH."
  exit 1
}

$steps = @(
  @{ Name = "Flutter version"; Command = "flutter"; Args = @("--version") },
  @{ Name = "Flutter analyze"; Command = "flutter"; Args = @("analyze") },
  @{ Name = "Flutter test"; Command = "flutter"; Args = @("test", "--reporter", "expanded") }
)

$allPassed = $true
foreach ($step in $steps) {
  $ok = Invoke-Step -name $step.Name -command $step.Command -args $step.Args
  if (-not $ok) {
    $allPassed = $false
  }
}

Write-LogHeader ("Evidence run finished for {0}" -f $RepoLabel)
Write-LogHeader ("Log file: {0}" -f $logPath)

if (-not $allPassed) {
  exit 1
}
