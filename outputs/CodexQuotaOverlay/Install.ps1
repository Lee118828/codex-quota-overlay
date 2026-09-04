$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot 'CodexQuotaOverlay.ps1'
$startupPath = Join-Path ([Environment]::GetFolderPath('Startup')) 'Codex Quota Overlay.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($startupPath)
$shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Description = 'Codex remaining quota overlay launcher'
$shortcut.Save()
Start-Process -FilePath $shortcut.TargetPath -ArgumentList $shortcut.Arguments -WindowStyle Hidden
Write-Host 'Codex quota overlay installed and started.'
