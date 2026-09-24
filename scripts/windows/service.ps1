param(
    [ValidateSet('start', 'stop')]
    [string]$Action = 'start'
)

$ErrorActionPreference = 'Stop'
$exe = Join-Path $PSScriptRoot 'wb2api.exe'
$configPath = Join-Path $PSScriptRoot 'config.json'
$running = @(Get-Process -Name wb2api -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe })

if ($Action -eq 'stop') {
    $running | Stop-Process
    Write-Host 'WorkBuddy2API stopped.'
    exit 0
}

if ($running.Count -gt 0) {
    Write-Host "WorkBuddy2API is already running (PID $($running[0].Id))."
    exit 0
}

if (-not (Test-Path -LiteralPath $exe)) {
    throw 'wb2api.exe is missing. Download and extract the complete Windows artifact first.'
}

if (-not (Test-Path -LiteralPath $configPath)) {
    $config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'config.example.json') -Raw | ConvertFrom-Json
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    $config.api_key = 'wb_admin_' + [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    $config.listen = '127.0.0.1:7863'
    [System.IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 20), (New-Object System.Text.UTF8Encoding($false)))
}

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
foreach ($name in @('auths', 'data', 'logs')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $PSScriptRoot $name) | Out-Null
}

$port = [int](($config.listen -split ':')[-1])
$base = "http://127.0.0.1:$port"
if (Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue) {
    throw "Port $port is already in use. Change listen in config.json or stop the other service."
}

$process = Start-Process -FilePath $exe -ArgumentList '-config config.json' -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput (Join-Path $PSScriptRoot 'logs/stdout.log') `
    -RedirectStandardError (Join-Path $PSScriptRoot 'logs/stderr.log')

for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 500
    $process.Refresh()
    if ($process.HasExited) { throw 'Startup failed. See logs/stderr.log.' }
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "$base/healthz" -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            Write-Host "WorkBuddy2API started (PID $($process.Id))."
            Write-Host "Panel: $base/panel/"
            Write-Host "API base URL: $base/v1"
            Write-Host "Panel login key: api_key in $configPath"
            exit 0
        }
    } catch {
        # The HTTP listener may not be ready yet.
    }
}

throw 'Health check timed out. See logs/stderr.log; use stop.cmd before retrying.'
