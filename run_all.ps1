<#
.SYNOPSIS
    Starts all SIH Vehicle Intelligence Platform microservices and frontend.
.DESCRIPTION
    Launches:
      - ANPR Service         : http://127.0.0.1:8000
      - Tracking Service     : http://127.0.0.1:8001
      - Integration Service  : http://127.0.0.1:8002
      - Traffic Service      : http://127.0.0.1:8003
      - Central Backend      : http://127.0.0.1:8005
      - Frontend Dashboard   : http://127.0.0.1:5500
#>

$root = $PSScriptRoot
if (-not $root) { $root = Get-Location }

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Starting SIH Vehicle Intelligence Platform" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan

# 1. ANPR Service (port 8000)
$anprDir = Join-Path $root "sih-vehicle-intelligence\services\anpr"
$anprPy = Join-Path $anprDir ".venv\Scripts\python.exe"
Write-Host "[1/6] Starting ANPR Service (port 8000)..." -ForegroundColor Yellow
$anprProc = Start-Process -FilePath $anprPy -ArgumentList "-m uvicorn app:app --host 127.0.0.1 --port 8000" -WorkingDirectory $anprDir -PassThru -WindowStyle Hidden

# 2. Tracking Service (port 8001)
$trackingDir = Join-Path $root "sih-vehicle-intelligence\services\tracking"
$trackingPy = Join-Path $trackingDir ".venv\Scripts\python.exe"
Write-Host "[2/6] Starting Tracking Service (port 8001)..." -ForegroundColor Yellow
$trackingProc = Start-Process -FilePath $trackingPy -ArgumentList "-m uvicorn app:app --host 127.0.0.1 --port 8001" -WorkingDirectory $trackingDir -PassThru -WindowStyle Hidden

# 3. Integration Service (port 8002)
$integrationDir = Join-Path $root "sih-vehicle-intelligence\services\integration"
$integrationPy = Join-Path $integrationDir ".venv\Scripts\python.exe"
Write-Host "[3/6] Starting Integration Service (port 8002)..." -ForegroundColor Yellow
$integrationProc = Start-Process -FilePath $integrationPy -ArgumentList "-m uvicorn app:app --host 127.0.0.1 --port 8002" -WorkingDirectory $integrationDir -PassThru -WindowStyle Hidden

# 4. Traffic Service (port 8003)
$trafficDir = Join-Path $root "sih-vehicle-intelligence\services\traffic"
$trafficPy = Join-Path $root "traffic-test\.venv\Scripts\python.exe"
Write-Host "[4/6] Starting Traffic Service (port 8003)..." -ForegroundColor Yellow
$trafficProc = Start-Process -FilePath $trafficPy -ArgumentList "-m uvicorn app:app --host 127.0.0.1 --port 8003" -WorkingDirectory $trafficDir -PassThru -WindowStyle Hidden

# 5. Central Backend (port 8005)
$backendDir = Join-Path $root "sih-vehicle-intelligence\backend"
$backendPy = Join-Path $backendDir ".venv\Scripts\python.exe"
Write-Host "[5/6] Starting Central Backend (port 8005)..." -ForegroundColor Yellow
$backendProc = Start-Process -FilePath $backendPy -ArgumentList "-m uvicorn app:app --host 127.0.0.1 --port 8005" -WorkingDirectory $backendDir -PassThru -WindowStyle Hidden

# 6. Frontend Server (port 5500)
$frontendDir = Join-Path $root "sih-vehicle-intelligence\frontend"
Write-Host "[6/6] Starting Frontend Web Server (port 5500)..." -ForegroundColor Yellow
$frontendProc = Start-Process -FilePath "py" -ArgumentList "-3.11 -m http.server 5500 --directory `"$frontendDir`"" -WorkingDirectory $frontendDir -PassThru -WindowStyle Hidden

# Save PIDs to a temp file for stop_all.ps1
$pids = @($anprProc.Id, $trackingProc.Id, $integrationProc.Id, $trafficProc.Id, $backendProc.Id, $frontendProc.Id)
$pids | Out-File -FilePath (Join-Path $root ".services_pids.txt") -Force

Write-Host "`nWaiting for services to become healthy..." -ForegroundColor Cyan

function Wait-ForHealth($url, $name, $maxWaitSec = 20) {
    $started = Get-Date
    while (((Get-Date) - $started).TotalSeconds -lt $maxWaitSec) {
        try {
            $resp = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 2 -ErrorAction Stop
            Write-Host "  [OK] $name ($url)" -ForegroundColor Green
            return $true
        } catch {
            Start-Sleep -Milliseconds 800
        }
    }
    Write-Host "  [WAITING] $name took longer than ${maxWaitSec}s to respond (still loading models in background)" -ForegroundColor Yellow
    return $false
}

Wait-ForHealth "http://127.0.0.1:8000/health" "ANPR Service" 45
Wait-ForHealth "http://127.0.0.1:8001/health" "Tracking Service" 30
Wait-ForHealth "http://127.0.0.1:8002/health" "Integration Service" 40
Wait-ForHealth "http://127.0.0.1:8003/health" "Traffic Service" 30
Wait-ForHealth "http://127.0.0.1:8005/health" "Central Backend" 20

Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "  All services running! Access URLs:" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  * Dashboard UI    : http://127.0.0.1:5500" -ForegroundColor White
Write-Host "  * Central API Docs: http://127.0.0.1:8005/docs" -ForegroundColor White
Write-Host "  * Integration Docs: http://127.0.0.1:8002/docs" -ForegroundColor White
Write-Host "  * Tracking Docs   : http://127.0.0.1:8001/docs" -ForegroundColor White
Write-Host "  * ANPR Docs       : http://127.0.0.1:8000/docs" -ForegroundColor White
Write-Host "  * Traffic Docs    : http://127.0.0.1:8003/docs" -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "To stop all services, run: .\stop_all.ps1`n" -ForegroundColor DarkGray

try { Start-Process "http://127.0.0.1:5500" -ErrorAction SilentlyContinue } catch {}
