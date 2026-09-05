<#
.SYNOPSIS
    Stops all SIH Vehicle Intelligence Platform services and clears ports.
#>

$ports = @(8000, 8001, 8002, 8003, 8005, 5500)

Write-Host "Stopping all SIH services on ports: $($ports -join ', ')..." -ForegroundColor Cyan

# Check PID file first
$pidFile = Join-Path $PSScriptRoot ".services_pids.txt"
if (Test-Path $pidFile) {
    Get-Content $pidFile | ForEach-Object {
        $pId = [int]$_
        try {
            Stop-Process -Id $pId -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

# Also ensure any lingering listeners on those ports are stopped
foreach ($port in $ports) {
    try {
        $conns = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        foreach ($conn in $conns) {
            if ($conn.OwningProcess -gt 0) {
                Write-Host "Killing process on port $port (PID: $($conn.OwningProcess))..." -ForegroundColor Yellow
                Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}

Write-Host "All services stopped successfully." -ForegroundColor Green
