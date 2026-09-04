# Codex Quota Overlay

一个 Windows PowerShell/WPF 桌面浮窗，显示 Codex 的两条剩余额度：

- 外环：5 小时额度（300 分钟）
- 内环：每周额度（10080 分钟）

程序只读取 `%USERPROFILE%\.codex\sessions` 中的会话日志，不读取或保存账号令牌。

## 运行

在 Windows PowerShell 5.1 中执行：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\outputs\CodexQuotaOverlay\Install.ps1
```

右键浮窗可刷新、调整大小/摩擦力、启用随 Windows 启动或退出。卸载：

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
