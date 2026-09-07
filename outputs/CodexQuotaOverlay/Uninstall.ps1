$startupPath = Join-Path ([Environment]::GetFolderPath('Startup')) 'Codex Quota Overlay.lnk'
$desktopPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Codex Quota Overlay.lnk'
Remove-Item -LiteralPath $startupPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $desktopPath -Force -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like '*CodexQuotaOverlay.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Write-Host 'Codex quota overlay uninstalled.'
