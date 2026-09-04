param([switch]$DataOnly)

$ErrorActionPreference = 'Stop'
$appName = 'CodexQuotaOverlay'
$appDir = Join-Path $env:LOCALAPPDATA $appName
$settingsPath = Join-Path $appDir 'settings.json'
$startupPath = Join-Path ([Environment]::GetFolderPath('Startup')) 'Codex Quota Overlay.lnk'
$scriptPath = $MyInvocation.MyCommand.Path
$script:quotaFileCache = @{}

function Get-TargetThreadId {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_THREAD_ID)) { return $env:CODEX_THREAD_ID }

    $statePath = Join-Path $env:USERPROFILE '.codex\.codex-global-state.json'
    if (-not (Test-Path -LiteralPath $statePath)) { return $null }

    $outputRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
    $escapedOutputRoot = [regex]::Escape(($outputRoot -replace '\\', '\\'))
    $stateText = Get-Content -Raw -LiteralPath $statePath -ErrorAction SilentlyContinue
    if ($stateText -match '"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"\s*:\s*"' + $escapedOutputRoot + '"') {
        return $matches[1]
    }

    return $null
}

function Get-LatestQuota {
    $sessions = Join-Path $env:USERPROFILE '.codex\sessions'
    if (-not (Test-Path -LiteralPath $sessions)) { return $null }

    $files = @(Get-ChildItem -LiteralPath $sessions -Recurse -Filter '*.jsonl' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 30)

    if ($files.Count -eq 0) { return $null }

    $records = @()
    foreach ($file in $files) {
        $stamp = '{0}:{1}' -f $file.LastWriteTimeUtc.Ticks, $file.Length
        $cached = $script:quotaFileCache[$file.FullName]
        if ($null -ne $cached -and $cached.Stamp -eq $stamp) {
            if ($null -ne $cached.Record) { $records += $cached.Record }
            continue
        }

        # Keep one best record per file. Account-level `limit_id=codex` data
        # always wins; dual-window auxiliary data is only a fallback.
        $fileCandidates = @()
        $lines = @(Get-Content -LiteralPath $file.FullName -Tail 1200 -ErrorAction SilentlyContinue)
        foreach ($line in $lines) {
            if ($line -notmatch '"rate_limits"') { continue }
            try { $event = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            $limits = $null
            if ($null -ne $event.payload) { $limits = $event.payload.rate_limits }
            if ($null -eq $limits) { $limits = $event.rate_limits }
            if ($null -eq $limits) { continue }
            $primaryBucket = $limits.primary
            $secondaryBucket = $limits.secondary
            if ($null -eq $primaryBucket -and $null -eq $secondaryBucket) { continue }

            $fiveHourBucket = $null
            $weeklyBucket = $null
            foreach ($bucket in @($primaryBucket, $secondaryBucket)) {
                if ($null -eq $bucket) { continue }
                $windowMinutes = 0
                try { $windowMinutes = [int]$bucket.window_minutes } catch { $windowMinutes = 0 }
                if ($windowMinutes -eq 300 -and $null -eq $fiveHourBucket) {
                    $fiveHourBucket = $bucket
                } elseif ($windowMinutes -eq 10080 -and $null -eq $weeklyBucket) {
                    $weeklyBucket = $bucket
                }
            }

            # The original contract had primary=5h and secondary=weekly. Keep
            # that mapping for old logs that predate window_minutes metadata.
            if ($null -eq $fiveHourBucket -and $null -eq $weeklyBucket -and
                $null -ne $primaryBucket -and $null -ne $secondaryBucket) {
                $fiveHourBucket = $primaryBucket
                $weeklyBucket = $secondaryBucket
            }

            # A one-bucket record without metadata is the later weekly-only
            # format. Do not manufacture a 5-hour value from it.
            if ($null -eq $fiveHourBucket -and $null -eq $weeklyBucket) {
                if ($null -ne $primaryBucket) { $weeklyBucket = $primaryBucket }
                elseif ($null -ne $secondaryBucket) { $weeklyBucket = $secondaryBucket }
            }

            # If only one side carries window metadata, the other side is the
            # remaining legacy bucket and can still be mapped safely.
            if ($null -ne $fiveHourBucket -and $null -eq $weeklyBucket -and
                $null -ne $secondaryBucket -and $secondaryBucket -ne $fiveHourBucket) {
                $weeklyBucket = $secondaryBucket
            }
            if ($null -ne $weeklyBucket -and $null -eq $fiveHourBucket -and
                $null -ne $primaryBucket -and $primaryBucket -ne $weeklyBucket) {
                $fiveHourBucket = $primaryBucket
            }

            $hasFiveHour = $null -ne $fiveHourBucket -and $null -ne $fiveHourBucket.used_percent
            $hasWeekly = $null -ne $weeklyBucket -and $null -ne $weeklyBucket.used_percent
            if (-not $hasFiveHour -and -not $hasWeekly) { continue }

            $isPrimaryCodex = [string]$limits.limit_id -ceq 'codex'
            $isDualWindow = $hasFiveHour -and $hasWeekly
            if (-not $isPrimaryCodex -and -not $isDualWindow -and $null -eq $limits.plan_type) { continue }
            try { $timestamp = [DateTimeOffset]::Parse([string]$event.timestamp).LocalDateTime } catch { $timestamp = $file.LastWriteTime }

            $fiveHourUsed = $null
            $fiveHourReset = $null
            if ($hasFiveHour) {
                try {
                    $fiveHourUsed = [double]$fiveHourBucket.used_percent
                    $fiveHourReset = [long]$fiveHourBucket.resets_at
                } catch { $hasFiveHour = $false }
            }
            $weeklyUsed = $null
            $weeklyReset = $null
            if ($hasWeekly) {
                try {
                    $weeklyUsed = [double]$weeklyBucket.used_percent
                    $weeklyReset = [long]$weeklyBucket.resets_at
                } catch { $hasWeekly = $false }
            }
            if (-not $hasFiveHour -and -not $hasWeekly) { continue }
            $isDualWindow = $hasFiveHour -and $hasWeekly

            $rank = 0
            if ($isDualWindow) { $rank += 2 }
            if ($isPrimaryCodex) { $rank += 1 }
            $fileCandidates += [pscustomobject]@{
                Timestamp      = $timestamp
                FiveHourUsed   = $fiveHourUsed
                FiveHourReset  = $fiveHourReset
                WeeklyUsed     = $weeklyUsed
                WeeklyReset    = $weeklyReset
                HasFiveHour    = $hasFiveHour
                HasWeekly      = $hasWeekly
                IsDualWindow   = $isDualWindow
                IsPrimaryCodex = $isPrimaryCodex
                Rank           = $rank
                Source         = $file.FullName
            }
        }

        $filePrimaryRecords = @($fileCandidates | Where-Object { $_.IsPrimaryCodex })
        if ($filePrimaryRecords.Count -gt 0) {
            $fileDualPrimaryRecords = @($filePrimaryRecords | Where-Object { $_.IsDualWindow })
            $fileSelection = if ($fileDualPrimaryRecords.Count -gt 0) {
                $fileDualPrimaryRecords
            } else {
                $filePrimaryRecords
            }
        } else {
            $fileDualRecords = @($fileCandidates | Where-Object { $_.IsDualWindow })
            $fileSelection = if ($fileDualRecords.Count -gt 0) { $fileDualRecords } else { $fileCandidates }
        }
        $fileRecord = $fileSelection |
            Sort-Object -Property @{Expression='Timestamp';Descending=$true} |
            Select-Object -First 1
        $script:quotaFileCache[$file.FullName] = [pscustomobject]@{ Stamp = $stamp; Record = $fileRecord }
        if ($null -ne $fileRecord) { $records += $fileRecord }
    }

    if ($records.Count -eq 0) { return $null }

    # Prefer account-level codex records. Auxiliary buckets are only a
    # fallback when no account-level record exists at all.
    $codexRecords = @($records | Where-Object { $_.IsPrimaryCodex })
    if ($codexRecords.Count -gt 0) {
        $codexDualRecords = @($codexRecords | Where-Object { $_.IsDualWindow })
        $candidateRecords = if ($codexDualRecords.Count -gt 0) { $codexDualRecords } else { $codexRecords }
        $latest = $candidateRecords | Sort-Object Timestamp -Descending | Select-Object -First 1
    } else {
        $dualRecords = @($records | Where-Object { $_.IsDualWindow })
        $candidateRecords = if ($dualRecords.Count -gt 0) { $dualRecords } else { $records }
        $latest = $candidateRecords | Sort-Object Timestamp -Descending | Select-Object -First 1
    }

    $primaryRemaining = $null
    $primaryReset = $null
    if ($latest.HasFiveHour) {
        $primaryRemaining = [Math]::Max(0, [Math]::Min(100, 100 - [double]$latest.FiveHourUsed))
        if ($null -ne $latest.FiveHourReset) {
            $primaryReset = [DateTimeOffset]::FromUnixTimeSeconds([long]$latest.FiveHourReset).LocalDateTime
        }
    }
    $secondaryRemaining = $null
    $secondaryReset = $null
    if ($latest.HasWeekly) {
        $secondaryRemaining = [Math]::Max(0, [Math]::Min(100, 100 - [double]$latest.WeeklyUsed))
        if ($null -ne $latest.WeeklyReset) {
            $secondaryReset = [DateTimeOffset]::FromUnixTimeSeconds([long]$latest.WeeklyReset).LocalDateTime
        }
    }
    return [pscustomobject]@{
        PrimaryRemaining   = $primaryRemaining
        SecondaryRemaining = $secondaryRemaining
        FiveHourRemaining   = $primaryRemaining
        WeeklyRemaining     = $secondaryRemaining
        PrimaryReset        = $primaryReset
        SecondaryReset      = $secondaryReset
        FiveHourReset       = $primaryReset
        WeeklyReset         = $secondaryReset
        UpdatedAt           = $latest.Timestamp
        Source              = $latest.Source
    }
}

if ($DataOnly) {
    $quota = Get-LatestQuota
    if ($null -eq $quota) { Write-Error 'No Codex rate-limit data found.' }
    $quota | ConvertTo-Json
    exit 0
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
$physicsReferences = @(
    [Windows.Window].Assembly.Location
    [Windows.Media.CompositionTarget].Assembly.Location
    [Windows.Point].Assembly.Location
    [System.Xaml.XamlReader].Assembly.Location
    [System.Windows.Forms.Cursor].Assembly.Location
    [System.Drawing.Point].Assembly.Location
) | Select-Object -Unique
$physicsControllerSource = @'
using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using WinForms = System.Windows.Forms;

public sealed class OverlayPhysicsController : IDisposable
{
    private readonly Window window;
    private readonly ScaleTransform scale;
    private readonly ScaleTransform userScale;
    private readonly double inset;
    private readonly string settingsPath;
    private readonly FrameworkElement[] trails;
    private readonly RotateTransform[] trailTransforms;
    private readonly double[] trailOpacities = { 0.22, 0.13, 0.07 };
    private readonly Stopwatch clock = Stopwatch.StartNew();
    private bool dragging;
    private bool dragThresholdExceeded;
    private bool moving;
    private System.Drawing.Point pressCursor;
    private System.Drawing.Point lastCursor;
    private double lastPointerTime;
    private double lastFrameTime;
    private double velocityX;
    private double velocityY;
    private double squashX = 1.0;
    private double squashY = 1.0;
    private int scalePercent;
    private int frictionValue;
    private Func<System.Drawing.Point> cursorPositionProvider;
    private Func<MouseEventArgs, bool> leftButtonPressedProvider;
    private Func<double, double, Vector> pixelDeltaToDipProvider;
    private Func<bool> physicalLeftButtonPressedProvider;
    private Func<System.Drawing.Point, bool> overlayTopLevelHitProvider;
    private Action<string, string> settingsWriteProvider;
    private bool physicalLeftButtonWasPressed;
    private bool suppressClickForCurrentPress;

    public event EventHandler ClickRequested;
    public event EventHandler DragCompleted;

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int virtualKey);

    [DllImport("user32.dll")]
    private static extern IntPtr WindowFromPoint(System.Drawing.Point point);

    public OverlayPhysicsController(
        Window window,
        ScaleTransform scale,
        ScaleTransform userScale,
        double inset,
        string settingsPath,
        int initialScalePercent,
        int initialFriction,
        FrameworkElement trail1,
        FrameworkElement trail2,
        FrameworkElement trail3)
    {
        this.window = window;
        this.scale = scale;
        this.userScale = userScale;
        this.inset = inset;
        this.settingsPath = settingsPath;
        scalePercent = OverlayControlMath.ClampScalePercent(initialScalePercent);
        frictionValue = OverlayControlMath.ClampFriction(initialFriction);
        cursorPositionProvider = delegate { return WinForms.Cursor.Position; };
        leftButtonPressedProvider = delegate(MouseEventArgs args)
        {
            return args.LeftButton == MouseButtonState.Pressed;
        };
        pixelDeltaToDipProvider = PixelDeltaToDipFromWindow;
        physicalLeftButtonPressedProvider = IsPhysicalLeftButtonPressed;
        overlayTopLevelHitProvider = IsOverlayTopLevelAtPoint;
        settingsWriteProvider = File.WriteAllText;
        trails = new[] { trail1, trail2, trail3 };
        trailTransforms = new[]
        {
            new RotateTransform(),
            new RotateTransform(),
            new RotateTransform()
        };
        for (int i = 0; i < trails.Length; i++)
        {
            trails[i].RenderTransform = trailTransforms[i];
            trails[i].RenderTransformOrigin = new Point(0.5, 0.5);
        }

        ApplyScale(false);
        ResolveCollisions();
    }

    public void Start()
    {
        physicalLeftButtonWasPressed = physicalLeftButtonPressedProvider();
        lastFrameTime = clock.Elapsed.TotalSeconds;
        window.MouseLeftButtonDown += OnMouseDown;
        window.MouseMove += OnMouseMove;
        window.MouseLeftButtonUp += OnMouseUp;
        CompositionTarget.Rendering += OnRendering;
    }

    private void OnMouseDown(object sender, MouseButtonEventArgs e)
    {
        if (!leftButtonPressedProvider(e)) return;
        BeginPress(cursorPositionProvider());
        e.Handled = true;
    }

    private void BeginPress(System.Drawing.Point cursor)
    {
        if (dragging) return;
        dragging = true;
        dragThresholdExceeded = false;
        suppressClickForCurrentPress = false;
        moving = false;
        velocityX = 0.0;
        velocityY = 0.0;
        pressCursor = cursor;
        lastCursor = pressCursor;
        lastPointerTime = clock.Elapsed.TotalSeconds;
        window.CaptureMouse();
    }

    public void SuppressClickForCurrentPress()
    {
        BeginPress(cursorPositionProvider());
        suppressClickForCurrentPress = true;
        physicalLeftButtonWasPressed = true;
    }

    private void OnMouseMove(object sender, MouseEventArgs e)
    {
        if (!dragging) return;
        if (!leftButtonPressedProvider(e)) return;

        if (ProcessCursorPosition(cursorPositionProvider()))
            e.Handled = true;
    }

    private bool ProcessCursorPosition(System.Drawing.Point cursor)
    {
        if (!dragging) return false;
        if (cursor.X == lastCursor.X && cursor.Y == lastCursor.Y) return false;

        if (!dragThresholdExceeded)
        {
            Vector thresholdDelta = PixelDeltaToDip(
                cursor.X - pressCursor.X,
                cursor.Y - pressCursor.Y);
            dragThresholdExceeded = OverlayControlMath.IsDragThresholdExceeded(
                thresholdDelta.X,
                thresholdDelta.Y);
            if (!dragThresholdExceeded) return false;
        }

        double now = clock.Elapsed.TotalSeconds;
        double elapsed = Math.Max(0.001, now - lastPointerTime);
        Vector delta = PixelDeltaToDip(cursor.X - lastCursor.X, cursor.Y - lastCursor.Y);
        if (Math.Abs(delta.X) < 0.001 && Math.Abs(delta.Y) < 0.001) return false;

        window.Left += delta.X;
        window.Top += delta.Y;
        double instantX = delta.X / elapsed;
        double instantY = delta.Y / elapsed;
        velocityX = Clamp(velocityX * 0.15 + instantX * 0.85, -3200.0, 3200.0);
        velocityY = Clamp(velocityY * 0.15 + instantY * 0.85, -3200.0, 3200.0);
        lastCursor = cursor;
        lastPointerTime = now;

        if (Math.Abs(velocityX) > Math.Abs(velocityY))
        {
            squashX = 1.025;
            squashY = 0.985;
        }
        else
        {
            squashX = 0.985;
            squashY = 1.025;
        }
        return true;
    }

    private void OnMouseUp(object sender, MouseButtonEventArgs e)
    {
        if (!dragging) return;
        CompletePress();
        e.Handled = true;
    }

    private void CompletePress()
    {
        if (!dragging) return;
        bool wasDrag = dragThresholdExceeded;
        bool suppressClick = suppressClickForCurrentPress;
        suppressClickForCurrentPress = false;
        EndDrag();
        if (!wasDrag)
        {
            StopInertia();
        }
        if (Math.Abs(velocityX) + Math.Abs(velocityY) <= 10.0)
        {
            StopInertia();
            SavePosition();
        }
        if (!wasDrag && !suppressClick)
        {
            EventHandler handler = ClickRequested;
            if (handler != null) handler(this, EventArgs.Empty);
        }
        else if (wasDrag)
        {
            EventHandler handler = DragCompleted;
            if (handler != null) handler(this, EventArgs.Empty);
        }
    }

    private void EndDrag()
    {
        dragging = false;
        window.ReleaseMouseCapture();
    }

    public void SetScalePercent(int value)
    {
        scalePercent = OverlayControlMath.ClampScalePercent(value);
        StopInertia();
        ApplyScale(true);
        ResolveCollisions();
        SavePosition();
    }

    public void SetFriction(int value)
    {
        frictionValue = OverlayControlMath.ClampFriction(value);
        StopInertia();
        SavePosition();
    }

    public bool IsCursorOverOverlayWindow()
    {
        return overlayTopLevelHitProvider(cursorPositionProvider());
    }

    private void StopInertia()
    {
        velocityX = 0.0;
        velocityY = 0.0;
        moving = false;
    }

    private void ApplyScale(bool preserveCenter)
    {
        double centerX = window.Left + window.Width / 2.0;
        double centerY = window.Top + window.Height / 2.0;
        double factor = scalePercent / 100.0;
        window.Width = 292.0 * factor;
        window.Height = 292.0 * factor;
        userScale.ScaleX = factor;
        userScale.ScaleY = factor;
        if (preserveCenter)
        {
            window.Left = centerX - window.Width / 2.0;
            window.Top = centerY - window.Height / 2.0;
        }
    }

    private Vector PixelDeltaToDip(double x, double y)
    {
        return pixelDeltaToDipProvider(x, y);
    }

    private Vector PixelDeltaToDipFromWindow(double x, double y)
    {
        PresentationSource source = PresentationSource.FromVisual(window);
        Vector pixels = new Vector(x, y);
        if (source == null || source.CompositionTarget == null) return pixels;
        return source.CompositionTarget.TransformFromDevice.Transform(pixels);
    }

    private void OnRendering(object sender, EventArgs e)
    {
        SynchronizePhysicalLeftButton();
        double now = clock.Elapsed.TotalSeconds;
        double deltaSeconds = Clamp(now - lastFrameTime, 0.001, 0.034);
        lastFrameTime = now;
        UpdatePhysics(deltaSeconds);
    }

    private void SynchronizePhysicalLeftButton()
    {
        bool isPressed = physicalLeftButtonPressedProvider();
        if (isPressed)
        {
            System.Drawing.Point cursor = cursorPositionProvider();
            if (!physicalLeftButtonWasPressed && !dragging && overlayTopLevelHitProvider(cursor))
                BeginPress(cursor);
            if (dragging)
                ProcessCursorPosition(cursor);
        }
        else if (!isPressed && physicalLeftButtonWasPressed && dragging)
        {
            CompletePress();
        }
        physicalLeftButtonWasPressed = isPressed;
    }

    private bool IsPhysicalLeftButtonPressed()
    {
        return (GetAsyncKeyState(0x01) & 0x8000) != 0;
    }

    private bool IsOverlayTopLevelAtPoint(System.Drawing.Point point)
    {
        IntPtr overlayHandle = new WindowInteropHelper(window).Handle;
        return overlayHandle != IntPtr.Zero && WindowFromPoint(point) == overlayHandle;
    }

    private void UpdatePhysics(double deltaSeconds)
    {
        double ease = 1.0 - Math.Exp(-13.0 * deltaSeconds);
        squashX += (1.0 - squashX) * ease;
        squashY += (1.0 - squashY) * ease;

        if (!dragging)
        {
            double speed = Math.Abs(velocityX) + Math.Abs(velocityY);
            if (speed > 10.0)
            {
                moving = true;
                window.Left += velocityX * deltaSeconds;
                window.Top += velocityY * deltaSeconds;
                ResolveCollisions();
                double coefficient = OverlayControlMath.FrictionCoefficientFromValue(frictionValue);
                double friction = Math.Exp(-coefficient * deltaSeconds);
                velocityX *= friction;
                velocityY *= friction;
                velocityX = Clamp(velocityX, -3200.0, 3200.0);
                velocityY = Clamp(velocityY, -3200.0, 3200.0);
            }
            else if (moving)
            {
                velocityX = 0.0;
                velocityY = 0.0;
                moving = false;
                SavePosition();
            }
        }

        double breath = (!dragging && !moving)
            ? 1.0 + Math.Sin(clock.Elapsed.TotalSeconds * 2.6) * 0.006
            : 1.0;
        scale.ScaleX = breath * squashX;
        scale.ScaleY = breath * squashY;
        UpdateTrails(deltaSeconds);
    }

    private void UpdateTrails(double deltaSeconds)
    {
        double speed = Math.Sqrt(velocityX * velocityX + velocityY * velocityY);
        double ease = 1.0 - Math.Exp(-18.0 * deltaSeconds);

        if (speed <= 10.0)
        {
            for (int i = 0; i < trails.Length; i++)
            {
                SetArcTrailGeometry(trails[i], 0.0);
                trails[i].Opacity += (0.0 - trails[i].Opacity) * ease;
            }
            return;
        }

        double intensity = Clamp((speed - 10.0) / 1790.0, 0.0, 1.0);
        double reverseVelocityDegrees = Math.Atan2(-velocityY, -velocityX) * 180.0 / Math.PI;
        double arcLength = Clamp(24.0 + speed * 0.04, 24.0, 96.0);
        for (int i = 0; i < trails.Length; i++)
        {
            double targetAngle = reverseVelocityDegrees + 90.0;
            SetArcTrailGeometry(trails[i], arcLength * (1.0 - i * 0.12));
            trailTransforms[i].Angle += NormalizeAngle(targetAngle - trailTransforms[i].Angle) * ease;
            double targetOpacity = trailOpacities[i] * intensity;
            trails[i].Opacity += (targetOpacity - trails[i].Opacity) * ease;
        }
    }

    // Set-ArcTrailGeometry rebuilds one replacement layer from the current render frame.
    private static void SetArcTrailGeometry(FrameworkElement trail, double arcLength)
    {
        System.Windows.Shapes.Path path = trail as System.Windows.Shapes.Path;
        if (path == null) return;
        if (arcLength <= 0.0)
        {
            path.Data = null;
            return;
        }

        const double center = 146.0;
        const double radius = 88.0;
        double halfSweepRadians = arcLength * Math.PI / 360.0;
        double startRadians = -Math.PI / 2.0 - halfSweepRadians;
        double endRadians = -Math.PI / 2.0 + halfSweepRadians;
        PathFigure figure = new PathFigure();
        figure.StartPoint = new Point(
            center + radius * Math.Cos(startRadians),
            center + radius * Math.Sin(startRadians));
        ArcSegment segment = new ArcSegment();
        segment.Point = new Point(
            center + radius * Math.Cos(endRadians),
            center + radius * Math.Sin(endRadians));
        segment.Size = new Size(radius, radius);
        segment.SweepDirection = SweepDirection.Clockwise;
        figure.Segments.Add(segment);
        PathGeometry geometry = new PathGeometry();
        geometry.Figures.Add(figure);
        path.Data = geometry;
    }

    private static double NormalizeAngle(double angle)
    {
        while (angle > 180.0) angle -= 360.0;
        while (angle < -180.0) angle += 360.0;
        return angle;
    }

    private void ResolveCollisions()
    {
        Rect area = SystemParameters.WorkArea;
        double scaledInset = inset * scalePercent / 100.0;
        double minLeft = area.Left - scaledInset;
        double minTop = area.Top - scaledInset;
        double maxLeft = Math.Max(minLeft, area.Right - window.Width + scaledInset);
        double maxTop = Math.Max(minTop, area.Bottom - window.Height + scaledInset);

        if (window.Left < minLeft)
        {
            window.Left = minLeft;
            velocityX = Math.Abs(velocityX) * 0.82;
            SquashHorizontal();
        }
        else if (window.Left > maxLeft)
        {
            window.Left = maxLeft;
            velocityX = -Math.Abs(velocityX) * 0.82;
            SquashHorizontal();
        }

        if (window.Top < minTop)
        {
            window.Top = minTop;
            velocityY = Math.Abs(velocityY) * 0.82;
            SquashVertical();
        }
        else if (window.Top > maxTop)
        {
            window.Top = maxTop;
            velocityY = -Math.Abs(velocityY) * 0.82;
            SquashVertical();
        }
    }

    private void SquashHorizontal()
    {
        squashX = 0.82;
        squashY = 1.11;
    }

    private void SquashVertical()
    {
        squashY = 0.82;
        squashX = 1.11;
    }

    private void SavePosition()
    {
        try
        {
            string directory = Path.GetDirectoryName(settingsPath);
            if (!String.IsNullOrEmpty(directory)) Directory.CreateDirectory(directory);
            // Stable tail property order: "ScalePercent":{2},"Friction":{3}
            string json = String.Format(
                CultureInfo.InvariantCulture,
                "{{\"Left\":{0},\"Top\":{1},\"ScalePercent\":{2},\"Friction\":{3}}}",
                window.Left,
                window.Top,
                scalePercent,
                frictionValue);
            settingsWriteProvider(settingsPath, json);
        }
        catch { }
    }

    private static double Clamp(double value, double minimum, double maximum)
    {
        return Math.Max(minimum, Math.Min(maximum, value));
    }

    public void Dispose()
    {
        CompositionTarget.Rendering -= OnRendering;
        window.MouseLeftButtonDown -= OnMouseDown;
        window.MouseMove -= OnMouseMove;
        window.MouseLeftButtonUp -= OnMouseUp;
    }
}
'@
$controlMathPath = Join-Path $PSScriptRoot 'OverlayControlMath.cs'
$controlMathSource = Get-Content -Raw -LiteralPath $controlMathPath
Add-Type -Language CSharp -ReferencedAssemblies $physicsReferences -TypeDefinition (
    $physicsControllerSource + [Environment]::NewLine + $controlMathSource)
New-Item -ItemType Directory -Path $appDir -Force | Out-Null

$createdNew = $false
$mutex = [Threading.Mutex]::new($true, 'Local\CodexQuotaOverlay.SingleInstance', [ref]$createdNew)
if (-not $createdNew) { exit 0 }

function Set-Autostart([bool]$enabled) {
    if ($enabled) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($startupPath)
        $shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
        $shortcut.WorkingDirectory = Split-Path -Parent $scriptPath
        $shortcut.Description = 'Codex remaining quota overlay launcher'
        $shortcut.Save()
    } else {
        Remove-Item -LiteralPath $startupPath -Force -ErrorAction SilentlyContinue
    }
}

function Test-CodexRunning {
    $processes = @(Get-Process -ErrorAction SilentlyContinue)
    if ($null -ne ($processes | Where-Object {
        $_.ProcessName -match '^Codex$' -or $_.MainWindowTitle -match 'Codex'
    } | Select-Object -First 1)) { return $true }

    foreach ($process in ($processes | Where-Object { $_.ProcessName -eq 'ChatGPT' })) {
        try {
            if ($process.Path -match '\\WindowsApps\\OpenAI\.Codex_') { return $true }
        } catch {}
    }
    return $false
}

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Codex Quota Overlay" Width="292" Height="292" WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" Topmost="True" ShowInTaskbar="False"
        ResizeMode="NoResize" Opacity="0.96">
  <Grid>
    <Grid x:Name="VisualGroup" Width="292" Height="292"
          HorizontalAlignment="Center" VerticalAlignment="Center"
          RenderTransformOrigin="0.5,0.5">
      <Grid.RenderTransform>
        <ScaleTransform x:Name="UserScale" ScaleX="1" ScaleY="1"/>
      </Grid.RenderTransform>
      <Path x:Name="Trail3" Width="292" Height="292" Stretch="None" IsHitTestVisible="False" Opacity="0"
            Stroke="#FF38C985" StrokeThickness="9">
        <Path.Effect><BlurEffect Radius="18"/></Path.Effect>
      </Path>
      <Path x:Name="Trail2" Width="292" Height="292" Stretch="None" IsHitTestVisible="False" Opacity="0"
            Stroke="#FF38C985" StrokeThickness="8">
        <Path.Effect><BlurEffect Radius="13"/></Path.Effect>
      </Path>
      <Path x:Name="Trail1" Width="292" Height="292" Stretch="None" IsHitTestVisible="False" Opacity="0"
            Stroke="#FF38C985" StrokeThickness="7">
        <Path.Effect><BlurEffect Radius="9"/></Path.Effect>
      </Path>
      <Border Width="164" Height="164" HorizontalAlignment="Center" VerticalAlignment="Center"
              CornerRadius="82" BorderThickness="1" Padding="8" RenderTransformOrigin="0.5,0.5">
        <Border.Background>
          <RadialGradientBrush Center="0.32,0.24" GradientOrigin="0.28,0.20" RadiusX="0.78" RadiusY="0.78">
            <GradientStop Color="#FF303A46" Offset="0"/>
            <GradientStop Color="#F5161C24" Offset="0.52"/>
            <GradientStop Color="#FA090D12" Offset="1"/>
          </RadialGradientBrush>
        </Border.Background>
        <Border.BorderBrush>
          <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#B8DDE8F4" Offset="0"/>
            <GradientStop Color="#4A6F7A88" Offset="0.42"/>
            <GradientStop Color="#18606A76" Offset="0.72"/>
            <GradientStop Color="#756F7B89" Offset="1"/>
          </LinearGradientBrush>
        </Border.BorderBrush>
        <Border.Effect><DropShadowEffect BlurRadius="24" ShadowDepth="5" Opacity="0.58" Color="#000000"/></Border.Effect>
        <Border.RenderTransform><ScaleTransform x:Name="CardScale" ScaleX="1" ScaleY="1"/></Border.RenderTransform>
        <Canvas Width="146" Height="146">
          <Ellipse Canvas.Left="5" Canvas.Top="5" Width="136" Height="136" Stroke="#18FFFFFF" StrokeThickness="1"/>
          <Ellipse Canvas.Left="5" Canvas.Top="5" Width="136" Height="136" Stroke="#FF252D36" StrokeThickness="10"/>
          <Ellipse Canvas.Left="22" Canvas.Top="22" Width="102" Height="102" Stroke="#FF252D36" StrokeThickness="8"/>
          <Path x:Name="RingGlow" Stroke="#FF38C985" StrokeThickness="17" Opacity="0.42"
                StrokeStartLineCap="Round" StrokeEndLineCap="Round">
            <Path.Effect><BlurEffect Radius="10"/></Path.Effect>
          </Path>
          <Path x:Name="PrimaryRing" Stroke="#FF38C985" StrokeThickness="10" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
          <Path x:Name="SecondaryRing" Stroke="#FF38C985" StrokeThickness="8" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
          <Path Data="M 33,40 C 53,16 94,10 116,34" Stroke="#4AFFFFFF" StrokeThickness="2"
                 StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
          <TextBlock Canvas.Left="0" Canvas.Top="46" Width="146" Text="5H" TextAlignment="Center"
                      Foreground="#FF9BA7B5" FontSize="10" FontWeight="SemiBold"/>
          <TextBlock x:Name="PrimaryPercent" Canvas.Left="0" Canvas.Top="61" Width="146" TextAlignment="Center"
                      Foreground="#FF38C985" FontSize="29" FontWeight="Bold"/>
          <TextBlock x:Name="SecondaryPercent" Canvas.Left="0" Canvas.Top="92" Width="146" Text="WEEK" TextAlignment="Center"
                      Foreground="#FFB7BEC8" FontSize="11" FontWeight="SemiBold"/>
          <TextBlock x:Name="Status" Canvas.Left="0" Canvas.Top="106" Width="146" TextAlignment="Center"
                      Foreground="#FF687483" FontSize="9"/>
        </Canvas>
      </Border>
    </Grid>
  </Grid>
</Window>
'@

[xml]$controlPanelXaml = @'
<ContextMenu xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             x:Name="ControlPanel" StaysOpen="False" Placement="MousePoint"
             Width="210" MinWidth="210" Height="172" MinHeight="172"
             VerticalOffset="10" Background="Transparent" BorderThickness="0"
             HasDropShadow="False" Opacity="0" RenderTransformOrigin="0.5,0">
  <ContextMenu.RenderTransform>
    <ScaleTransform ScaleX="0.96" ScaleY="0.96"/>
  </ContextMenu.RenderTransform>
  <ContextMenu.Template>
    <ControlTemplate TargetType="{x:Type ContextMenu}">
      <Border Background="Transparent">
        <ItemsPresenter/>
      </Border>
    </ControlTemplate>
  </ContextMenu.Template>
  <ContextMenu.Triggers>
    <EventTrigger RoutedEvent="ContextMenu.Opened">
      <BeginStoryboard>
        <Storyboard>
          <DoubleAnimation Storyboard.TargetProperty="Opacity" To="1" Duration="0:0:0.13"/>
          <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)"
                           To="1" Duration="0:0:0.13"/>
          <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)"
                           To="1" Duration="0:0:0.13"/>
        </Storyboard>
      </BeginStoryboard>
    </EventTrigger>
  </ContextMenu.Triggers>
  <MenuItem StaysOpenOnClick="True" Padding="0" Background="Transparent" BorderThickness="0">
    <MenuItem.Template>
      <ControlTemplate TargetType="{x:Type MenuItem}">
        <ContentPresenter ContentSource="Header"/>
      </ControlTemplate>
    </MenuItem.Template>
    <MenuItem.Header>
      <Border Width="210" Height="172" CornerRadius="14" BorderThickness="1" Padding="14,12"
              Background="#F2181D25">
        <Border.BorderBrush>
          <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#A8EEF4FA" Offset="0"/>
            <GradientStop Color="#526E7885" Offset="0.45"/>
            <GradientStop Color="#24798491" Offset="0.72"/>
            <GradientStop Color="#7FC6D0DB" Offset="1"/>
          </LinearGradientBrush>
        </Border.BorderBrush>
        <Border.Effect>
          <DropShadowEffect BlurRadius="22" ShadowDepth="6" Opacity="0.62" Color="#000000"/>
        </Border.Effect>
        <StackPanel>
          <TextBlock Text="SIZE" Foreground="#FF84909E" FontSize="9"
                     FontWeight="SemiBold" Margin="2,0,0,6"/>
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="42"/>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="42"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="ScaleDown" Grid.Column="0" Content="&#x2212;" Width="34" Height="30"
                    FontSize="18" Foreground="#FFE3E9F0" Background="#FF252B34"
                    BorderBrush="#536E7885" BorderThickness="1" Cursor="Hand"/>
            <TextBlock x:Name="ScaleValue" Grid.Column="1" Text="100%"
                       HorizontalAlignment="Center" VerticalAlignment="Center"
                       Foreground="#FFF1F4F7" FontSize="15" FontWeight="SemiBold"/>
            <Button x:Name="ScaleUp" Grid.Column="2" Content="+" Width="34" Height="30"
                    FontSize="17" Foreground="#FFE3E9F0" Background="#FF252B34"
                    BorderBrush="#536E7885" BorderThickness="1" Cursor="Hand"/>
          </Grid>
          <Grid Margin="2,8,2,0">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="ScaleDown100" Grid.Column="0" Content="&#x2212;100%"
                    Width="72" Height="26" HorizontalAlignment="Left"
                    FontSize="11" Foreground="#FFE3E9F0" Background="#FF252B34"
                    BorderBrush="#536E7885" BorderThickness="1" Cursor="Hand"/>
            <Button x:Name="ScaleUp100" Grid.Column="1" Content="+100%"
                    Width="72" Height="26" HorizontalAlignment="Right"
                    FontSize="11" Foreground="#FFE3E9F0" Background="#FF252B34"
                    BorderBrush="#536E7885" BorderThickness="1" Cursor="Hand"/>
          </Grid>
          <Grid Margin="2,13,2,0">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="32"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
              <TextBlock Text="FRICTION" Foreground="#FF84909E" FontSize="9"
                         FontWeight="SemiBold" Margin="0,0,0,5"/>
              <Slider x:Name="FrictionSlider" Minimum="-100" Maximum="100" Value="40"
                      TickFrequency="1" IsSnapToTickEnabled="False" Cursor="Hand"/>
            </StackPanel>
            <TextBlock x:Name="FrictionValue" Grid.Column="1" Text="40"
                       HorizontalAlignment="Right" VerticalAlignment="Bottom"
                       Margin="0,0,0,2" Foreground="#FFF1F4F7" FontSize="12"
                       FontWeight="SemiBold"/>
          </Grid>
        </StackPanel>
      </Border>
    </MenuItem.Header>
  </MenuItem>
</ContextMenu>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$controlPanelReader = New-Object System.Xml.XmlNodeReader $controlPanelXaml
$controlPanel = [Windows.Markup.XamlReader]::Load($controlPanelReader)
$visualGroup = $window.FindName('VisualGroup')
$userScale = $window.FindName('UserScale')
$cardScale = $window.FindName('CardScale')
$trail1 = $window.FindName('Trail1')
$trail2 = $window.FindName('Trail2')
$trail3 = $window.FindName('Trail3')
$primaryPercent = $window.FindName('PrimaryPercent')
$primaryRing = $window.FindName('PrimaryRing')
$secondaryPercent = $window.FindName('SecondaryPercent')
$secondaryRing = $window.FindName('SecondaryRing')
$ringGlow = $window.FindName('RingGlow')
$status = $window.FindName('Status')
$scaleDown = $controlPanel.FindName('ScaleDown')
$scaleUp = $controlPanel.FindName('ScaleUp')
$scaleDown100 = $controlPanel.FindName('ScaleDown100')
$scaleUp100 = $controlPanel.FindName('ScaleUp100')

$scaleValue = $controlPanel.FindName('ScaleValue')
$frictionSlider = $controlPanel.FindName('FrictionSlider')
$frictionValue = $controlPanel.FindName('FrictionValue')
$lastQuota = $null
$lastPrimaryRemaining = $null
$lastSecondaryRemaining = $null
$visualInset = 64.0
$script:controlsLoading = $true
$script:syncingControlState = $false

function Get-QuotaColor([double]$remaining) {
    if ($remaining -lt 20) { return '#FFFF5F65' }
    if ($remaining -le 50) { return '#FFFFC857' }
    return '#FF38C985'
}

function Set-DefaultWindowPosition {
    $area = [System.Windows.SystemParameters]::WorkArea
    $window.Left = $area.Right - $window.Width + $visualInset - 18
    $window.Top = $area.Top - $visualInset + 18
}

function Clamp-WindowPosition([int]$scalePercent = 100) {
    $area = [System.Windows.SystemParameters]::WorkArea
    $clampedScalePercent = [OverlayControlMath]::ClampScalePercent($scalePercent)
    $scaledInset = $visualInset * $clampedScalePercent / 100.0
    $minLeft = $area.Left - $scaledInset
    $minTop = $area.Top - $scaledInset
    $maxLeft = [Math]::Max($minLeft, $area.Right - $window.Width + $scaledInset)
    $maxTop = [Math]::Max($minTop, $area.Bottom - $window.Height + $scaledInset)

    if ([double]::IsNaN($window.Left) -or [double]::IsInfinity($window.Left)) { $window.Left = $maxLeft - 18 }
    if ([double]::IsNaN($window.Top) -or [double]::IsInfinity($window.Top)) { $window.Top = $minTop + 18 }

    $window.Left = [Math]::Min($maxLeft, [Math]::Max($minLeft, $window.Left))
    $window.Top = [Math]::Min($maxTop, [Math]::Max($minTop, $window.Top))
}

function Initialize-OverlayWindowFromSettings {
    $initialScalePercent = 100
    $initialFriction = 40
    try {
        if (Test-Path -LiteralPath $settingsPath) {
            $settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
            if ($null -ne $settings.ScalePercent) { $initialScalePercent = [int]$settings.ScalePercent }
            if ($null -ne $settings.Friction) { $initialFriction = [int]$settings.Friction }
            $initialScalePercent = [OverlayControlMath]::ClampScalePercent($initialScalePercent)
            $initialFriction = [OverlayControlMath]::ClampFriction($initialFriction)
            $startupScaleFactor = $initialScalePercent / 100.0
            $window.Width = 292.0 * $startupScaleFactor
            $window.Height = 292.0 * $startupScaleFactor
            $window.Left = [double]$settings.Left; $window.Top = [double]$settings.Top
            Clamp-WindowPosition -scalePercent $initialScalePercent
        } else {
            Set-DefaultWindowPosition
        }
    } catch {
        $initialScalePercent = 100
        $initialFriction = 40
        $window.Width = 292.0
        $window.Height = 292.0
        Set-DefaultWindowPosition
    }
    return [pscustomobject]@{
        ScalePercent = $initialScalePercent
        Friction = $initialFriction
    }
}

function Set-ScaleControlState(
    [int]$Value,
    [bool]$ApplyToController = $true
) {
    $clampedValue = [OverlayControlMath]::ClampScalePercent($Value)
    $script:currentScalePercent = $clampedValue
    $scaleValue.Text = "$clampedValue%"
    $scaleDown.IsEnabled = $true
    $scaleUp.IsEnabled = $true
    $scaleDown100.IsEnabled = $true
    $scaleUp100.IsEnabled = $true
    if ($ApplyToController -and -not $script:controlsLoading -and $null -ne $physicsController) {
        $physicsController.SetScalePercent($clampedValue)
    }
}

function Set-FrictionControlState(
    [double]$Value,
    [bool]$ApplyToController = $true
) {
    $roundedValue = [OverlayControlMath]::ClampFriction([int][Math]::Round($Value))
    $previousSyncState = $script:syncingControlState
    $script:syncingControlState = $true
    try {
        $script:currentFriction = $roundedValue
        $frictionSlider.Value = $roundedValue
        $frictionValue.Text = [string]$roundedValue
    }
    finally {
        $script:syncingControlState = $previousSyncState
    }
    if ($ApplyToController -and -not $script:controlsLoading -and $null -ne $physicsController) {
        $physicsController.SetFriction($roundedValue)
    }
}

function Toggle-OverlayControlPanel {
    if ($controlPanel.IsOpen) {
        $script:controlPanelPresented = $false
        $controlPanel.IsOpen = $false
        return
    }

    $script:controlPanelPresented = $true
    $controlPanel.IsOpen = $true
}

function Dismiss-OverlayControlPanelForCurrentPress {
    if (-not $controlPanel.IsOpen) { return }
    $script:controlPanelPresented = $false
    $controlPanel.IsOpen = $false
    [void][Windows.Input.Mouse]::Capture([Windows.IInputElement]$null)
    $physicsController.SuppressClickForCurrentPress()
}

function Process-OverlayPreInput($stagedInput) {
    if (-not $controlPanel.IsOpen) { return }
    if ($stagedInput -isnot [Windows.Input.MouseButtonEventArgs]) { return }
    if ($stagedInput.ChangedButton -ne [Windows.Input.MouseButton]::Left) { return }
    if ($stagedInput.ButtonState -ne [Windows.Input.MouseButtonState]::Pressed) { return }
    if (-not $physicsController.IsCursorOverOverlayWindow()) { return }
    Dismiss-OverlayControlPanelForCurrentPress
}

function Invoke-OverlayControlPanelClick {
    Toggle-OverlayControlPanel
}

function Register-OverlayControlHandlers {
    $script:controlPanelPresented = [bool]$controlPanel.IsOpen
    $controlPanel.Add_Opened({
        $script:controlPanelPresented = $true
    })
    $controlPanel.Add_Closed({
        $script:controlPanelPresented = $false
    })
    $script:overlayPreProcessInputHandler =
        [Windows.Input.PreProcessInputEventHandler]{
            param($sender, $eventArgs)
            Process-OverlayPreInput $eventArgs.StagingItem.Input
        }
    [Windows.Input.InputManager]::Current.add_PreProcessInput(
        $script:overlayPreProcessInputHandler)
    $scaleDown.Add_Click({
        if ($script:controlsLoading) { return }
        Set-ScaleControlState ($script:currentScalePercent - 10)
    })
    $scaleUp.Add_Click({
        if ($script:controlsLoading) { return }
        Set-ScaleControlState ($script:currentScalePercent + 10)
    })
    $scaleDown100.Add_Click({
        if ($script:controlsLoading) { return }
        Set-ScaleControlState ($script:currentScalePercent - 100)
    })
    $scaleUp100.Add_Click({
        if ($script:controlsLoading) { return }
        Set-ScaleControlState ($script:currentScalePercent + 100)
    })
    $frictionSlider.Add_ValueChanged({
        param($sender, $eventArgs)
        if ($script:controlsLoading -or $script:syncingControlState) { return }
        Set-FrictionControlState $sender.Value
    })
    $physicsController.add_ClickRequested({ Invoke-OverlayControlPanelClick })
}

function Set-RingArc($path, [double]$radius, [double]$remaining) {
    $percent = [Math]::Max(0, [Math]::Min(100, $remaining))
    if ($percent -le 0) { $path.Data = $null; return }

    $center = 73.0
    $sweep = [Math]::Min(359.9, $percent * 3.6)
    $radians = $sweep * [Math]::PI / 180
    $endX = $center + ($radius * [Math]::Sin($radians))
    $endY = $center - ($radius * [Math]::Cos($radians))
    $endPoint = [Windows.Point]::new($endX, $endY)
    $figure = New-Object Windows.Media.PathFigure
    $figure.StartPoint = [Windows.Point]::new($center, $center - $radius)
    $segment = New-Object Windows.Media.ArcSegment
    $segment.Point = $endPoint
    $segment.Size = [Windows.Size]::new($radius, $radius)
    $segment.IsLargeArc = $sweep -gt 180
    $segment.SweepDirection = [Windows.Media.SweepDirection]::Clockwise
    $figure.Segments.Add($segment)
    $geometry = New-Object Windows.Media.PathGeometry
    $geometry.Figures.Add($figure)
    $path.Data = $geometry
}

function Update-View {
    $leftClickSettingsCue = -join ([char[]]@(
        0x5DE6,
        0x952E,
        0x8BBE,
        0x7F6E))
    $statusSeparator = [char]0x00B7
    $quota = Get-LatestQuota
    if ($null -ne $quota) { $script:lastQuota = $quota }
    if ($null -eq $script:lastQuota) {
        $primaryPercent.Text = '--%'
        $secondaryPercent.Text = 'WEEK --%'
        $status.Text = "Waiting for data $statusSeparator $leftClickSettingsCue"
        Set-RingArc $primaryRing 64 0
        Set-RingArc $secondaryRing 51 0
        $ringGlow.Data = $primaryRing.Data
        return
    }
    $q = $script:lastQuota
    $fiveHour = $q.PrimaryRemaining
    if ($null -eq $fiveHour) { $fiveHour = $q.FiveHourRemaining }
    $weekly = $q.SecondaryRemaining
    if ($null -eq $weekly) { $weekly = $q.WeeklyRemaining }

    $p = $null
    if ($null -ne $fiveHour) { $p = [Math]::Round([double]$fiveHour, 1) }
    $s = $null
    if ($null -ne $weekly) { $s = [Math]::Round([double]$weekly, 1) }
    $script:lastPrimaryRemaining = $p
    $script:lastSecondaryRemaining = $s
    $primaryPercent.Text = if ($null -eq $p) { '--%' } else { "$p%" }
    $secondaryPercent.Text = if ($null -eq $s) { 'WEEK --%' } else { "WEEK $s%" }
    Set-RingArc $primaryRing 64 $(if ($null -eq $p) { 0 } else { $p })
    Set-RingArc $secondaryRing 51 $(if ($null -eq $s) { 0 } else { $s })
    $ringGlow.Data = $primaryRing.Data
    if ($null -ne $p) {
        $pc = Get-QuotaColor $p
        $primaryRing.Stroke = $pc; $primaryPercent.Foreground = $pc
        $ringGlow.Stroke = $pc
    } else {
        $pc = '#FF687483'
        $primaryRing.Stroke = $pc; $primaryPercent.Foreground = $pc
        $ringGlow.Stroke = $pc
    }
    if ($null -ne $s) {
        $sc = Get-QuotaColor $s
        $secondaryRing.Stroke = $sc; $secondaryPercent.Foreground = $sc
    } else {
        $sc = '#FF687483'
        $secondaryRing.Stroke = $sc; $secondaryPercent.Foreground = $sc
    }
    $trailColor = if ($null -ne $p) { $pc } elseif ($null -ne $s) { $sc } else { '#FF687483' }
    $trail1.Stroke = $trailColor; $trail2.Stroke = $trailColor; $trail3.Stroke = $trailColor
    $status.Text = "$leftClickSettingsCue $statusSeparator $($q.UpdatedAt.ToString('HH:mm:ss'))"
}

$startupSettings = Initialize-OverlayWindowFromSettings
$initialScalePercent = [int]$startupSettings.ScalePercent
$initialFriction = [int]$startupSettings.Friction

$script:physicsController = [OverlayPhysicsController]::new(
    $window,
    $cardScale,
    $userScale,
    $visualInset,
    $settingsPath,
    $initialScalePercent,
    $initialFriction,
    $trail1,
    $trail2,
    $trail3)
Set-ScaleControlState $initialScalePercent -ApplyToController $false
Set-FrictionControlState $initialFriction -ApplyToController $false
Register-OverlayControlHandlers
$script:controlsLoading = $false
$physicsController.Start()
$menu = New-Object Windows.Controls.ContextMenu
$refreshItem = New-Object Windows.Controls.MenuItem; $refreshItem.Header = 'Refresh'; $refreshItem.Add_Click({ Update-View })
$autoItem = New-Object Windows.Controls.MenuItem; $autoItem.Header = 'Start with Windows (wait for Codex)'; $autoItem.IsCheckable = $true; $autoItem.IsChecked = Test-Path -LiteralPath $startupPath
$autoItem.Add_Click({ Set-Autostart $autoItem.IsChecked })
$exitItem = New-Object Windows.Controls.MenuItem; $exitItem.Header = 'Exit'; $exitItem.Add_Click({ $window.Close(); [Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown() })
[void]$menu.Items.Add($refreshItem); [void]$menu.Items.Add($autoItem); [void]$menu.Items.Add((New-Object Windows.Controls.Separator)); [void]$menu.Items.Add($exitItem)
$window.ContextMenu = $menu

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(4)
$timer.Add_Tick({
    Update-View
})
$timer.Start()
Update-View
$window.Show()
[void][Windows.Threading.Dispatcher]::Run()
$physicsController.Dispose()
$timer.Stop(); $mutex.ReleaseMutex(); $mutex.Dispose()
