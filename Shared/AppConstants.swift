import Foundation

public enum AppConstants {
    public static let appGroupIdentifier = "group.com.glebporoshin.liquidglassdash"
    public static let statsSnapshotFile = "stats.json"
    public static let displaysSnapshotFile = "displays.json"
    public static let samplerDefaultsSuite = "group.com.glebporoshin.liquidglassdash.defaults"
    public static let samplerIntervalKey = "sampler.interval"
    public static let defaultSampleInterval: TimeInterval = 10
    public static let historyWindow: TimeInterval = 180
    public static let statsWidgetKind = "LiquidGlassDash.Stats"
    public static let displaysWidgetKind = "LiquidGlassDash.Displays"
    public static let loginItemIdentifier = "com.glebporoshin.LiquidGlassDash.SamplerAgent"
}
