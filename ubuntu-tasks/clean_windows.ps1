# WSL VHDX Compaction Script
# Run this in PowerShell as Administrator

Write-Host "=== WSL Storage Compaction ===" -ForegroundColor Green

Write-Host "Shutting down WSL..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep -Seconds 5

$vhdxPath = "$env:LOCALAPPDATA\Packages\CanonicalGroupLimited.Ubuntu_79rhkp1fndgsc\LocalState\ext4.vhdx"

if (-not (Test-Path $vhdxPath)) {
    Write-Host "VHDX not found at: $vhdxPath" -ForegroundColor Red
    Write-Host "Searching for all WSL VHDX files..." -ForegroundColor Yellow
    Get-ChildItem "$env:LOCALAPPDATA\Packages\*\LocalState\ext4.vhdx" -Recurse | ForEach-Object {
        Write-Host "Found: $($_.FullName)" -ForegroundColor Cyan
    }
    exit 1
}

$sizeBefore = (Get-Item $vhdxPath).Length / 1GB
Write-Host "VHDX size before: $([math]::Round($sizeBefore, 2)) GB" -ForegroundColor Yellow

if (Get-Command Optimize-VHD -ErrorAction SilentlyContinue) {
    Write-Host "Using Optimize-VHD (Hyper-V method)..." -ForegroundColor Yellow
    Optimize-VHD -Path $vhdxPath -Mode Full
} else {
    Write-Host "Using diskpart method..." -ForegroundColor Yellow
    $diskpartScript = @"
select vdisk file="$vhdxPath"
compact vdisk
exit
"@
    $diskpartScript | diskpart
}

$sizeAfter = (Get-Item $vhdxPath).Length / 1GB
$saved = $sizeBefore - $sizeAfter

Write-Host ""
Write-Host "=== Compaction Complete ===" -ForegroundColor Green
Write-Host "VHDX size after:  $([math]::Round($sizeAfter, 2)) GB" -ForegroundColor Green
Write-Host "Space reclaimed:  $([math]::Round($saved, 2)) GB" -ForegroundColor Green
Write-Host ""
Write-Host "You can now restart WSL with: wsl" -ForegroundColor Cyan
