$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot 'CodexQuotaOverlay.ps1'
$startupPath = Join-Path ([Environment]::GetFolderPath('Startup')) 'Codex Quota Overlay.lnk'
$desktopPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Codex Quota Overlay.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($startupPath)
$shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Description = 'Codex remaining quota overlay launcher'
$shortcut.IconLocation = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe,0"
$shortcut.Save()
$desktopShortcut = $shell.CreateShortcut($desktopPath)
$desktopShortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$desktopShortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$desktopShortcut.WorkingDirectory = $PSScriptRoot
$desktopShortcut.Description = 'Codex remaining quota overlay launcher'
$desktopShortcut.IconLocation = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe,0"
$desktopShortcut.Save()
Start-Process -FilePath $shortcut.TargetPath -ArgumentList $shortcut.Arguments -WindowStyle Hidden
Write-Host 'Codex quota overlay installed and started.'
