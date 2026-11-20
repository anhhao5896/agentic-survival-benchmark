param(
    [Parameter(Mandatory=$true)][string]$File
)
$SasExe = "sas"
if (-not (Test-Path $File)) {
    Write-Host "File not found: $File"
    exit 1
}

$originalContent = Get-Content $File -Raw
$odsExclude = "ods exclude ProductLimitEstimates(persist);`r`n"
$tempFile = [System.IO.Path]::ChangeExtension($File, "run.sas")
Set-Content -Path $tempFile -Value ($odsExclude + $originalContent) -NoNewline

$logFile = [System.IO.Path]::ChangeExtension($File, "log")
$lstFile = [System.IO.Path]::ChangeExtension($File, "lst")
if (Test-Path $logFile) { Remove-Item $logFile }
if (Test-Path $lstFile) { Remove-Item $lstFile }
Start-Process -FilePath $SasExe -ArgumentList "-SYSIN `"$tempFile`" -LOG `"$logFile`" -PRINT `"$lstFile`" -NOSPLASH -ICON" -NoNewWindow -Wait
if (-not (Test-Path $logFile)) {
    Write-Host "No log file was generated."
    exit 1
}
Get-Content $logFile
if (Test-Path $lstFile) {
    Write-Host "`n===== SAS OUTPUT (LST) ====="
    Get-Content $lstFile
}