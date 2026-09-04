public static class OverlayControlMath
{
    public const double DragThreshold = 6.0;

    public static bool IsDragThresholdExceeded(double deltaX, double deltaY)
    {
        return deltaX * deltaX + deltaY * deltaY >= DragThreshold * DragThreshold;
    }

    public static int ClampScalePercent(int value)
    {
        return value <= 0 ? 1 : value;
    }

    public static int ClampFriction(int value)
    {
        return System.Math.Max(-100, System.Math.Min(100, value));
    }

    public static double FrictionCoefficientFromValue(int value)
    {
        int clamped = ClampFriction(value);
        if (clamped < 0) return 2.0 * clamped / 100.0;
        if (clamped <= 40)
            return 0.35 + (1.65 - 0.35) * clamped / 40.0;
        return 1.65 + (4.50 - 1.65) * (clamped - 40) / 60.0;
    }

}
