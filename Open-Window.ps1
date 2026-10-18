# Starts the bundled Node server, opens JianPi in its own window, then stops the server when that window closes.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Show-Error([string]$msg) {
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.MessageBox]::Show($msg, "Jinply", "OK", "Error") | Out-Null
}

function Test-Health {
  try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8787/api/health" -UseBasicParsing -TimeoutSec 2
    return $r.StatusCode -eq 200
  } catch {
    return $false
  }
}

$node = Join-Path $root "runtime\node.exe"
$serverJs = Join-Path $root "app\server.js"
if (-not (Test-Path -LiteralPath $node) -or -not (Test-Path -LiteralPath $serverJs)) {
  Show-Error "Jinply is incomplete. Unzip the whole folder first, then double-click Jinply."
  exit 1
}

$edge = $null
foreach ($candidate in @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "$env:LocalAppData\Microsoft\Edge\Application\msedge.exe"
)) {
  if (Test-Path -LiteralPath $candidate) { $edge = $candidate; break }
}
if (-not $edge) {
  Show-Error "Microsoft Edge was not found. Windows 10 and 11 include Edge. Install it, then open Jinply again."
  exit 1
}

$started = $null
if (-not (Test-Health)) {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $node
  $psi.Arguments = "`"$serverJs`""
  $psi.WorkingDirectory = Join-Path $root "app"
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.EnvironmentVariables["PORT"] = "8787"
  $started = [System.Diagnostics.Process]::Start($psi)

  $ready = $false
  for ($i = 0; $i -lt 40; $i++) {
    if ($started.HasExited) { break }
    if (Test-Health) { $ready = $true; break }
    Start-Sleep -Milliseconds 250
  }
  if (-not $ready) {
    if ($started -and -not $started.HasExited) { try { $started.Kill() } catch {} }
    Show-Error "Jinply did not start. If a Jinply window is already open, close it and try again."
    exit 1
  }
}

$profile = Join-Path $root "data\window"
New-Item -ItemType Directory -Force -Path $profile | Out-Null
$window = Start-Process -FilePath $edge -PassThru -ArgumentList @(
  "--app=http://127.0.0.1:8787",
  "--user-data-dir=$profile",
  "--no-first-run",
  "--no-default-browser-check",
  "--disable-sync",
  "--disable-extensions",
  "--disable-translate",
  "--window-size=1280,800"
)

Start-Sleep -Seconds 2
if ($window.HasExited) {
  if ($started -and -not $started.HasExited) { try { $started.Kill() } catch {} }
  exit 0
}

$window.WaitForExit()
if ($started -and -not $started.HasExited) {
  try { $started.Kill() } catch {}
}
