param(
    [Parameter(Mandatory=$true)][string]$File
)
$StataExe = "C:\Program Files\StataNow19\StataMP-64.exe"

if (-not (Test-Path $File)) {
    Write-Host "File not found: $File"
    exit 1
}
if (-not (Test-Path $StataExe)) {
    Write-Host "Stata executable not found: $StataExe"
    exit 1
}

Get-Process -Name "StataMP-64" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$logFile = [System.IO.Path]::ChangeExtension($File, "log")
if (Test-Path $logFile) { Remove-Item $logFile }

Start-Process -FilePath $StataExe -ArgumentList "/q /e do `"$File`"" -WindowStyle Minimized -Wait

if (-not (Test-Path $logFile)) {
    Write-Host "No log file was generated."
    exit 1
}
Get-Content $logFile