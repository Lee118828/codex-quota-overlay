# Codex 剩余额度浮窗

显示 Codex 的 5 小时与每周剩余额度、百分比和重置时间。

## 使用

右键运行 `Install.ps1`，或在 PowerShell 中执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\Install.ps1
```

安装后，后台启动器随 Windows 登录启动，只在 Codex 运行时显示浮窗。浮窗可拖动、始终置顶；右键可刷新、切换自启动或退出。

运行 `Uninstall.ps1` 可删除启动项并关闭浮窗。

数据只读自 `%USERPROFILE%\.codex\sessions`，不会读取账号令牌。
