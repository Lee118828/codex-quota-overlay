$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '..\outputs\CodexQuotaOverlay\CodexQuotaOverlay.ps1'
$content = Get-Content -Raw -LiteralPath $scriptPath

function Assert-Contains([string]$needle, [string]$name) {
    if ($content.IndexOf($needle, [System.StringComparison]::Ordinal) -lt 0) {
        throw "FAIL: $name"
    }
}

function Assert-NotContains([string]$needle, [string]$name) {
    if ($content.IndexOf($needle, [System.StringComparison]::Ordinal) -ge 0) {
        throw "FAIL: $name"
    }
}

Assert-Contains 'x:Name="PrimaryRing"' 'primary circular gauge path is defined'
Assert-Contains 'x:Name="SecondaryRing"' 'secondary circular gauge path is defined'
Assert-Contains 'Text="5H"' 'five-hour gauge is labeled'
Assert-Contains 'Text="WEEK"' 'weekly gauge is labeled'
Assert-Contains 'function Set-RingArc' 'ring geometry is rendered from remaining percent'
Assert-Contains '[Windows.Point]::new' 'ring point construction uses WPF point coordinates'
Assert-Contains 'WeeklyRemaining' 'primary-only quota records are exposed as weekly remaining'
Assert-Contains 'PrimaryRemaining' 'five-hour quota is exposed as primary remaining'
Assert-Contains 'SecondaryRemaining' 'weekly quota is exposed as secondary remaining'
Assert-Contains '$timer.Interval = [TimeSpan]::FromSeconds(4)' 'scheduled refresh remains low frequency'
Assert-Contains '$refreshItem.Add_Click({ Update-View })' 'manual refresh performs an immediate view update'
Assert-Contains 'x:Name="CardScale"' 'card has a transform for breathing and squash effects'
Assert-Contains 'class OverlayPhysicsController' 'physics runs in compiled code'
Assert-Contains 'public event EventHandler ClickRequested;' 'physics controller exposes a click event'
Assert-Contains 'OverlayControlMath.IsDragThresholdExceeded' 'dragging begins at the shared threshold'
Assert-Contains 'public void SetScalePercent(int value)' 'physics controller accepts scale changes'
Assert-Contains 'public void SetFriction(int value)' 'physics controller accepts friction changes'
Assert-Contains '"ScalePercent":{2},"Friction":{3}' 'settings persist scale and friction'
Assert-Contains 'CompositionTarget.Rendering +=' 'physics follows WPF render frames'
Assert-Contains 'SynchronizePhysicalLeftButton();' 'render frame synchronizes physical input before physics'
Assert-Contains 'WindowFromPoint(point) == overlayHandle' 'fallback accepts only the overlay top-level HWND'
Assert-Contains 'Cursor.Position' 'dragging uses absolute cursor coordinates'
Assert-Contains '[System.Xaml.XamlReader].Assembly.Location' 'compiled controller references the WPF XAML assembly'
Assert-Contains 'Title="Codex Quota Overlay"' 'window is identifiable during live UI verification'
Assert-Contains 'OpenAI\.Codex_' 'new Codex desktop package process is detected'
Assert-Contains '$script:quotaFileCache' 'unchanged session logs are not reparsed every refresh'
Assert-Contains '<Path x:Name="Trail1"' 'first velocity trail layer is an arc path'
Assert-Contains '<Path x:Name="Trail2"' 'second velocity trail layer is an arc path'
Assert-Contains '<Path x:Name="Trail3"' 'third velocity trail layer is an arc path'
foreach ($removedStopControlArtifact in @(
        '$stopControlSettingsPath',
        '[xml]$stopControlXaml',
        'StopMotionButton',
        'StopControlFace',
        'Set-StopControlWindow',
        'Restore-StopControlWindowPosition',
        'Save-StopControlWindowPosition',
        'Register-StopControlWindowDragHandlers',
        'SuppressPhysicalPressForExternalControl',
        'externalControlPressActive',
        'StopMotion()')) {
    Assert-NotContains $removedStopControlArtifact "removed stop-control artifact '$removedStopControlArtifact'"
}
Assert-Contains 'Set-ArcTrailGeometry' 'render frames rebuild the current arc geometry'
Assert-Contains 'Math.Atan2' 'trail orientation follows reverse velocity'
Assert-Contains 'trails[i].Opacity' 'trail opacity eases per replacement layer'
Assert-Contains 'Width="292" Height="292"' 'expanded transparent canvas contains the trail'
Assert-Contains 'Math.Exp(-coefficient * deltaSeconds)' 'inertia decay uses the selected coefficient'
Assert-Contains '* 0.82' 'edge collision has stronger restitution'
Assert-Contains '<RadialGradientBrush' 'card uses an obsidian glass gradient'
Assert-Contains 'x:Name="RingGlow"' 'quota ring has a separate glow layer'
Assert-Contains 'x:Name="VisualGroup"' 'quota and trails share a user-scale transform'
Assert-Contains 'x:Name="UserScale"' 'visual group exposes the persisted scale transform'
Assert-Contains 'x:Name="ControlPanel"' 'left-click control panel exists'
Assert-Contains 'x:Name="ScaleDown"' 'control panel has a shrink button'
Assert-Contains 'x:Name="ScaleUp"' 'control panel has an enlarge button'
Assert-Contains 'x:Name="ScaleDown100"' 'control panel has a minus 100 percent shortcut'
Assert-Contains 'x:Name="ScaleUp100"' 'control panel has a plus 100 percent shortcut'
Assert-Contains '$script:currentScalePercent - 100' 'minus 100 shortcut uses the shared scale state'
Assert-Contains '$script:currentScalePercent + 100' 'plus 100 shortcut uses the shared scale state'
Assert-Contains 'x:Name="FrictionSlider"' 'control panel has a friction slider'
Assert-Contains '$physicsController.add_ClickRequested' 'short clicks toggle the panel'
Assert-Contains '$physicsController.SetScalePercent' 'size controls update compiled physics'
Assert-Contains '$physicsController.SetFriction' 'slider updates compiled physics'
Assert-Contains '$controlPanel.Add_Closed' 'normal popup closure updates logical panel state'
Assert-Contains '$scaleDown.IsEnabled = $true' 'shrink button has no configured UI limit'
Assert-Contains '$scaleUp.IsEnabled = $true' 'enlarge button has no configured UI limit'
if ($content.IndexOf('controlPanelAutoClosedAt', [System.StringComparison]::Ordinal) -ge 0) {
    throw 'FAIL: popup suppression no longer uses a broad elapsed-time token'
}
if ($content.IndexOf('controlPanelClosingByToggle', [System.StringComparison]::Ordinal) -ge 0) {
    throw 'FAIL: popup closure no longer relies on a setter-scoped flag'
}
$mouseDownStart = $content.IndexOf('private void OnMouseDown', [System.StringComparison]::Ordinal)
$mouseMoveStart = $content.IndexOf('private void OnMouseMove', $mouseDownStart, [System.StringComparison]::Ordinal)
if ($mouseDownStart -lt 0 -or $mouseMoveStart -lt 0) {
    throw 'FAIL: mouse-down handler remains inspectable'
}
$mouseDownBody = $content.Substring($mouseDownStart, $mouseMoveStart - $mouseDownStart)
if ($mouseDownBody.IndexOf('moving = false;', [System.StringComparison]::Ordinal) -lt 0) {
    throw 'FAIL: mouse down immediately stops inertia and rebound'
}
$mouseUpStart = $content.IndexOf('private void OnMouseUp', $mouseMoveStart, [System.StringComparison]::Ordinal)
$mouseMoveBody = $content.Substring($mouseMoveStart, $mouseUpStart - $mouseMoveStart)
if ($mouseMoveBody -match 'if\s*\(e\.LeftButton\s*!=\s*MouseButtonState\.Pressed\)\s*\{\s*EndDrag\(\);') {
    throw 'FAIL: mouse move cannot consume a pending click before mouse up'
}
if ($mouseMoveBody -notmatch 'Vector\s+thresholdDelta\s*=\s*PixelDeltaToDip\(\s*cursor\.X\s*-\s*pressCursor\.X,\s*cursor\.Y\s*-\s*pressCursor\.Y\);\s*dragThresholdExceeded\s*=\s*OverlayControlMath\.IsDragThresholdExceeded\(\s*thresholdDelta\.X,\s*thresholdDelta\.Y\)') {
    throw 'FAIL: drag threshold uses total displacement converted to DIP'
}
if ($content.IndexOf('function Save-WindowPosition', [System.StringComparison]::Ordinal) -ge 0) {
    throw 'FAIL: obsolete position-only settings writer is removed'
}
$settingsLoadStart = $content.IndexOf(
    'if (Test-Path -LiteralPath $settingsPath)',
    [System.StringComparison]::Ordinal)
$controllerCreateStart = $content.IndexOf(
    '$script:physicsController = [OverlayPhysicsController]::new(',
    $settingsLoadStart,
    [System.StringComparison]::Ordinal)
$settingsLoadBody = $content.Substring(
    $settingsLoadStart,
    $controllerCreateStart - $settingsLoadStart)
$startupWidthIndex = $settingsLoadBody.IndexOf(
    '$window.Width = 292.0 * $startupScaleFactor',
    [System.StringComparison]::Ordinal)
$restoreLeftIndex = $settingsLoadBody.IndexOf(
    '$window.Left = [double]$settings.Left',
    [System.StringComparison]::Ordinal)
if ($startupWidthIndex -lt 0 -or $startupWidthIndex -gt $restoreLeftIndex) {
    throw 'FAIL: startup applies persisted scale before restoring coordinates'
}
if ($settingsLoadBody.IndexOf(
        'Clamp-WindowPosition -scalePercent $initialScalePercent',
        [System.StringComparison]::Ordinal) -lt 0) {
    throw 'FAIL: startup coordinate clamp uses the persisted scale'
}

$quotaParseErrors = $null
$quotaScriptAst = [Management.Automation.Language.Parser]::ParseFile(
    $scriptPath,
    [ref]$null,
    [ref]$quotaParseErrors)
if ($quotaParseErrors.Count -ne 0) {
    throw 'FAIL: quota script parses successfully for quota selection tests'
}
$latestQuotaFunctionAst = $quotaScriptAst.Find(
    {
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq 'Get-LatestQuota'
    },
    $true)
if ($null -eq $latestQuotaFunctionAst) {
    throw 'FAIL: Get-LatestQuota remains directly executable for quota selection tests'
}
. ([scriptblock]::Create($latestQuotaFunctionAst.Extent.Text))

$quotaFixturePath = Join-Path $PSScriptRoot 'fixtures\quota-primary-over-auxiliary.jsonl'
$quotaTestHome = Join-Path ([IO.Path]::GetTempPath()) (
    'CodexQuotaOverlay.QuotaTests.' + [guid]::NewGuid().ToString('N'))
$originalUserProfile = $env:USERPROFILE
$originalQuotaFileCache = $script:quotaFileCache
try {
    $quotaSessions = Join-Path $quotaTestHome '.codex\sessions\2026\08\01'
    New-Item -ItemType Directory -Path $quotaSessions -Force | Out-Null
    Copy-Item -LiteralPath $quotaFixturePath -Destination (
        Join-Path $quotaSessions 'rollout-fixture.jsonl')
    $env:USERPROFILE = $quotaTestHome
    $script:quotaFileCache = @{}

    $selectedQuota = Get-LatestQuota

    if ($selectedQuota.WeeklyRemaining -ne 66) {
        throw "FAIL: primary codex record wins over newer auxiliary quota bucket (expected 66, got $($selectedQuota.WeeklyRemaining))"
    }
    if (-not $selectedQuota.Source.EndsWith(
            'rollout-fixture.jsonl',
            [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'FAIL: primary codex quota source is retained'
    }
}
finally {
    $env:USERPROFILE = $originalUserProfile
    $script:quotaFileCache = $originalQuotaFileCache
    Remove-Item -LiteralPath $quotaTestHome -Recurse -Force -ErrorAction SilentlyContinue
}

$dualQuotaFixturePath = Join-Path $PSScriptRoot 'fixtures\quota-dual-window.jsonl'
$dualQuotaTestHome = Join-Path ([IO.Path]::GetTempPath()) (
    'CodexQuotaOverlay.DualQuotaTests.' + [guid]::NewGuid().ToString('N'))
$originalDualUserProfile = $env:USERPROFILE
$originalDualQuotaFileCache = $script:quotaFileCache
try {
    $dualQuotaSessions = Join-Path $dualQuotaTestHome '.codex\sessions\2026\09\04'
    New-Item -ItemType Directory -Path $dualQuotaSessions -Force | Out-Null
    Copy-Item -LiteralPath $dualQuotaFixturePath -Destination (
        Join-Path $dualQuotaSessions 'rollout-dual-fixture.jsonl')
    $env:USERPROFILE = $dualQuotaTestHome
    $script:quotaFileCache = @{}

    $dualQuota = Get-LatestQuota

    if ($dualQuota.PrimaryRemaining -ne 88) {
        throw "FAIL: five-hour window maps from primary 300-minute bucket (expected 88, got $($dualQuota.PrimaryRemaining))"
    }
    if ($dualQuota.SecondaryRemaining -ne 66) {
        throw "FAIL: weekly window maps from secondary 10080-minute bucket (expected 66, got $($dualQuota.SecondaryRemaining))"
    }
    if ($dualQuota.WeeklyRemaining -ne 66 -or $dualQuota.FiveHourRemaining -ne 88) {
        throw 'FAIL: quota aliases preserve weekly and five-hour values'
    }
}
finally {
    $env:USERPROFILE = $originalDualUserProfile
    $script:quotaFileCache = $originalDualQuotaFileCache
    Remove-Item -LiteralPath $dualQuotaTestHome -Recurse -Force -ErrorAction SilentlyContinue
}

$controlMathPath = Join-Path $PSScriptRoot '..\outputs\CodexQuotaOverlay\OverlayControlMath.cs'
$controlMathSource = Get-Content -Raw -LiteralPath $controlMathPath
if ($controlMathSource.IndexOf(
        'return value <= 0 ? 1 : value;',
        [System.StringComparison]::Ordinal) -lt 0) {
    throw 'FAIL: scale normalization has no configured upper limit'
}
$controllerMatch = [regex]::Match(
    $content,
    '(?s)\$physicsControllerSource\s*=\s*@''\r?\n(?<source>.*?)\r?\n''@')
if (-not $controllerMatch.Success) { throw 'FAIL: embedded controller source can be compiled by tests' }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class OverlayTestNativeWindow
{
    [StructLayout(LayoutKind.Sequential)]
    private struct Input
    {
        public uint Type;
        public MouseInput Data;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MouseInput
    {
        public int Dx;
        public int Dy;
        public uint MouseData;
        public uint Flags;
        public uint Time;
        public UIntPtr ExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct Rect
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct Point
    {
        public int X;
        public int Y;

        public Point(int x, int y)
        {
            X = x;
            Y = y;
        }
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetWindowRect(IntPtr handle, out Rect rect);

    [DllImport("user32.dll")]
    public static extern IntPtr WindowFromPoint(Point point);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(
        uint flags,
        uint dx,
        uint dy,
        uint data,
        UIntPtr extraInfo);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint SendInput(
        uint inputCount,
        Input[] inputs,
        int inputSize);

    public static void SendLeftClick()
    {
        Input[] inputs = new[]
        {
            new Input { Type = 0, Data = new MouseInput { Flags = 0x0002 } },
            new Input { Type = 0, Data = new MouseInput { Flags = 0x0004 } }
        };
        uint sent = SendInput(
            (uint)inputs.Length,
            inputs,
            Marshal.SizeOf(typeof(Input)));
        if (sent != inputs.Length)
        {
            throw new InvalidOperationException(
                "SendInput left click failed: " + Marshal.GetLastWin32Error());
        }
    }

    public static void SendLeftMouseDown()
    {
        SendMouseInput(0x0002);
    }

    public static void SendLeftMouseUp()
    {
        SendMouseInput(0x0004);
    }

    private static void SendMouseInput(uint flags)
    {
        Input[] inputs = new[]
        {
            new Input { Type = 0, Data = new MouseInput { Flags = flags } }
        };
        uint sent = SendInput(
            (uint)inputs.Length,
            inputs,
            Marshal.SizeOf(typeof(Input)));
        if (sent != inputs.Length)
        {
            throw new InvalidOperationException(
                "SendInput mouse input failed: " + Marshal.GetLastWin32Error());
        }
    }

    public static Rect ReadRect(IntPtr handle)
    {
        Rect rect;
        if (!GetWindowRect(handle, out rect))
        {
            throw new InvalidOperationException(
                "GetWindowRect failed: " + Marshal.GetLastWin32Error());
        }
        return rect;
    }
}
'@
$physicsReferences = @(
    [Windows.Window].Assembly.Location
    [Windows.Media.CompositionTarget].Assembly.Location
    [Windows.Point].Assembly.Location
    [System.Xaml.XamlReader].Assembly.Location
    [System.Windows.Forms.Cursor].Assembly.Location
    [System.Drawing.Point].Assembly.Location
) | Select-Object -Unique
Add-Type -Language CSharp -ReferencedAssemblies $physicsReferences -TypeDefinition (
    $controllerMatch.Groups['source'].Value + [Environment]::NewLine + $controlMathSource)

function Assert-Equal($actual, $expected, [string]$name) {
    if ($actual -ne $expected) { throw "FAIL: $name (expected $expected, got $actual)" }
}

function Assert-Near([double]$actual, [double]$expected, [double]$epsilon, [string]$name) {
    if ([Math]::Abs($actual - $expected) -gt $epsilon) {
        throw "FAIL: $name (expected $expected, got $actual)"
    }
}

$windowXamlMatch = [regex]::Match(
    $content,
    '(?s)\[xml\]\$xaml\s*=\s*@''\r?\n(?<xaml>.*?)\r?\n''@')
if (-not $windowXamlMatch.Success) { throw 'FAIL: production window XAML remains loadable by tests' }
$windowXamlReader = [System.Xml.XmlNodeReader]::new(
    [xml]$windowXamlMatch.Groups['xaml'].Value)
$loadedWindow = [Windows.Markup.XamlReader]::Load($windowXamlReader)

$controlPanelXamlMatch = [regex]::Match(
    $content,
    '(?s)\[xml\]\$controlPanelXaml\s*=\s*@''\r?\n(?<xaml>.*?)\r?\n''@')
if (-not $controlPanelXamlMatch.Success) { throw 'FAIL: production control-panel XAML remains loadable by tests' }
$controlPanelXamlReader = [System.Xml.XmlNodeReader]::new(
    [xml]$controlPanelXamlMatch.Groups['xaml'].Value)
$loadedControlPanel = [Windows.Markup.XamlReader]::Load($controlPanelXamlReader)

foreach ($name in @(
        'VisualGroup',
        'UserScale',
        'Trail1',
        'Trail2',
        'Trail3',
        'CardScale')) {
    Assert-Equal ($null -ne $loadedWindow.FindName($name)) $true "window XAML exposes $name"
}
Assert-Equal $loadedControlPanel.Name 'ControlPanel' 'control-panel XAML exposes ControlPanel'
foreach ($name in @(
        'ScaleDown',
        'ScaleUp',
        'ScaleDown100',
        'ScaleUp100',
        'ScaleValue',
        'FrictionSlider',
        'FrictionValue')) {
    Assert-Equal ($null -ne $loadedControlPanel.FindName($name)) $true "control-panel XAML exposes $name"
}
$loadedScaleDown100 = $loadedControlPanel.FindName('ScaleDown100')
$loadedScaleUp100 = $loadedControlPanel.FindName('ScaleUp100')
Assert-Equal ([string]$loadedScaleDown100.Content) ([char]0x2212 + '100%') 'minus 100 shortcut has visible text'
Assert-Equal ([string]$loadedScaleUp100.Content) '+100%' 'plus 100 shortcut has visible text'
$loadedFrictionSlider = $loadedControlPanel.FindName('FrictionSlider')
Assert-Near $loadedFrictionSlider.Minimum -100 0.0001 'friction slider minimum'
Assert-Near $loadedFrictionSlider.Maximum 100 0.0001 'friction slider maximum'

Assert-Equal ([OverlayControlMath]::IsDragThresholdExceeded(3, 4)) $false 'five pixels remains a click'
Assert-Equal ([OverlayControlMath]::IsDragThresholdExceeded(6, 0)) $true 'six pixels begins a drag'
Assert-Equal ([OverlayControlMath]::ClampScalePercent(-10)) 1 'negative scale normalizes to one percent'
Assert-Equal ([OverlayControlMath]::ClampScalePercent(0)) 1 'zero scale normalizes to one percent'
Assert-Equal ([OverlayControlMath]::ClampScalePercent(1)) 1 'one percent remains unchanged'
Assert-Equal ([OverlayControlMath]::ClampScalePercent(150)) 150 'scale above the former upper bound remains unchanged'
Assert-Equal ([OverlayControlMath]::ClampScalePercent(1000)) 1000 'scale has no configured upper limit'
Assert-Equal ([OverlayControlMath]::ClampFriction(-101)) -100 'friction lower bound'
Assert-Equal ([OverlayControlMath]::ClampFriction(-100)) -100 'negative friction is retained'
Assert-Equal ([OverlayControlMath]::ClampFriction(101)) 100 'friction upper bound'
Assert-Near ([OverlayControlMath]::FrictionCoefficientFromValue(-1)) -0.02 0.0001 'mild anti-friction mapping'
Assert-Near ([OverlayControlMath]::FrictionCoefficientFromValue(-100)) -2.00 0.0001 'maximum anti-friction mapping'
Assert-Near ([OverlayControlMath]::FrictionCoefficientFromValue(0)) 0.35 0.0001 'minimum friction mapping'
Assert-Near ([OverlayControlMath]::FrictionCoefficientFromValue(40)) 1.65 0.0001 'default friction mapping'
Assert-Near ([OverlayControlMath]::FrictionCoefficientFromValue(100)) 4.50 0.0001 'maximum friction mapping'
function New-ControllerFixture([int]$scalePercent = 100, [int]$friction = 40) {
    $window = [Windows.Window]::new()
    $window.Width = 292
    $window.Height = 292
    $area = [System.Windows.SystemParameters]::WorkArea
    $window.Left = $area.Left + 200
    $window.Top = $area.Top + 200
    $cardScale = [Windows.Media.ScaleTransform]::new()
    $userScale = [Windows.Media.ScaleTransform]::new()
    $settingsPath = Join-Path ([IO.Path]::GetTempPath()) (
        'CodexQuotaOverlay.Tests.' + [guid]::NewGuid().ToString('N') + '.json')
    $trails = @(
        [Windows.Shapes.Ellipse]::new()
        [Windows.Shapes.Ellipse]::new()
        [Windows.Shapes.Ellipse]::new()
    )
    $controller = [OverlayPhysicsController]::new(
        $window,
        $cardScale,
        $userScale,
        64.0,
        $settingsPath,
        $scalePercent,
        $friction,
        $trails[0],
        $trails[1],
        $trails[2])
    return [pscustomobject]@{
        Window = $window
        Controller = $controller
        UserScale = $userScale
        SettingsPath = $settingsPath
    }
}

$scaledFixture = New-ControllerFixture -scalePercent 170
$expectedLeft = [System.Windows.SystemParameters]::WorkArea.Left + 200
$expectedTop = [System.Windows.SystemParameters]::WorkArea.Top + 200
Assert-Near $scaledFixture.Window.Left $expectedLeft 0.0001 'startup scale preserves restored left coordinate'
Assert-Near $scaledFixture.Window.Top $expectedTop 0.0001 'startup scale preserves restored top coordinate'
Assert-Near $scaledFixture.Window.Width 496.4 0.0001 'startup scale accepts values above the former maximum'
$scaledFixture.Controller.Dispose()
$scaledFixture.Window.Close()

function Set-ControllerField($controller, [string]$name, $value) {
    $field = $controller.GetType().GetField(
        $name,
        [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic)
    if ($null -eq $field) { throw "FAIL: controller field '$name' remains inspectable" }
    $field.SetValue($controller, $value)
}

function Invoke-ControllerMouseUp($fixture) {
    $method = $fixture.Controller.GetType().GetMethod(
        'OnMouseUp',
        [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic)
    if ($null -eq $method) { throw 'FAIL: controller mouse-up behavior remains directly executable' }
    $eventArgs = [Windows.Input.MouseButtonEventArgs]::new(
        [Windows.Input.InputManager]::Current.PrimaryMouseDevice,
        [Environment]::TickCount,
        [Windows.Input.MouseButton]::Left)
    $eventArgs.RoutedEvent = [Windows.Input.Mouse]::MouseUpEvent
    [void]$method.Invoke($fixture.Controller, @($fixture.Window, $eventArgs))
}

function Get-ControllerField($controller, [string]$name) {
    $field = $controller.GetType().GetField(
        $name,
        [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic)
    if ($null -eq $field) { throw "FAIL: controller field '$name' remains inspectable" }
    return $field.GetValue($controller)
}

function Invoke-ControllerMouseMove($fixture) {
    $method = $fixture.Controller.GetType().GetMethod(
        'OnMouseMove',
        [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic)
    if ($null -eq $method) { throw 'FAIL: controller mouse-move behavior remains directly executable' }
    $eventArgs = [Windows.Input.MouseEventArgs]::new(
        [Windows.Input.InputManager]::Current.PrimaryMouseDevice,
        [Environment]::TickCount)
    $eventArgs.RoutedEvent = [Windows.Input.Mouse]::MouseMoveEvent
    [void]$method.Invoke($fixture.Controller, @($fixture.Window, $eventArgs))
}

function Invoke-ControllerMouseDown($fixture) {
    $method = $fixture.Controller.GetType().GetMethod(
        'OnMouseDown',
        [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic)
    if ($null -eq $method) { throw 'FAIL: controller mouse-down behavior remains directly executable' }
    $eventArgs = [Windows.Input.MouseButtonEventArgs]::new(
        [Windows.Input.InputManager]::Current.PrimaryMouseDevice,
        [Environment]::TickCount,
        [Windows.Input.MouseButton]::Left)
    $eventArgs.RoutedEvent = [Windows.Input.Mouse]::MouseDownEvent
    [void]$method.Invoke($fixture.Controller, @($fixture.Window, $eventArgs))
}

function Invoke-ControllerRendering($fixture, [double]$deltaSeconds = 0.02) {
    $clock = Get-ControllerField $fixture.Controller 'clock'
    Set-ControllerField $fixture.Controller 'lastFrameTime' (
        $clock.Elapsed.TotalSeconds - $deltaSeconds)
    $method = $fixture.Controller.GetType().GetMethod(
        'OnRendering',
        [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic)
    if ($null -eq $method) { throw 'FAIL: controller render synchronization remains directly executable' }
    [void]$method.Invoke($fixture.Controller, @($null, [EventArgs]::Empty))
}

$negativeFrictionFixture = New-ControllerFixture
try {
    $area = [System.Windows.SystemParameters]::WorkArea
    $negativeFrictionFixture.Window.Left = $area.Left + 600
    $negativeFrictionFixture.Window.Top = $area.Top + 400
    Set-ControllerField $negativeFrictionFixture.Controller 'physicalLeftButtonPressedProvider' ([Func[bool]]{
        $false
    })
    Set-ControllerField $negativeFrictionFixture.Controller 'physicalLeftButtonWasPressed' $false
    Set-ControllerField $negativeFrictionFixture.Controller 'dragging' $false
    $negativeFrictionFixture.Controller.SetFriction(-100)
    Set-ControllerField $negativeFrictionFixture.Controller 'velocityX' 3000.0
    Set-ControllerField $negativeFrictionFixture.Controller 'velocityY' 100.0
    $initialNegativeFrictionSpeed =
        [Math]::Abs([double](Get-ControllerField $negativeFrictionFixture.Controller 'velocityX')) +
        [Math]::Abs([double](Get-ControllerField $negativeFrictionFixture.Controller 'velocityY'))

    for ($frame = 0; $frame -lt 5; $frame++) {
        Invoke-ControllerRendering $negativeFrictionFixture
        $velocityX = [double](Get-ControllerField $negativeFrictionFixture.Controller 'velocityX')
        $velocityY = [double](Get-ControllerField $negativeFrictionFixture.Controller 'velocityY')
        if ([Math]::Abs($velocityX) -gt 3200.0 -or [Math]::Abs($velocityY) -gt 3200.0) {
            throw 'FAIL: negative friction keeps every velocity component within the controller limit'
        }
    }

    $finalNegativeFrictionSpeed =
        [Math]::Abs([double](Get-ControllerField $negativeFrictionFixture.Controller 'velocityX')) +
        [Math]::Abs([double](Get-ControllerField $negativeFrictionFixture.Controller 'velocityY'))
    if ($finalNegativeFrictionSpeed -le $initialNegativeFrictionSpeed) {
        throw 'FAIL: negative friction grows released velocity over successive frames'
    }
}
finally {
    $negativeFrictionFixture.Controller.Dispose()
    $negativeFrictionFixture.Window.Close()
    if ([IO.File]::Exists($negativeFrictionFixture.SettingsPath)) {
        [IO.File]::Delete($negativeFrictionFixture.SettingsPath)
    }
}

$moveFixture = New-ControllerFixture
$cursorState = [pscustomobject]@{ Point = [Drawing.Point]::new(106, 100) }
$conversionCounter = [pscustomobject]@{ Value = 0 }
$cursorProvider = [Func[Drawing.Point]]{ $cursorState.Point }
$leftPressedProvider = [Func[Windows.Input.MouseEventArgs, bool]]{ param($eventArgs) $true }
$pixelToDipProvider = [Func[double, double, Windows.Vector]]{
    param($x, $y)
    $conversionCounter.Value++
    return [Windows.Vector]::new($x / 2.0, $y / 2.0)
}
try {
    $defaultPixelToDipProvider = [Func[double, double, Windows.Vector]](
        Get-ControllerField $moveFixture.Controller 'pixelDeltaToDipProvider')
    $defaultFallbackDelta = $defaultPixelToDipProvider.Invoke(6.0, 0.0)
    Assert-Near $defaultFallbackDelta.X 6.0 0.0001 'production converter preserves pixels when no presentation source exists'

    Set-ControllerField $moveFixture.Controller 'cursorPositionProvider' $cursorProvider
    Set-ControllerField $moveFixture.Controller 'leftButtonPressedProvider' $leftPressedProvider
    Set-ControllerField $moveFixture.Controller 'pixelDeltaToDipProvider' $pixelToDipProvider
    Set-ControllerField $moveFixture.Controller 'dragging' $true
    Set-ControllerField $moveFixture.Controller 'dragThresholdExceeded' $false
    Set-ControllerField $moveFixture.Controller 'pressCursor' ([Drawing.Point]::new(100, 100))
    Set-ControllerField $moveFixture.Controller 'lastCursor' ([Drawing.Point]::new(100, 100))
    $initialMoveLeft = $moveFixture.Window.Left

    Invoke-ControllerMouseMove $moveFixture
    Assert-Equal (Get-ControllerField $moveFixture.Controller 'dragThresholdExceeded') $false 'six device pixels remain below a six-DIP threshold at 200 percent'
    Assert-Near $moveFixture.Window.Left $initialMoveLeft 0.0001 'sub-threshold DIP movement does not move the window'

    $cursorState.Point = [Drawing.Point]::new(112, 100)
    Invoke-ControllerMouseMove $moveFixture
    Assert-Equal (Get-ControllerField $moveFixture.Controller 'dragThresholdExceeded') $true 'twelve device pixels reach a six-DIP threshold at 200 percent'
    Assert-Near $moveFixture.Window.Left ($initialMoveLeft + 6.0) 0.0001 'threshold-crossing movement uses the converted DIP delta'
    Assert-Equal $conversionCounter.Value 3 'OnMouseMove routes threshold and movement deltas through PixelDeltaToDip'
}
finally {
    $moveFixture.Controller.Dispose()
    $moveFixture.Window.Close()
    if ([IO.File]::Exists($moveFixture.SettingsPath)) {
        [IO.File]::Delete($moveFixture.SettingsPath)
    }
}

$fallbackFixture = New-ControllerFixture
$fallbackPhysicalState = [pscustomobject]@{ Pressed = $true }
$fallbackCursorState = [pscustomobject]@{ Point = [Drawing.Point]::new(640, 360) }
$fallbackPhysicalProvider = [Func[bool]]{ $fallbackPhysicalState.Pressed }
$fallbackHitProvider = [Func[Drawing.Point, bool]]{ param($point) $true }
$fallbackCursorProvider = [Func[Drawing.Point]]{ $fallbackCursorState.Point }
$fallbackConversionCounter = [pscustomobject]@{ Value = 0 }
$fallbackPixelToDipProvider = [Func[double, double, Windows.Vector]]{
    param($x, $y)
    $fallbackConversionCounter.Value++
    return [Windows.Vector]::new($x / 2.0, $y / 2.0)
}
try {
    Set-ControllerField $fallbackFixture.Controller 'physicalLeftButtonPressedProvider' $fallbackPhysicalProvider
    Set-ControllerField $fallbackFixture.Controller 'overlayTopLevelHitProvider' $fallbackHitProvider
    Set-ControllerField $fallbackFixture.Controller 'cursorPositionProvider' $fallbackCursorProvider
    Set-ControllerField $fallbackFixture.Controller 'pixelDeltaToDipProvider' $fallbackPixelToDipProvider
    Set-ControllerField $fallbackFixture.Controller 'physicalLeftButtonWasPressed' $false
    Set-ControllerField $fallbackFixture.Controller 'dragging' $false
    Set-ControllerField $fallbackFixture.Controller 'moving' $true
    Set-ControllerField $fallbackFixture.Controller 'velocityX' 900.0
    Set-ControllerField $fallbackFixture.Controller 'velocityY' 0.0
    $fallbackInitialLeft = $fallbackFixture.Window.Left

    Invoke-ControllerRendering $fallbackFixture
    Assert-Equal (Get-ControllerField $fallbackFixture.Controller 'dragging') $true 'render fallback begins a grab for a new physical press over this top-level HWND'
    Assert-Equal (Get-ControllerField $fallbackFixture.Controller 'moving') $false 'render fallback stops inertia before physics advances'
    Assert-Near (Get-ControllerField $fallbackFixture.Controller 'velocityX') 0.0 0.0001 'render fallback clears horizontal velocity'
    Assert-Near $fallbackFixture.Window.Left $fallbackInitialLeft 0.0001 'render fallback catches the moving window before UpdatePhysics'

    $fallbackInitialTop = $fallbackFixture.Window.Top
    $fallbackCursorState.Point = [Drawing.Point]::new(740, 408)
    Invoke-ControllerRendering $fallbackFixture
    Assert-Near $fallbackFixture.Window.Left ($fallbackInitialLeft + 50.0) 0.0001 'held fallback drag advances horizontally by the DIP cursor delta'
    Assert-Near $fallbackFixture.Window.Top ($fallbackInitialTop + 24.0) 0.0001 'held fallback drag advances vertically by the DIP cursor delta'
    Assert-Equal (Get-ControllerField $fallbackFixture.Controller 'dragThresholdExceeded') $true 'held fallback movement updates the shared drag threshold'
    if (
        [Math]::Abs([double](Get-ControllerField $fallbackFixture.Controller 'velocityX')) +
        [Math]::Abs([double](Get-ControllerField $fallbackFixture.Controller 'velocityY')) -le 10.0
    ) {
        throw 'FAIL: held fallback movement samples throw velocity'
    }
    Assert-Equal $fallbackConversionCounter.Value 2 'held fallback movement uses DIP conversion for threshold and cursor delta'
}
finally {
    $fallbackFixture.Controller.Dispose()
    $fallbackFixture.Window.Close()
}

$movementDedupeFixture = New-ControllerFixture
$movementDedupePhysicalState = [pscustomobject]@{ Pressed = $true }
$movementDedupeCursorState = [pscustomobject]@{ Point = [Drawing.Point]::new(800, 500) }
$movementDedupeClickCounter = [pscustomobject]@{ Value = 0 }
$movementDedupeWriteCounter = [pscustomobject]@{ Value = 0 }
$movementDedupeClickHandler = [EventHandler]{
    param($sender, $eventArgs)
    $movementDedupeClickCounter.Value++
}
$movementDedupeFixture.Controller.add_ClickRequested($movementDedupeClickHandler)
try {
    Set-ControllerField $movementDedupeFixture.Controller 'physicalLeftButtonPressedProvider' ([Func[bool]]{
        $movementDedupePhysicalState.Pressed
    })
    Set-ControllerField $movementDedupeFixture.Controller 'overlayTopLevelHitProvider' ([Func[Drawing.Point, bool]]{
        param($point)
        $true
    })
    Set-ControllerField $movementDedupeFixture.Controller 'cursorPositionProvider' ([Func[Drawing.Point]]{
        $movementDedupeCursorState.Point
    })
    Set-ControllerField $movementDedupeFixture.Controller 'leftButtonPressedProvider' ([Func[Windows.Input.MouseEventArgs, bool]]{
        param($eventArgs)
        $true
    })
    Set-ControllerField $movementDedupeFixture.Controller 'settingsWriteProvider' ([Action[string, string]]{
        param($path, $json)
        $movementDedupeWriteCounter.Value++
    })
    Set-ControllerField $movementDedupeFixture.Controller 'physicalLeftButtonWasPressed' $false

    Invoke-ControllerMouseDown $movementDedupeFixture
    $movementDedupeInitialLeft = $movementDedupeFixture.Window.Left
    $movementDedupeInitialTop = $movementDedupeFixture.Window.Top
    $movementDedupeCursorState.Point = [Drawing.Point]::new(812, 506)
    Invoke-ControllerMouseMove $movementDedupeFixture
    $leftAfterWpfMove = $movementDedupeFixture.Window.Left
    $topAfterWpfMove = $movementDedupeFixture.Window.Top
    $velocityXAfterWpfMove = [double](Get-ControllerField $movementDedupeFixture.Controller 'velocityX')
    $velocityYAfterWpfMove = [double](Get-ControllerField $movementDedupeFixture.Controller 'velocityY')
    Assert-Near $leftAfterWpfMove ($movementDedupeInitialLeft + 12.0) 0.0001 'routed WPF movement applies the cursor delta once'
    Assert-Near $topAfterWpfMove ($movementDedupeInitialTop + 6.0) 0.0001 'routed WPF movement applies the vertical cursor delta once'

    Invoke-ControllerRendering $movementDedupeFixture
    Assert-Near $movementDedupeFixture.Window.Left $leftAfterWpfMove 0.0001 'render polling does not reapply a cursor position already seen by WPF'
    Assert-Near $movementDedupeFixture.Window.Top $topAfterWpfMove 0.0001 'render polling deduplicates the vertical cursor position'
    Assert-Near ([double](Get-ControllerField $movementDedupeFixture.Controller 'velocityX')) $velocityXAfterWpfMove 0.0001 'duplicate render position does not resample horizontal velocity'
    Assert-Near ([double](Get-ControllerField $movementDedupeFixture.Controller 'velocityY')) $velocityYAfterWpfMove 0.0001 'duplicate render position does not resample vertical velocity'

    $movementDedupePhysicalState.Pressed = $false
    Invoke-ControllerRendering $movementDedupeFixture
    Assert-Equal (Get-ControllerField $movementDedupeFixture.Controller 'dragging') $false 'fallback release completes the held drag'
    Assert-Equal (Get-ControllerField $movementDedupeFixture.Controller 'moving') $true 'fallback release preserves the sampled throw'
    $velocityXAfterFallbackRelease = [double](Get-ControllerField $movementDedupeFixture.Controller 'velocityX')
    $velocityYAfterFallbackRelease = [double](Get-ControllerField $movementDedupeFixture.Controller 'velocityY')
    if ([Math]::Abs($velocityXAfterFallbackRelease) + [Math]::Abs($velocityYAfterFallbackRelease) -le 10.0) {
        throw 'FAIL: fallback release retains fling velocity'
    }

    Invoke-ControllerMouseUp $movementDedupeFixture
    Assert-Near ([double](Get-ControllerField $movementDedupeFixture.Controller 'velocityX')) $velocityXAfterFallbackRelease 0.0001 'duplicate WPF release does not alter horizontal throw'
    Assert-Near ([double](Get-ControllerField $movementDedupeFixture.Controller 'velocityY')) $velocityYAfterFallbackRelease 0.0001 'duplicate WPF release does not alter vertical throw'
    Assert-Equal $movementDedupeClickCounter.Value 0 'drag release never emits a click through either input path'
    Assert-Equal $movementDedupeWriteCounter.Value 0 'fling release is completed once without an early settings write'
}
finally {
    $movementDedupeFixture.Controller.remove_ClickRequested($movementDedupeClickHandler)
    $movementDedupeFixture.Controller.Dispose()
    $movementDedupeFixture.Window.Close()
}

$foreignHitFixture = New-ControllerFixture
$foreignPhysicalProvider = [Func[bool]]{ $true }
$foreignHitState = [pscustomobject]@{ IsOverlay = $false }
$foreignCursorState = [pscustomobject]@{ Point = [Drawing.Point]::new(640, 360) }
$foreignHitProvider = [Func[Drawing.Point, bool]]{
    param($point)
    $foreignHitState.IsOverlay
}
try {
    Set-ControllerField $foreignHitFixture.Controller 'physicalLeftButtonPressedProvider' $foreignPhysicalProvider
    Set-ControllerField $foreignHitFixture.Controller 'overlayTopLevelHitProvider' $foreignHitProvider
    Set-ControllerField $foreignHitFixture.Controller 'cursorPositionProvider' ([Func[Drawing.Point]]{
        $foreignCursorState.Point
    })
    Set-ControllerField $foreignHitFixture.Controller 'physicalLeftButtonWasPressed' $false
    Set-ControllerField $foreignHitFixture.Controller 'dragging' $false
    Set-ControllerField $foreignHitFixture.Controller 'moving' $true
    Set-ControllerField $foreignHitFixture.Controller 'velocityX' 900.0
    Set-ControllerField $foreignHitFixture.Controller 'velocityY' 0.0
    $foreignInitialLeft = $foreignHitFixture.Window.Left

    Invoke-ControllerRendering $foreignHitFixture
    Assert-Equal (Get-ControllerField $foreignHitFixture.Controller 'dragging') $false 'physical press over popup or foreign HWND does not grab overlay'
    if ($foreignHitFixture.Window.Left -le $foreignInitialLeft) {
        throw 'FAIL: ignored foreign-HWND press allows existing inertia to advance'
    }

    $foreignHitState.IsOverlay = $true
    $foreignCursorState.Point = [Drawing.Point]::new(700, 400)
    Invoke-ControllerRendering $foreignHitFixture
    Assert-Equal (Get-ControllerField $foreignHitFixture.Controller 'dragging') $false 'button held elsewhere and moved onto overlay does not begin a grab'
}
finally {
    $foreignHitFixture.Controller.Dispose()
    $foreignHitFixture.Window.Close()
}

$dedupeFixture = New-ControllerFixture
$dedupePhysicalState = [pscustomobject]@{ Pressed = $true }
$dedupeCursorState = [pscustomobject]@{ Point = [Drawing.Point]::new(700, 420) }
$dedupeClickCounter = [pscustomobject]@{ Value = 0 }
$dedupeWriteCounter = [pscustomobject]@{ Value = 0 }
$dedupeClickHandler = [EventHandler]{ param($sender, $eventArgs) $dedupeClickCounter.Value++ }
$dedupeFixture.Controller.add_ClickRequested($dedupeClickHandler)
try {
    Set-ControllerField $dedupeFixture.Controller 'physicalLeftButtonPressedProvider' ([Func[bool]]{
        $dedupePhysicalState.Pressed
    })
    Set-ControllerField $dedupeFixture.Controller 'overlayTopLevelHitProvider' ([Func[Drawing.Point, bool]]{
        param($point)
        $true
    })
    Set-ControllerField $dedupeFixture.Controller 'cursorPositionProvider' ([Func[Drawing.Point]]{
        $dedupeCursorState.Point
    })
    Set-ControllerField $dedupeFixture.Controller 'leftButtonPressedProvider' ([Func[Windows.Input.MouseEventArgs, bool]]{
        param($eventArgs)
        $true
    })
    Set-ControllerField $dedupeFixture.Controller 'settingsWriteProvider' ([Action[string, string]]{
        param($path, $json)
        $dedupeWriteCounter.Value++
    })
    Set-ControllerField $dedupeFixture.Controller 'physicalLeftButtonWasPressed' $false

    Invoke-ControllerMouseDown $dedupeFixture
    $wpfPressCursor = Get-ControllerField $dedupeFixture.Controller 'pressCursor'
    $dedupeCursorState.Point = [Drawing.Point]::new(701, 420)
    Invoke-ControllerRendering $dedupeFixture
    $afterPollPressCursor = Get-ControllerField $dedupeFixture.Controller 'pressCursor'
    Assert-Equal $afterPollPressCursor.X $wpfPressCursor.X 'WPF down plus physical polling does not restart the same press'
    Assert-Equal $afterPollPressCursor.Y $wpfPressCursor.Y 'deduplicated press retains original cursor anchor'

    $dedupePhysicalState.Pressed = $false
    Invoke-ControllerRendering $dedupeFixture
    Invoke-ControllerMouseUp $dedupeFixture
    Invoke-ControllerRendering $dedupeFixture
    Assert-Equal $dedupeClickCounter.Value 1 'fallback release plus WPF up raises ClickRequested once'
    Assert-Equal $dedupeWriteCounter.Value 1 'fallback release plus WPF up saves once'
    Assert-Equal (Get-ControllerField $dedupeFixture.Controller 'dragging') $false 'physical release completes fallback grab once'
}
finally {
    $dedupeFixture.Controller.remove_ClickRequested($dedupeClickHandler)
    $dedupeFixture.Controller.Dispose()
    $dedupeFixture.Window.Close()
}

$gestureFixture = New-ControllerFixture
$clickCounter = [pscustomobject]@{ Value = 0 }
$clickHandler = [EventHandler]{ param($sender, $eventArgs) $clickCounter.Value++ }
$gestureFixture.Controller.add_ClickRequested($clickHandler)
try {
    $gestureFixture.Window.Left += 17
    $gestureFixture.Window.Top += 11
    Set-ControllerField $gestureFixture.Controller 'dragging' $true
    Set-ControllerField $gestureFixture.Controller 'dragThresholdExceeded' $false
    Set-ControllerField $gestureFixture.Controller 'moving' $false
    Set-ControllerField $gestureFixture.Controller 'velocityX' 0.0
    Set-ControllerField $gestureFixture.Controller 'velocityY' 0.0
    Invoke-ControllerMouseUp $gestureFixture
    Invoke-ControllerMouseUp $gestureFixture
    Assert-Equal $clickCounter.Value 1 'a short press raises ClickRequested exactly once'
    Assert-Equal ([IO.File]::Exists($gestureFixture.SettingsPath)) $true 'grab-stop short press saves its stationary position'
    $clickSettings = Get-Content -Raw -LiteralPath $gestureFixture.SettingsPath | ConvertFrom-Json
    Assert-Near ([double]$clickSettings.Left) $gestureFixture.Window.Left 0.0001 'click save records current left'
    Assert-Near ([double]$clickSettings.Top) $gestureFixture.Window.Top 0.0001 'click save records current top'

    [IO.File]::Delete($gestureFixture.SettingsPath)
    Set-ControllerField $gestureFixture.Controller 'dragging' $true
    Set-ControllerField $gestureFixture.Controller 'dragThresholdExceeded' $true
    Set-ControllerField $gestureFixture.Controller 'moving' $false
    Set-ControllerField $gestureFixture.Controller 'velocityX' 4.0
    Set-ControllerField $gestureFixture.Controller 'velocityY' 4.0
    Invoke-ControllerMouseUp $gestureFixture
    Assert-Equal $clickCounter.Value 1 'a drag release never raises ClickRequested'
    Assert-Equal ([IO.File]::Exists($gestureFixture.SettingsPath)) $true 'slow drag release saves its stationary position'

    [IO.File]::Delete($gestureFixture.SettingsPath)
    Set-ControllerField $gestureFixture.Controller 'dragging' $true
    Set-ControllerField $gestureFixture.Controller 'dragThresholdExceeded' $true
    Set-ControllerField $gestureFixture.Controller 'moving' $false
    Set-ControllerField $gestureFixture.Controller 'velocityX' 100.0
    Set-ControllerField $gestureFixture.Controller 'velocityY' 0.0
    Invoke-ControllerMouseUp $gestureFixture
    Assert-Equal ([IO.File]::Exists($gestureFixture.SettingsPath)) $false 'fling release waits for inertia to settle before saving'
}
finally {
    $gestureFixture.Controller.remove_ClickRequested($clickHandler)
    $gestureFixture.Controller.Dispose()
    $gestureFixture.Window.Close()
    if ([IO.File]::Exists($gestureFixture.SettingsPath)) {
        [IO.File]::Delete($gestureFixture.SettingsPath)
    }
}

$parseTokens = $null
$parseErrors = $null
$scriptAst = [Management.Automation.Language.Parser]::ParseInput(
    $content,
    [ref]$parseTokens,
    [ref]$parseErrors)
$startupFunctionNames = @(
    'Set-DefaultWindowPosition'
    'Clamp-WindowPosition'
    'Initialize-OverlayWindowFromSettings'
    'Set-ScaleControlState'
    'Set-FrictionControlState'
    'Toggle-OverlayControlPanel'
    'Invoke-OverlayControlPanelClick'
    'Register-OverlayControlHandlers'
)
$startupFunctionAsts = foreach ($functionName in $startupFunctionNames) {
    $functionAst = $scriptAst.Find(
        {
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq $functionName
        },
        $true)
    if ($null -eq $functionAst) {
        throw "FAIL: production startup function '$functionName' is executable in isolation"
    }
    $functionAst
}
$startupFunctionsSource = ($startupFunctionAsts | ForEach-Object { $_.Extent.Text }) -join [Environment]::NewLine
. ([scriptblock]::Create($startupFunctionsSource))
$optionalDismissFunctionAst = $scriptAst.Find(
    {
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq 'Dismiss-OverlayControlPanelForCurrentPress'
    },
    $true)
if ($null -ne $optionalDismissFunctionAst) {
    . ([scriptblock]::Create($optionalDismissFunctionAst.Extent.Text))
}
$optionalPreInputFunctionAst = $scriptAst.Find(
    {
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq 'Process-OverlayPreInput'
    },
    $true)
if ($null -ne $optionalPreInputFunctionAst) {
    . ([scriptblock]::Create($optionalPreInputFunctionAst.Extent.Text))
}

function Invoke-PreviewMouseLeftButtonDown($element) {
    $eventArgs = [Windows.Input.MouseButtonEventArgs]::new(
        [Windows.Input.InputManager]::Current.PrimaryMouseDevice,
        [Environment]::TickCount,
        [Windows.Input.MouseButton]::Left)
    $eventArgs.RoutedEvent = [Windows.UIElement]::PreviewMouseLeftButtonDownEvent
    $element.RaiseEvent($eventArgs)
    return $eventArgs
}

function Invoke-RealWpfLeftClick($element) {
    $center = $element.PointToScreen([Windows.Point]::new(
            $element.ActualWidth / 2.0,
            $element.ActualHeight / 2.0))
    $originalCursor = [System.Windows.Forms.Cursor]::Position
    try {
        if (-not [OverlayTestNativeWindow]::SetCursorPos(
                [int][Math]::Round($center.X),
                [int][Math]::Round($center.Y))) {
            throw 'FAIL: real WPF gesture can position the cursor over the stop-motion button'
        }
        Start-Sleep -Milliseconds 50
        [OverlayTestNativeWindow]::SendLeftClick()
        [Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke(
            [Action]{},
            [Windows.Threading.DispatcherPriority]::Background)
    }
    finally {
        [void][OverlayTestNativeWindow]::SetCursorPos($originalCursor.X, $originalCursor.Y)
    }
}

function Invoke-RealWpfDrag($element, [int]$horizontalOffset, [int]$verticalOffset) {
    $dragWindow = [Windows.Window]::GetWindow($element)
    $center = $element.PointToScreen([Windows.Point]::new(
            $element.ActualWidth / 2.0,
            $element.ActualHeight / 2.0))
    $originalCursor = [System.Windows.Forms.Cursor]::Position
    try {
        if (-not [OverlayTestNativeWindow]::SetCursorPos(
                [int][Math]::Round($center.X),
                [int][Math]::Round($center.Y))) {
            throw 'FAIL: real WPF drag can position the cursor over the stop-motion button'
        }
        Start-Sleep -Milliseconds 50
        [OverlayTestNativeWindow]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 30
        $downEvent = [Windows.Input.MouseButtonEventArgs]::new(
            [Windows.Input.InputManager]::Current.PrimaryMouseDevice,
            [Environment]::TickCount,
            [Windows.Input.MouseButton]::Left)
        $downEvent.RoutedEvent = [Windows.UIElement]::PreviewMouseLeftButtonDownEvent
        $dragWindow.RaiseEvent($downEvent)
        [OverlayTestNativeWindow]::mouse_event(
            0x0001,
            [uint32]$horizontalOffset,
            [uint32]$verticalOffset,
            0,
            [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 50
        $moveEvent = [Windows.Input.MouseEventArgs]::new(
            [Windows.Input.InputManager]::Current.PrimaryMouseDevice,
            [Environment]::TickCount)
        $moveEvent.RoutedEvent = [Windows.UIElement]::MouseMoveEvent
        $dragWindow.RaiseEvent($moveEvent)
        $upEvent = [Windows.Input.MouseButtonEventArgs]::new(
            [Windows.Input.InputManager]::Current.PrimaryMouseDevice,
            [Environment]::TickCount,
            [Windows.Input.MouseButton]::Left)
        $upEvent.RoutedEvent = [Windows.UIElement]::PreviewMouseLeftButtonUpEvent
        $dragWindow.RaiseEvent($upEvent)
        [OverlayTestNativeWindow]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
        [Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke(
            [Action]{},
            [Windows.Threading.DispatcherPriority]::Background)
    }
    finally {
        [void][OverlayTestNativeWindow]::SetCursorPos($originalCursor.X, $originalCursor.Y)
    }
}

function Invoke-ControlPanelCapturedOutsideMouseDown(
    $element,
    [bool]$Handled = $false
) {
    $eventArgs = [Windows.Input.MouseButtonEventArgs]::new(
        [Windows.Input.InputManager]::Current.PrimaryMouseDevice,
        [Environment]::TickCount,
        [Windows.Input.MouseButton]::Left)
    $eventArgs.RoutedEvent =
        [Windows.Input.Mouse]::PreviewMouseDownOutsideCapturedElementEvent
    $eventArgs.Handled = $Handled
    $element.RaiseEvent($eventArgs)
}

$controlFixture = New-ControllerFixture -scalePercent 580
try {
    $physicsController = $controlFixture.Controller
    $window = $loadedWindow
    $visualGroup = $loadedWindow.FindName('VisualGroup')
    $controlPanel = $loadedControlPanel
    $scaleDown = $controlPanel.FindName('ScaleDown')
    $scaleUp = $controlPanel.FindName('ScaleUp')
    $scaleDown100 = $controlPanel.FindName('ScaleDown100')
    $scaleUp100 = $controlPanel.FindName('ScaleUp100')
    $scaleValue = $controlPanel.FindName('ScaleValue')
    $frictionSlider = $controlPanel.FindName('FrictionSlider')
    $frictionValue = $controlPanel.FindName('FrictionValue')
    $script:controlsLoading = $true
    $script:syncingControlState = $false
    Set-ScaleControlState 580 -ApplyToController $false
    Set-FrictionControlState 40 -ApplyToController $false
    Register-OverlayControlHandlers
    $script:controlsLoading = $false

    $scaleUp100.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-Equal $script:currentScalePercent 680 'plus 100 changes scale from 580 to 680'
    $plus100Settings = Get-Content -Raw -LiteralPath $controlFixture.SettingsPath | ConvertFrom-Json
    Assert-Equal $plus100Settings.ScalePercent 680 'plus 100 persists 680 to real settings JSON'
    Assert-Near $controlFixture.Window.Width 1985.6 0.0001 'plus 100 applies 680 percent to the real WPF controller'
    $scaleDown100.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-Equal $script:currentScalePercent 580 'minus 100 changes scale from 680 to 580'
    $minus100Settings = Get-Content -Raw -LiteralPath $controlFixture.SettingsPath | ConvertFrom-Json
    Assert-Equal $minus100Settings.ScalePercent 580 'minus 100 persists 580 to real settings JSON'
    Assert-Near $controlFixture.Window.Width 1693.6 0.0001 'minus 100 reapplies 580 percent to the real WPF controller'

    Set-ScaleControlState 50
    $scaleDown100.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-Equal $script:currentScalePercent 1 'minus 100 normalizes a non-positive result to one percent'
    $normalized100Settings = Get-Content -Raw -LiteralPath $controlFixture.SettingsPath | ConvertFrom-Json
    Assert-Equal $normalized100Settings.ScalePercent 1 'minus 100 persists normalized positive scale'
    Assert-Near $controlFixture.Window.Width 2.92 0.0001 'minus 100 keeps real WPF dimensions positive'
    Assert-Equal $scaleDown.IsEnabled $true 'minus 10 remains enabled after minus 100 normalization'
    Assert-Equal $scaleUp.IsEnabled $true 'plus 10 remains enabled after minus 100 normalization'
    Assert-Equal $scaleDown100.IsEnabled $true 'minus 100 remains enabled after normalization'
    Assert-Equal $scaleUp100.IsEnabled $true 'plus 100 remains enabled after normalization'

    Set-ScaleControlState 580
    $scaleDown.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-Equal $script:currentScalePercent 570 'existing minus changes 580 by exactly ten points'
    $scaleUp.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-Equal $script:currentScalePercent 580 'existing plus restores 580 by exactly ten points'

    Set-ScaleControlState 0 -ApplyToController $false
    Assert-Equal $script:currentScalePercent 1 'non-positive UI scale normalizes to one percent'
    Assert-Equal $scaleDown.IsEnabled $true 'minus remains enabled at one percent'
    Assert-Equal $scaleUp.IsEnabled $true 'plus remains enabled at one percent'
    $scaleDown.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-Equal $script:currentScalePercent 1 'minus normalizes a non-positive result back to one percent'
    Assert-Near $controlFixture.Window.Width 2.92 0.0001 'one-percent button result keeps real WPF dimensions valid'
    Set-ScaleControlState 150 -ApplyToController $false
    Assert-Equal $scaleDown.IsEnabled $true 'minus remains enabled above the former maximum'
    Assert-Equal $scaleUp.IsEnabled $true 'plus remains enabled above the former maximum'

    Set-ScaleControlState 150 -ApplyToController $false
    $scaleUp.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-Equal $script:currentScalePercent 160 'plus changes an unbounded scale by exactly ten points'
    Assert-Equal $scaleValue.Text '160%' 'plus updates the unbounded scale label'
    $scaleDown.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-Equal $script:currentScalePercent 150 'minus changes an unbounded scale by exactly ten points'

    Set-ScaleControlState 170
    Set-FrictionControlState -73
    Assert-Equal $frictionValue.Text '-73' 'negative friction label displays the selected signed integer'
    $negativeControlSettings = Get-Content -Raw -LiteralPath $controlFixture.SettingsPath | ConvertFrom-Json
    Assert-Equal $negativeControlSettings.Friction -73 'negative friction persists to real settings JSON'

    $frictionSlider.Value = 72.6
    Assert-Equal $frictionValue.Text '73' 'friction label rounds to an integer'
    $controlSettings = Get-Content -Raw -LiteralPath $controlFixture.SettingsPath | ConvertFrom-Json
    Assert-Equal $controlSettings.ScalePercent 170 'unbounded scale control persists selected value to real settings JSON'
    Assert-Near $controlFixture.Window.Width 496.4 0.0001 'unbounded scale control changes the real WPF window size'
    Assert-Equal $controlSettings.Friction 73 'friction control persists rounded value to real settings JSON'

}
finally {
    $controlPanel.IsOpen = $false
    $controlFixture.Controller.Dispose()
    $controlFixture.Window.Close()
    $loadedWindow.Close()
    if ([IO.File]::Exists($controlFixture.SettingsPath)) {
        [IO.File]::Delete($controlFixture.SettingsPath)
    }
}

$viewFunctionNames = @('Get-QuotaColor', 'Set-RingArc', 'Update-View')
$viewFunctionAsts = foreach ($functionName in $viewFunctionNames) {
    $functionAst = $scriptAst.Find(
        {
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq $functionName
        },
        $true)
    if ($null -eq $functionAst) {
        throw "FAIL: production view function '$functionName' is executable in isolation"
    }
    $functionAst
}
. ([scriptblock]::Create(
    ($viewFunctionAsts | ForEach-Object { $_.Extent.Text }) -join
        [Environment]::NewLine))

function Get-LatestQuota {
    return [pscustomobject]@{
        PrimaryRemaining = 64.2
        SecondaryRemaining = 38.7
        WeeklyRemaining = 38.7
        UpdatedAt = [datetime]::new(2026, 7, 28, 12, 34, 56)
    }
}

$statusWindowXamlReader = [System.Xml.XmlNodeReader]::new(
    [xml]$windowXamlMatch.Groups['xaml'].Value)
$statusWindow = [Windows.Markup.XamlReader]::Load($statusWindowXamlReader)
try {
    $primaryPercent = $statusWindow.FindName('PrimaryPercent')
    $primaryRing = $statusWindow.FindName('PrimaryRing')
    $secondaryPercent = $statusWindow.FindName('SecondaryPercent')
    $secondaryRing = $statusWindow.FindName('SecondaryRing')
    $ringGlow = $statusWindow.FindName('RingGlow')
    $trail1 = $statusWindow.FindName('Trail1')
    $trail2 = $statusWindow.FindName('Trail2')
    $trail3 = $statusWindow.FindName('Trail3')
    $status = $statusWindow.FindName('Status')
    $script:lastQuota = $null
    $script:lastPrimaryRemaining = $null
    $script:lastSecondaryRemaining = $null

    Update-View

    $leftClickSettingsCue = -join ([char[]]@(
        0x5DE6,
        0x952E,
        0x8BBE,
        0x7F6E))
    Assert-Equal (
        $status.Text.IndexOf(
            $leftClickSettingsCue,
            [System.StringComparison]::Ordinal) -ge 0
    ) $true 'rendered status includes the left-click settings cue'
    Assert-Equal (
        $status.Text.IndexOf(
            '12:34:56',
            [System.StringComparison]::Ordinal) -ge 0
    ) $true 'rendered status keeps the live update time'

    function Get-LatestQuota { return $null }
    $script:lastQuota = $null
    $script:lastPrimaryRemaining = $null
    $script:lastSecondaryRemaining = $null

    Update-View

    Assert-Equal (
        $status.Text.IndexOf(
            'Waiting for data',
            [System.StringComparison]::Ordinal) -ge 0 -and
        $status.Text.IndexOf(
            $leftClickSettingsCue,
            [System.StringComparison]::Ordinal) -ge 0
    ) $true 'null quota status keeps waiting semantics and the left-click settings cue together'
}
finally {
    $statusWindow.Close()
}

$timerTickInvocation = $scriptAst.Find(
    {
        param($node)
        $node -is [Management.Automation.Language.InvokeMemberExpressionAst] -and
            $node.Member.Value -eq 'Add_Tick' -and
            $node.Expression.Extent.Text -eq '$timer'
    },
    $true)
if ($null -eq $timerTickInvocation) {
    throw 'FAIL: refresh timer tick remains directly executable for refresh tests'
}
$timerTickScriptText = (
    $timerTickInvocation.Arguments[0].ScriptBlock.EndBlock.Statements |
        ForEach-Object { $_.Extent.Text }) -join [Environment]::NewLine
$refreshQuotaHome = Join-Path ([IO.Path]::GetTempPath()) (
    'CodexQuotaOverlay.RefreshTests.' + [guid]::NewGuid().ToString('N'))
$refreshQuotaPath = Join-Path $refreshQuotaHome '.codex\sessions\2026\08\01\refresh-fixture.jsonl'
$originalRefreshUserProfile = $env:USERPROFILE
$originalRefreshQuotaFileCache = $script:quotaFileCache
$originalTestCodexRunning = ${function:Test-CodexRunning}
$refreshWindow = [pscustomobject]@{ IsVisible = $true }
$refreshWindow | Add-Member -MemberType ScriptMethod -Name Show -Value { $this.IsVisible = $true }
$refreshWindow | Add-Member -MemberType ScriptMethod -Name Hide -Value { $this.IsVisible = $false }
try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $refreshQuotaPath) -Force | Out-Null
    [IO.File]::WriteAllText(
        $refreshQuotaPath,
        '{"timestamp":"2026-08-01T08:00:00Z","payload":{"rate_limits":{"limit_id":"codex","plan_type":"plus","primary":{"used_percent":34,"resets_at":1785600000}}}}')
    $env:USERPROFILE = $refreshQuotaHome
    $script:quotaFileCache = @{}
    $global:CodexQuotaOverlayRefreshQuotaPath = $refreshQuotaPath
    $global:CodexQuotaOverlayRefreshUpdateView = {
        $global:CodexQuotaOverlayRefreshUpdateCalls++
        $event = Get-Content -Raw -LiteralPath $global:CodexQuotaOverlayRefreshQuotaPath |
            ConvertFrom-Json -ErrorAction Stop
        $remaining = 100 - [double]$event.payload.rate_limits.primary.used_percent
        $global:CodexQuotaOverlayRefreshPrimaryPercent.Text = "$remaining%"
    }
    function Test-CodexRunning { return $false }
    $timerTickScript = [scriptblock]::Create(
        $timerTickScriptText.Replace(
            'Update-View',
            '& $global:CodexQuotaOverlayRefreshUpdateView'))

    $refreshWindowXamlReader = [System.Xml.XmlNodeReader]::new(
        [xml]$windowXamlMatch.Groups['xaml'].Value)
    $refreshWindowForTest = [Windows.Markup.XamlReader]::Load($refreshWindowXamlReader)
    try {
        $global:CodexQuotaOverlayRefreshPrimaryPercent =
            $refreshWindowForTest.FindName('PrimaryPercent')
        $global:CodexQuotaOverlayRefreshUpdateCalls = 0

        & $timerTickScript
        Assert-Equal $global:CodexQuotaOverlayRefreshUpdateCalls 1 'timer invokes Update-View while Codex process detection is false'
        Assert-Equal $global:CodexQuotaOverlayRefreshPrimaryPercent.Text '66%' 'timer refresh renders quota while Codex process detection is false'

        [IO.File]::WriteAllText(
            $refreshQuotaPath,
            '{"timestamp":"2026-08-01T08:02:00Z","payload":{"rate_limits":{"limit_id":"codex","plan_type":"plus","primary":{"used_percent":55,"resets_at":1785600000}}}}')
        & $timerTickScript
        Assert-Equal $global:CodexQuotaOverlayRefreshUpdateCalls 2 'timer invokes Update-View after the quota file changes while Codex process detection is false'
        Assert-Equal $global:CodexQuotaOverlayRefreshPrimaryPercent.Text '45%' 'timer refresh renders changed quota file while Codex process detection is false'
    }
    finally {
        $refreshWindowForTest.Close()
    }
}
finally {
    $env:USERPROFILE = $originalRefreshUserProfile
    $script:quotaFileCache = $originalRefreshQuotaFileCache
    if ($null -eq $originalTestCodexRunning) {
        Remove-Item -LiteralPath function:Test-CodexRunning -ErrorAction SilentlyContinue
    } else {
        Set-Item -LiteralPath function:Test-CodexRunning -Value $originalTestCodexRunning
    }
    Remove-Variable -Scope Global -Name @(
        'CodexQuotaOverlayRefreshPrimaryPercent',
        'CodexQuotaOverlayRefreshQuotaPath',
        'CodexQuotaOverlayRefreshUpdateCalls',
        'CodexQuotaOverlayRefreshUpdateView') -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $refreshQuotaHome -Recurse -Force -ErrorAction SilentlyContinue
}

$settingsWriterFixture = New-ControllerFixture
$restoredController = $null
$restoredWindow = $null
try {
    $area = [System.Windows.SystemParameters]::WorkArea
    $settingsWriterFixture.Window.Left = $area.Left + 350
    $settingsWriterFixture.Window.Top = $area.Top + 260
    $settingsWriterFixture.Controller.SetScalePercent(170)
    $settingsWriterFixture.Controller.SetFriction(73)
    $legacyPositiveSettings = Get-Content -Raw -LiteralPath $settingsWriterFixture.SettingsPath | ConvertFrom-Json
    Assert-Equal $legacyPositiveSettings.Friction 73 'positive legacy friction persists in the existing settings format'
    $settingsWriterFixture.Controller.SetFriction(-73)
    $writtenSettings = Get-Content -Raw -LiteralPath $settingsWriterFixture.SettingsPath | ConvertFrom-Json

    $settingsWriterFixture.Controller.Dispose()
    $settingsWriterFixture.Window.Close()

    $restoredWindow = [Windows.Window]::new()
    $restoredWindow.Width = 292
    $restoredWindow.Height = 292
    $window = $restoredWindow
    $settingsPath = $settingsWriterFixture.SettingsPath
    $visualInset = 64.0
    $startupState = Initialize-OverlayWindowFromSettings
    $restoredController = [OverlayPhysicsController]::new(
        $restoredWindow,
        [Windows.Media.ScaleTransform]::new(),
        [Windows.Media.ScaleTransform]::new(),
        $visualInset,
        $settingsPath,
        $startupState.ScalePercent,
        $startupState.Friction,
        [Windows.Shapes.Ellipse]::new(),
        [Windows.Shapes.Ellipse]::new(),
        [Windows.Shapes.Ellipse]::new())

    Assert-Near $restoredWindow.Left ([double]$writtenSettings.Left) 0.0001 'saved JSON restores left through production startup flow'
    Assert-Near $restoredWindow.Top ([double]$writtenSettings.Top) 0.0001 'saved JSON restores top through production startup flow'
    Assert-Near $restoredWindow.Width 496.4 0.0001 'saved JSON restores unbounded scale through production startup flow'
    Assert-Equal $startupState.ScalePercent 170 'production startup flow loads scale above the former maximum'
    Assert-Equal $startupState.Friction -73 'production startup flow loads signed saved friction'
}
finally {
    if ($null -ne $restoredController) { $restoredController.Dispose() }
    if ($null -ne $restoredWindow) { $restoredWindow.Close() }
    if ([IO.File]::Exists($settingsWriterFixture.SettingsPath)) {
        [IO.File]::Delete($settingsWriterFixture.SettingsPath)
    }
}

$asyncWindowXamlReader = [System.Xml.XmlNodeReader]::new(
    [xml]$windowXamlMatch.Groups['xaml'].Value)
$asyncWindow = [Windows.Markup.XamlReader]::Load($asyncWindowXamlReader)
$asyncPanelXamlReader = [System.Xml.XmlNodeReader]::new(
    [xml]$controlPanelXamlMatch.Groups['xaml'].Value)
$asyncPanel = [Windows.Markup.XamlReader]::Load($asyncPanelXamlReader)
$asyncArea = [Windows.SystemParameters]::WorkArea
$asyncWindow.Left = $asyncArea.Left
$asyncWindow.Top = $asyncArea.Top
$asyncSettingsPath = Join-Path ([IO.Path]::GetTempPath()) (
    'CodexQuotaOverlay.Tests.' + [guid]::NewGuid().ToString('N') + '.json')
$asyncController = [OverlayPhysicsController]::new(
    $asyncWindow,
    $asyncWindow.FindName('CardScale'),
    $asyncWindow.FindName('UserScale'),
    64.0,
    $asyncSettingsPath,
    580,
    40,
    $asyncWindow.FindName('Trail1'),
    $asyncWindow.FindName('Trail2'),
    $asyncWindow.FindName('Trail3'))
$asyncControlFixture = [pscustomobject]@{
    Window = $asyncWindow
    Controller = $asyncController
    SettingsPath = $asyncSettingsPath
}
$asyncTimer = $null
$asyncResult = [pscustomobject]@{ Error = $null; Step = 0 }
try {
    $physicsController = $asyncControlFixture.Controller
    $window = $asyncWindow
    $visualGroup = $asyncWindow.FindName('VisualGroup')
    $controlPanel = $asyncPanel
    $scaleDown = $controlPanel.FindName('ScaleDown')
    $scaleUp = $controlPanel.FindName('ScaleUp')
    $scaleDown100 = $controlPanel.FindName('ScaleDown100')
    $scaleUp100 = $controlPanel.FindName('ScaleUp100')
    $scaleValue = $controlPanel.FindName('ScaleValue')
    $frictionSlider = $controlPanel.FindName('FrictionSlider')
    $frictionValue = $controlPanel.FindName('FrictionValue')
    $script:controlsLoading = $false
    $script:syncingControlState = $false
    Set-ScaleControlState 100 -ApplyToController $false
    Set-FrictionControlState 40 -ApplyToController $false
    $asyncOverlayHitState = [pscustomobject]@{ IsOverlay = $true }
    $asyncCursorState = [pscustomobject]@{
        Point = [Drawing.Point]::new(640, 360)
    }
    $asyncPhysicalState = [pscustomobject]@{ Pressed = $false }
    $asyncClickCounter = [pscustomobject]@{ Value = 0 }
    $asyncClickHandler = [EventHandler]{
        param($sender, $eventArgs)
        $asyncClickCounter.Value++
    }
    $asyncControlFixture.Controller.add_ClickRequested($asyncClickHandler)
    $asyncDragCounter = [pscustomobject]@{ Value = 0 }
    $asyncDragHandler = [EventHandler]{
        param($sender, $eventArgs)
        $asyncDragCounter.Value++
    }
    $asyncControlFixture.Controller.add_DragCompleted($asyncDragHandler)
    Set-ControllerField $asyncControlFixture.Controller 'cursorPositionProvider' ([Func[Drawing.Point]]{
        $asyncCursorState.Point
    })
    Set-ControllerField $asyncControlFixture.Controller 'overlayTopLevelHitProvider' ([Func[Drawing.Point, bool]]{
        param($point)
        $asyncOverlayHitState.IsOverlay
    })
    Set-ControllerField $asyncControlFixture.Controller 'physicalLeftButtonPressedProvider' ([Func[bool]]{
        $asyncPhysicalState.Pressed
    })
    Set-ControllerField $asyncControlFixture.Controller 'pixelDeltaToDipProvider' ([Func[double, double, Windows.Vector]]{
        param($x, $y)
        [Windows.Vector]::new($x, $y)
    })
    Register-OverlayControlHandlers
    $asyncPreInputProbeEvent = [Windows.EventManager]::RegisterRoutedEvent(
        "OverlayPreInputProbe$([Guid]::NewGuid().ToString('N'))",
        [Windows.RoutingStrategy]::Direct,
        [Windows.RoutedEventHandler],
        [OverlayPhysicsController])
    $asyncStagingAuditState = [pscustomobject]@{
        Expected = $null
        Count = 0
        IsMouseButtonEventArgs = $false
        ButtonState = $null
    }
    $asyncStagingAuditHandler = [Windows.Input.PreProcessInputEventHandler]{
        param($sender, $eventArgs)
        $stagedInput = $eventArgs.StagingItem.Input
        if (-not [object]::ReferenceEquals(
                $stagedInput,
                $asyncStagingAuditState.Expected)) {
            return
        }
        $asyncStagingAuditState.Count++
        $asyncStagingAuditState.IsMouseButtonEventArgs =
            $stagedInput -is [Windows.Input.MouseButtonEventArgs]
        $asyncStagingAuditState.ButtonState = $stagedInput.ButtonState
    }
    [Windows.Input.InputManager]::Current.add_PreProcessInput(
        $asyncStagingAuditHandler)
    $invokeAsyncStagedMouseButton = {
        param(
            [Windows.Input.MouseButton]$button,
            [Windows.Input.MouseButtonState]$buttonState
        )
        $stagedInput = [Windows.Input.MouseButtonEventArgs]::new(
            [Windows.Input.Mouse]::PrimaryDevice,
            [Environment]::TickCount,
            $button)
        $stagedInput |
            Add-Member -MemberType NoteProperty -Name ButtonState -Value $buttonState -Force
        $stagedInput.RoutedEvent = $asyncPreInputProbeEvent
        $stagedInput.Source = $asyncWindow
        $asyncStagingAuditState.Expected = $stagedInput
        $asyncStagingAuditState.Count = 0
        $asyncStagingAuditState.IsMouseButtonEventArgs = $false
        $asyncStagingAuditState.ButtonState = $null
        [void][Windows.Input.InputManager]::Current.ProcessInput($stagedInput)
        Assert-Equal $asyncStagingAuditState.Count 1 'public ProcessInput stages the exact input object once'
        Assert-Equal $asyncStagingAuditState.IsMouseButtonEventArgs $true 'staged input remains a real MouseButtonEventArgs'
        Assert-Equal $asyncStagingAuditState.ButtonState $buttonState 'staging observes the requested mouse button state'
    }

    $invokeAsyncMouseUp = {
        Set-ControllerField $asyncControlFixture.Controller 'dragging' $true
        Set-ControllerField $asyncControlFixture.Controller 'dragThresholdExceeded' $false
        Invoke-ControllerMouseUp $asyncControlFixture
    }
    $invokeAsyncShortClick = {
        & $invokeAsyncMouseUp
    }
    $invokeAsyncPhysicalDown = {
        if ($asyncPhysicalState.Pressed) {
            throw 'FAIL: physical-down helper requires a released starting state'
        }
        $asyncPhysicalState.Pressed = $true
        Invoke-ControllerRendering $asyncControlFixture
    }
    $invokeAsyncPhysicalUp = {
        $asyncPhysicalState.Pressed = $false
        Invoke-ControllerRendering $asyncControlFixture
    }
    $invokeAsyncPhysicalClick = {
        & $invokeAsyncPhysicalDown
        & $invokeAsyncPhysicalUp
    }
    $assertAsyncControllerReleased = {
        param([string]$name)
        Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'dragging') $false "$name clears controller dragging"
        Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'physicalLeftButtonWasPressed') $false "$name clears controller physical latch"
        if (-not $controlPanel.IsOpen) {
            Assert-Equal ($null -eq [Windows.Input.Mouse]::Captured) $true "$name leaves no WPF mouse capture"
        }
    }

    $asyncWindow.Opacity = 0.01
    $asyncWindow.Show()
    $asyncTimer = [Windows.Threading.DispatcherTimer]::new()
    $asyncTimer.Interval = [TimeSpan]::FromMilliseconds(220)
    $asyncTimer.Add_Tick({
        try {
            switch ($asyncResult.Step) {
                0 {
                    $transparentMarginHit = $asyncWindow.InputHitTest(
                        [Windows.Point]::new(4, 4))
                    Assert-Equal ($null -ne $transparentMarginHit) $true 'transparent overlay margin remains in the controller window hit area'
                    Assert-Equal $visualGroup.IsAncestorOf($transparentMarginHit) $false 'transparent overlay margin route does not pass through VisualGroup'
                    & $invokeAsyncStagedMouseButton Left Pressed
                    Assert-Equal $controlPanel.IsOpen $false 'staged exact-overlay left-down is ignored while the panel is closed'
                    & $invokeAsyncShortClick
                    Assert-Equal $controlPanel.IsOpen $true 'first short click opens the real popup'
                }
                1 {
                    $popupSource = [Windows.PresentationSource]::FromVisual($controlPanel)
                    $popupRoot = if ($null -ne $popupSource) {
                        $popupSource.RootVisual
                    } else {
                        $null
                    }
                    $popupWidth = if ($null -ne $popupRoot) {
                        [double]$popupRoot.RenderSize.Width
                    } else {
                        0.0
                    }
                    $popupHeight = if ($null -ne $popupRoot) {
                        [double]$popupRoot.RenderSize.Height
                    } else {
                        0.0
                    }
                    $popupHandle = if (
                        $null -ne $popupSource -and
                        $popupSource -is [Windows.Interop.HwndSource]
                    ) {
                        $popupSource.Handle
                    } else {
                        [IntPtr]::Zero
                    }
                    $nativeRect = if ($popupHandle -ne [IntPtr]::Zero) {
                        [OverlayTestNativeWindow]::ReadRect($popupHandle)
                    } else {
                        [OverlayTestNativeWindow+Rect]::new()
                    }
                    $nativeWidth = $nativeRect.Right - $nativeRect.Left
                    $nativeHeight = $nativeRect.Bottom - $nativeRect.Top
                    $deviceTransform = if (
                        $null -ne $popupSource -and
                        $null -ne $popupSource.CompositionTarget
                    ) {
                        $popupSource.CompositionTarget.TransformToDevice
                    } else {
                        [Windows.Media.Matrix]::Identity
                    }
                    $expectedNativeWidth = $popupWidth * $deviceTransform.M11
                    $expectedNativeHeight = $popupHeight * $deviceTransform.M22
                    $hasFixedWpfLayout = (
                        -not [double]::IsNaN($controlPanel.Width) -and
                        -not [double]::IsNaN($controlPanel.Height) -and
                        [Math]::Abs($controlPanel.Width - 210.0) -le 1.0 -and
                        [Math]::Abs($controlPanel.MinWidth - 210.0) -le 1.0 -and
                        [Math]::Abs($controlPanel.Height - 172.0) -le 1.0 -and
                        [Math]::Abs($controlPanel.MinHeight - 172.0) -le 1.0 -and
                        [Math]::Abs($popupWidth - 210.0) -le 1.0 -and
                        [Math]::Abs($popupHeight - 172.0) -le 1.0)
                    $hasDpiAdjustedPositiveNativeSize = (
                        $nativeWidth -gt 0 -and
                        $nativeHeight -gt 0 -and
                        [Math]::Abs($nativeWidth - $expectedNativeWidth) -le 2.0 -and
                        [Math]::Abs($nativeHeight - $expectedNativeHeight) -le 2.0)
                    $usesMousePoint = (
                        $controlPanel.Placement -eq
                        [Windows.Controls.Primitives.PlacementMode]::MousePoint)
                    $hasNoScaledTarget = $null -eq $controlPanel.PlacementTarget
                    if (
                        $popupHandle -eq [IntPtr]::Zero -or
                        -not $hasFixedWpfLayout -or
                        -not $hasDpiAdjustedPositiveNativeSize -or
                        -not $usesMousePoint -or
                        -not $hasNoScaledTarget
                    ) {
                        throw (
                            'FAIL: scale-580 production popup has a fixed positive pointer-adjacent HWND ' +
                            "(handle=$popupHandle, width=$popupWidth, height=$popupHeight, " +
                            "nativeWidth=$nativeWidth, nativeHeight=$nativeHeight, " +
                            "expectedNativeWidth=$expectedNativeWidth, expectedNativeHeight=$expectedNativeHeight, " +
                            "configuredWidth=$($controlPanel.Width), minWidth=$($controlPanel.MinWidth), " +
                            "configuredHeight=$($controlPanel.Height), minHeight=$($controlPanel.MinHeight), " +
                            "placement=$($controlPanel.Placement), hasTarget=$($null -ne $controlPanel.PlacementTarget))")
                    }
                    $asyncOverlayHitState.IsOverlay = $true
                    & $invokeAsyncStagedMouseButton Left Pressed
                    Assert-Equal $controlPanel.IsOpen $false 'staged exact-overlay left-down closes immediately before routed-event producers'
                    Assert-Equal $script:controlPanelPresented $false 'staged exact-overlay left-down updates logical panel state immediately'
                }
                2 {
                    & $invokeAsyncMouseUp
                    Assert-Equal $controlPanel.IsOpen $false 'following production ClickRequested does not replace the popup'
                    Assert-Equal $asyncDragCounter.Value 0 'suppressed captured short press does not report drag completion'
                }
                3 {
                    & $invokeAsyncShortClick
                    Assert-Equal $controlPanel.IsOpen $true 'next distinct press opens after same-press suppression is consumed'
                }
                4 {
                    $asyncOverlayHitState.IsOverlay = $false
                    & $invokeAsyncStagedMouseButton Left Pressed
                    Assert-Equal $controlPanel.IsOpen $true 'staged left-down over popup child or foreign HWND does not dismiss'
                    $asyncOverlayHitState.IsOverlay = $true
                    & $invokeAsyncStagedMouseButton Right Pressed
                    Assert-Equal $controlPanel.IsOpen $true 'staged right-down over exact overlay does not dismiss'
                    & $invokeAsyncStagedMouseButton Left Released
                    Assert-Equal $controlPanel.IsOpen $true 'staged left release over exact overlay does not dismiss'
                    $scaleBeforePopupClick = $script:currentScalePercent
                    Invoke-PreviewMouseLeftButtonDown $scaleUp
                    $scaleUp.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
                    Assert-Equal $controlPanel.IsOpen $true 'popup button input does not trigger captured-outside closure'
                    Assert-Equal $script:currentScalePercent ($scaleBeforePopupClick + 10) 'popup button still performs its production action'
                }
                5 {
                    Toggle-OverlayControlPanel
                    Assert-Equal $controlPanel.IsOpen $false 'explicit toggle requests close before asynchronous Closed'
                }
                6 {
                    & $invokeAsyncShortClick
                    Assert-Equal $controlPanel.IsOpen $true 'asynchronous Closed after explicit close does not swallow the next press'
                }
                7 {
                    $asyncOverlayHitState.IsOverlay = $false
                    Invoke-ControlPanelCapturedOutsideMouseDown $controlPanel
                    Assert-Equal $controlPanel.IsOpen $false 'captured outside down over a foreign HWND follows normal StaysOpen false closure'
                }
                8 {
                    Assert-Equal $script:controlPanelPresented $false 'foreign outside close updates logical panel state through normal Closed'
                    & $invokeAsyncShortClick
                    Assert-Equal $controlPanel.IsOpen $true 'next independent overlay click opens after foreign outside close'
                }
                9 {
                    $asyncOverlayHitState.IsOverlay = $true
                    $asyncCursorState.Point = [Drawing.Point]::new(640, 360)
                    $asyncPhysicalState.Pressed = $true
                    Set-ControllerField $asyncControlFixture.Controller 'physicalLeftButtonWasPressed' $false
                    Set-ControllerField $asyncControlFixture.Controller 'dragging' $false
                    $menuCaptureBeforeDrag = [Windows.Input.Mouse]::Captured
                    if ($null -eq $menuCaptureBeforeDrag) {
                        throw 'FAIL: open production ContextMenu owns WPF mouse capture before captured drag'
                    }
                    & $invokeAsyncStagedMouseButton Left Pressed
                    Assert-Equal $controlPanel.IsOpen $false 'staged exact-overlay left-down closes before a possible drag'
                    Assert-Equal ([object]::ReferenceEquals(
                            [Windows.Input.Mouse]::Captured,
                            $asyncWindow)) $true 'pre-input dismissal transfers WPF capture to the controller window before routing'

                    Invoke-ControllerRendering $asyncControlFixture
                    Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'dragging') $true 'physical polling begins the captured overlay press'
                    Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'dragThresholdExceeded') $false 'captured overlay press begins below the drag threshold'

                    $asyncCursorState.Point = [Drawing.Point]::new(652, 360)
                    Invoke-ControllerRendering $asyncControlFixture
                    Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'dragThresholdExceeded') $true 'captured overlay press crosses the six-DIP drag threshold'

                    $clicksBeforeDragRelease = $asyncClickCounter.Value
                    $asyncPhysicalState.Pressed = $false
                    Invoke-ControllerRendering $asyncControlFixture
                    Assert-Equal $asyncClickCounter.Value $clicksBeforeDragRelease 'drag release does not emit ClickRequested'
                    Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'dragging') $false 'physical drag release completes the press'
                }
                10 {
                    Assert-Equal ($null -eq [Windows.Input.Mouse]::Captured) $true 'completed captured-close drag leaves no stale WPF capture to re-arm suppression'
                    & $invokeAsyncShortClick
                    Assert-Equal $controlPanel.IsOpen $true 'first short click after captured-close drag opens immediately'
                }
                11 {
                    $controlPanel.IsOpen = $false
                    $asyncPhysicalState.Pressed = $false
                }
                12 {
                    & $assertAsyncControllerReleased 'continuous sequence initial cleanup'
                    & $invokeAsyncPhysicalClick
                    Assert-Equal $controlPanel.IsOpen $true 'continuous sequence A opens with a normal physical short click'
                    & $assertAsyncControllerReleased 'continuous sequence A open'
                }
                13 {
                    if ($null -eq [Windows.Input.Mouse]::Captured) {
                        throw 'FAIL: continuous sequence A popup owns capture before exact-overlay close'
                    }
                    $asyncOverlayHitState.IsOverlay = $true
                    $asyncCursorState.Point = [Drawing.Point]::new(700, 400)
                    $asyncPhysicalState.Pressed = $true
                    & $invokeAsyncStagedMouseButton Left Pressed
                    Invoke-ControllerRendering $asyncControlFixture
                    $asyncPhysicalState.Pressed = $false
                    Invoke-ControllerRendering $asyncControlFixture
                    Assert-Equal $controlPanel.IsOpen $false 'continuous sequence A exact-overlay short click closes without replacement'
                    & $assertAsyncControllerReleased 'continuous sequence A close'
                }
                14 {
                    & $invokeAsyncPhysicalClick
                    Assert-Equal $controlPanel.IsOpen $true 'continuous sequence B setup click opens the popup'
                    & $assertAsyncControllerReleased 'continuous sequence B setup'
                }
                15 {
                    if ($null -eq [Windows.Input.Mouse]::Captured) {
                        throw 'FAIL: continuous sequence B popup owns capture before captured drag'
                    }
                    $asyncOverlayHitState.IsOverlay = $true
                    $asyncCursorState.Point = [Drawing.Point]::new(720, 420)
                    $asyncPhysicalState.Pressed = $true
                    & $invokeAsyncStagedMouseButton Left Pressed
                    Invoke-ControllerRendering $asyncControlFixture
                    $asyncCursorState.Point = [Drawing.Point]::new(732, 420)
                    Invoke-ControllerRendering $asyncControlFixture
                    Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'dragThresholdExceeded') $true 'continuous sequence B captured press crosses the drag threshold'
                    $asyncPhysicalState.Pressed = $false
                    Invoke-ControllerRendering $asyncControlFixture
                    Assert-Equal $controlPanel.IsOpen $false 'continuous sequence B captured drag keeps the popup closed'
                    & $assertAsyncControllerReleased 'continuous sequence B captured drag'
                }
                16 {
                    & $invokeAsyncPhysicalClick
                    Assert-Equal $controlPanel.IsOpen $true 'continuous sequence B next physical short click opens immediately'
                    & $assertAsyncControllerReleased 'continuous sequence B next click'
                }
                17 {
                    if ($null -eq [Windows.Input.Mouse]::Captured) {
                        throw 'FAIL: continuous sequence B popup owns capture before immediate close'
                    }
                    $asyncOverlayHitState.IsOverlay = $true
                    $asyncCursorState.Point = [Drawing.Point]::new(740, 430)
                    $asyncPhysicalState.Pressed = $true
                    & $invokeAsyncStagedMouseButton Left Pressed
                    Assert-Equal $controlPanel.IsOpen $false 'continuous sequence B immediate exact-overlay down closes the popup'
                    $asyncPhysicalState.Pressed = $false
                    Invoke-ControllerRendering $asyncControlFixture
                    & $assertAsyncControllerReleased 'continuous sequence B immediate close'
                }
                18 {
                    & $invokeAsyncPhysicalClick
                    Assert-Equal $controlPanel.IsOpen $true 'continuous sequence opens cleanly after immediate captured close'
                    & $assertAsyncControllerReleased 'continuous sequence post-immediate click'
                }
                19 {
                    $controlPanel.IsOpen = $false
                }
                20 {
                    & $assertAsyncControllerReleased 'continuous sequence C auto-close'
                    & $invokeAsyncPhysicalClick
                    Assert-Equal $controlPanel.IsOpen $true 'continuous sequence C freshly auto-closed popup reopens on the next exact-overlay short click'
                    & $assertAsyncControllerReleased 'continuous sequence C reopen'
                    Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'suppressClickForCurrentPress') $false 'per-press suppression is cleared after every completed press'
                }
                21 {
                    Assert-Equal $controlPanel.IsOpen $true 'continuous sequence capture-not-ready popup remains logically and visually open'
                    $captureNotReadyClicksBefore = $asyncClickCounter.Value
                    $captureNotReadyDragsBefore = $asyncDragCounter.Value
                    $asyncPhysicalState.Pressed = $true
                    & $invokeAsyncStagedMouseButton Left Pressed
                    Assert-Equal $controlPanel.IsOpen $false 'pre-routing staged exact-overlay left-down dismisses the open popup immediately'
                    $asyncPhysicalState.Pressed = $false
                    Invoke-ControllerRendering $asyncControlFixture
                    Assert-Equal $asyncClickCounter.Value $captureNotReadyClicksBefore 'sub-render-tick fallback close emits no ClickRequested'
                    Assert-Equal $asyncDragCounter.Value $captureNotReadyDragsBefore 'sub-render-tick fallback close emits no DragCompleted'
                    & $assertAsyncControllerReleased 'continuous sequence capture-not-ready fallback'
                }
                22 {
                    & $invokeAsyncPhysicalClick
                    Assert-Equal $controlPanel.IsOpen $true 'next physical click opens immediately after capture-not-ready fallback close'
                    & $assertAsyncControllerReleased 'continuous sequence post-fallback open'
                }
                23 {
                    Assert-Equal $controlPanel.IsOpen $true 'dual-route setup keeps the popup open for direct Window routing'
                    $dualRouteClicksBefore = $asyncClickCounter.Value
                    $dualRouteDragsBefore = $asyncDragCounter.Value
                    $asyncCursorState.Point = [Drawing.Point]::new(760, 440)
                    $asyncPhysicalState.Pressed = $true
                    Set-ControllerField $asyncControlFixture.Controller 'dragging' $true
                    Set-ControllerField $asyncControlFixture.Controller 'dragThresholdExceeded' $false
                    Set-ControllerField $asyncControlFixture.Controller 'suppressClickForCurrentPress' $false
                    Set-ControllerField $asyncControlFixture.Controller 'pressCursor' $asyncCursorState.Point
                    Set-ControllerField $asyncControlFixture.Controller 'lastCursor' $asyncCursorState.Point
                    $dualRoutePressCursor = Get-ControllerField $asyncControlFixture.Controller 'pressCursor'
                    Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'dragging') $true 'dual-route setup models OnMouseDown beginning the controller press before fallback suppression'
                    & $invokeAsyncStagedMouseButton Left Pressed
                    Assert-Equal $controlPanel.IsOpen $false 'pre-input producer dismisses an already-begun controller press'
                    Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'suppressClickForCurrentPress') $true 'pre-input producer idempotently suppresses the already-begun press'
                    & $invokeAsyncStagedMouseButton Left Pressed
                    Assert-Equal (Get-ControllerField $asyncControlFixture.Controller 'pressCursor') $dualRoutePressCursor 'duplicate staging cannot restart or replace the current press'
                    $asyncPhysicalState.Pressed = $false
                    Invoke-ControllerRendering $asyncControlFixture
                    Invoke-ControllerMouseUp $asyncControlFixture
                    Assert-Equal $asyncClickCounter.Value $dualRouteClicksBefore 'dual-route and duplicate release emit no ClickRequested'
                    Assert-Equal $asyncDragCounter.Value $dualRouteDragsBefore 'dual-route and duplicate release emit no DragCompleted'
                    & $assertAsyncControllerReleased 'continuous sequence dual-route close'
                }
                24 {
                    & $invokeAsyncPhysicalClick
                    Assert-Equal $controlPanel.IsOpen $true 'immediate click opens after the dual-route close'
                    & $assertAsyncControllerReleased 'continuous sequence dual-route follow-up open'
                }
                25 {
                    if ($null -eq [Windows.Input.Mouse]::Captured) {
                        throw 'FAIL: capture-ready follow-up popup owns WPF mouse capture'
                    }
                    $readyClicksBefore = $asyncClickCounter.Value
                    $readyDragsBefore = $asyncDragCounter.Value
                    $asyncPhysicalState.Pressed = $true
                    & $invokeAsyncStagedMouseButton Left Pressed
                    $asyncPhysicalState.Pressed = $false
                    Invoke-ControllerRendering $asyncControlFixture
                    Assert-Equal $controlPanel.IsOpen $false 'capture-ready outside path closes immediately after fallback sequence'
                    Assert-Equal $asyncClickCounter.Value $readyClicksBefore 'capture-ready suppressed close emits no ClickRequested'
                    Assert-Equal $asyncDragCounter.Value $readyDragsBefore 'capture-ready suppressed close emits no DragCompleted'
                    & $assertAsyncControllerReleased 'continuous sequence capture-ready follow-up close'
                }
                26 {
                    & $invokeAsyncPhysicalClick
                    Assert-Equal $controlPanel.IsOpen $true 'immediate click reopens after capture-ready close'
                    & $assertAsyncControllerReleased 'continuous sequence immediate reopen'
                }
                27 {
                    $controlPanel.IsOpen = $false
                }
                28 {
                    & $assertAsyncControllerReleased 'continuous sequence final external auto-close'
                    & $invokeAsyncPhysicalClick
                    Assert-Equal $controlPanel.IsOpen $true 'next exact-overlay click opens after final external auto-close'
                    & $assertAsyncControllerReleased 'continuous sequence final reopen'
                }
                29 {
                    $asyncTimer.Stop()
                    $controlPanel.IsOpen = $false
                    $asyncWindow.Close()
                    [Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
                }
            }
            $asyncResult.Step++
        }
        catch {
            $asyncResult.Error = $_
            $asyncTimer.Stop()
            $controlPanel.IsOpen = $false
            $asyncWindow.Close()
            [Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
        }
    })
    $asyncTimer.Start()
    [void][Windows.Threading.Dispatcher]::Run()
    if ($null -ne $asyncResult.Error) { throw $asyncResult.Error }
    Assert-Equal $asyncResult.Step 30 'dispatcher-driven popup state machine completed every step'
}
finally {
    if ($null -ne $asyncTimer) { $asyncTimer.Stop() }
    if ($null -ne $asyncStagingAuditHandler) {
        [Windows.Input.InputManager]::Current.remove_PreProcessInput(
            $asyncStagingAuditHandler)
    }
    $asyncPanel.IsOpen = $false
    if ($null -ne $asyncClickHandler) {
        $asyncControlFixture.Controller.remove_ClickRequested($asyncClickHandler)
    }
    if ($null -ne $asyncDragHandler) {
        $asyncControlFixture.Controller.remove_DragCompleted($asyncDragHandler)
    }
    $asyncControlFixture.Controller.Dispose()
    $asyncControlFixture.Window.Close()
    if ($asyncWindow.IsVisible) { $asyncWindow.Close() }
    if ([IO.File]::Exists($asyncControlFixture.SettingsPath)) {
        [IO.File]::Delete($asyncControlFixture.SettingsPath)
    }
}

$registerHandlersSource = (
    $startupFunctionAsts |
        Where-Object Name -eq 'Register-OverlayControlHandlers'
).Extent.Text
if ($registerHandlersSource.IndexOf(
        '[Windows.Input.Mouse]::PreviewMouseDownOutsideCapturedElementEvent',
        [System.StringComparison]::Ordinal) -ge 0) {
    throw 'FAIL: captured-outside producer is removed in favor of pre-input'
}
if ($registerHandlersSource.IndexOf(
        '$window.Add_PreviewMouseLeftButtonDown',
        [System.StringComparison]::Ordinal) -ge 0) {
    throw 'FAIL: Window preview producer is removed in favor of pre-input'
}
if ([regex]::Matches(
        $registerHandlersSource,
        '\.add_PreProcessInput\s*\(').Count -ne 1) {
    throw 'FAIL: InputManager PreProcessInput is the single production producer'
}
if ($registerHandlersSource.IndexOf(
        '[Windows.Input.PreProcessInputEventHandler]',
        [System.StringComparison]::Ordinal) -lt 0) {
    throw 'FAIL: PreProcessInput registration uses the explicit WPF delegate type'
}
if ($registerHandlersSource.IndexOf(
        '$script:overlayPreProcessInputHandler',
        [System.StringComparison]::Ordinal) -lt 0) {
    throw 'FAIL: PreProcessInput keeps a script-scope root for the typed delegate'
}
if ([regex]::Matches(
        $registerHandlersSource,
        '(?m)^\s*Process-OverlayPreInput \$eventArgs\.StagingItem\.Input\s*$').Count -ne 1) {
    throw 'FAIL: PreProcessInput forwards staged input through one production processor call'
}
$cursorHitMethod = [OverlayPhysicsController].GetMethod(
    'IsCursorOverOverlayWindow',
    [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::Public)
if ($null -eq $cursorHitMethod -or $cursorHitMethod.ReturnType -ne [bool] -or
    $cursorHitMethod.GetParameters().Count -ne 0) {
    throw 'FAIL: controller exposes minimal precise current-cursor overlay HWND check'
}
if ($content.IndexOf(
        'public event EventHandler DragCompleted;',
        [System.StringComparison]::Ordinal) -lt 0) {
    throw 'FAIL: physics controller exposes production drag completion'
}
if ($content.IndexOf(
        'public void SuppressClickForCurrentPress()',
        [System.StringComparison]::Ordinal) -lt 0) {
    throw 'FAIL: physics controller owns suppression for the current press'
}
if ($registerHandlersSource.IndexOf(
        '$physicsController.SuppressClickForCurrentPress()',
        [System.StringComparison]::Ordinal) -ge 0) {
    throw 'FAIL: pre-input registration does not duplicate current-press suppression plumbing'
}
if ($content.IndexOf(
        '$script:suppressNextControlPanelClick',
        [System.StringComparison]::Ordinal) -ge 0) {
    throw 'FAIL: popup-click suppression no longer leaks through PowerShell global state'
}
$dismissFunctionSource = if ($null -ne $optionalDismissFunctionAst) {
    $optionalDismissFunctionAst.Extent.Text
} else {
    ''
}
if ($dismissFunctionSource.IndexOf(
        '$physicsController.SuppressClickForCurrentPress()',
        [System.StringComparison]::Ordinal) -lt 0) {
    throw 'FAIL: shared popup dismiss binds suppression to the current controller press'
}
if ($dismissFunctionSource.IndexOf(
        '[void][Windows.Input.Mouse]::Capture([Windows.IInputElement]$null)',
        [System.StringComparison]::Ordinal) -lt 0) {
    throw 'FAIL: shared popup dismiss releases ContextMenu mouse capture'
}
if ($dismissFunctionSource.IndexOf(
        'if (-not $controlPanel.IsOpen) { return }',
        [System.StringComparison]::Ordinal) -lt 0) {
    throw 'FAIL: shared popup dismiss is idempotent after the first route closes the panel'
}
$preInputFunctionSource = if ($null -ne $optionalPreInputFunctionAst) {
    $optionalPreInputFunctionAst.Extent.Text
} else {
    ''
}
if ($preInputFunctionSource.IndexOf(
        'function Process-OverlayPreInput($input)',
        [System.StringComparison]::Ordinal) -ge 0) {
    throw 'FAIL: pre-input processor avoids PowerShell automatic variable $input'
}
foreach ($requiredPreInputSource in @(
        'if (-not $controlPanel.IsOpen) { return }',
        '$stagedInput -isnot [Windows.Input.MouseButtonEventArgs]',
        '$stagedInput.ChangedButton -ne [Windows.Input.MouseButton]::Left',
        '$stagedInput.ButtonState -ne [Windows.Input.MouseButtonState]::Pressed',
        'if (-not $physicsController.IsCursorOverOverlayWindow()) { return }')) {
    if ($preInputFunctionSource.IndexOf(
            $requiredPreInputSource,
            [System.StringComparison]::Ordinal) -lt 0) {
        throw "FAIL: pre-input processor requires '$requiredPreInputSource'"
    }
}
if ([regex]::Matches(
        $preInputFunctionSource,
        '(?m)^\s*Dismiss-OverlayControlPanelForCurrentPress\s*$').Count -ne 1) {
    throw 'FAIL: pre-input processor has exactly one shared dismiss call'
}

$dragCompletionFixture = New-ControllerFixture
$dragCompletionCounter = [pscustomobject]@{ Value = 0 }
$dragCompletionHandler = [EventHandler]{
    param($sender, $eventArgs)
    $dragCompletionCounter.Value++
}
$dragCompletionFixture.Controller.add_DragCompleted($dragCompletionHandler)
try {
    Set-ControllerField $dragCompletionFixture.Controller 'dragging' $true
    Set-ControllerField $dragCompletionFixture.Controller 'dragThresholdExceeded' $true
    Invoke-ControllerMouseUp $dragCompletionFixture
    Invoke-ControllerMouseUp $dragCompletionFixture
    Assert-Equal $dragCompletionCounter.Value 1 'WPF drag release raises DragCompleted exactly once'

    Set-ControllerField $dragCompletionFixture.Controller 'physicalLeftButtonPressedProvider' ([Func[bool]]{
        $false
    })
    Set-ControllerField $dragCompletionFixture.Controller 'physicalLeftButtonWasPressed' $true
    Set-ControllerField $dragCompletionFixture.Controller 'dragging' $true
    Set-ControllerField $dragCompletionFixture.Controller 'dragThresholdExceeded' $true
    Invoke-ControllerRendering $dragCompletionFixture
    Invoke-ControllerMouseUp $dragCompletionFixture
    Assert-Equal $dragCompletionCounter.Value 2 'physical drag release plus duplicate WPF up raises one additional DragCompleted'
}
finally {
    $dragCompletionFixture.Controller.remove_DragCompleted($dragCompletionHandler)
    $dragCompletionFixture.Controller.Dispose()
    $dragCompletionFixture.Window.Close()
    if ([IO.File]::Exists($dragCompletionFixture.SettingsPath)) {
        [IO.File]::Delete($dragCompletionFixture.SettingsPath)
    }
}

Write-Output 'PASS: circular overlay structure'
