# Codex Quota Overlay

一个 Windows PowerShell/WPF 桌面浮窗，显示 Codex 的每周剩余额度和百分比。

当前公开版本是回滚后的单周额度浮窗；程序会保留拖动、惯性、缩放和摩擦力控制。

程序只读取 `%USERPROFILE%\.codex\sessions` 中的会话日志，不读取或保存账号令牌。

## 运行

在 Windows PowerShell 5.1 中执行：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\outputs\CodexQuotaOverlay\Install.ps1
```

安装脚本会同时创建 Windows 自启动项和桌面启动快捷方式。右键浮窗可刷新、调整大小/摩擦力、启用随 Windows 启动或退出。卸载：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\outputs\CodexQuotaOverlay\Uninstall.ps1
```

只读取额度数据：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\outputs\CodexQuotaOverlay\CodexQuotaOverlay.ps1 -DataOnly
```

## 测试

```powershell
powershell.exe -NoProfile -Sta -ExecutionPolicy Bypass -File .\tests\CodexQuotaOverlay.Tests.ps1
```

GitHub 用于公开托管源码；WPF 桌面浮窗需要在本地 Windows 上运行，不能作为 GitHub Pages 网页直接运行。
