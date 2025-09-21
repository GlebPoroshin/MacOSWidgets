import WidgetKit
import SwiftUI
import AppIntents
import CoreStats
import DesignSystem

struct StatsEntry: TimelineEntry {
    let date: Date
    let snapshot: StatsSnapshot
}

struct StatsProvider: TimelineProvider {
    private let store = StatsSnapshotStore(appGroupIdentifier: AppConstants.appGroupIdentifier,
                                           fileName: AppConstants.statsSnapshotFile)

    func placeholder(in context: Context) -> StatsEntry {
        let sample = StatsSnapshot(
            cpu: .init(total: 0.42, perCore: [0.35, 0.44, 0.39, 0.41]),
            memory: .init(usedBytes: 16_000_000_000, totalBytes: 32_000_000_000, swapUsedBytes: 1_200_000_000),
            uptime: 72_000,
            history: .init(cpu: Array(repeating: 0.5, count: 24),
                           memory: Array(repeating: 0.6, count: 24),
                           windowSec: AppConstants.historyWindow)
        )
        return StatsEntry(date: Date(), snapshot: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
        if let snapshot = try? store.readLatest() {
            completion(StatsEntry(date: Date(), snapshot: snapshot))
        } else {
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        let entry: StatsEntry
        if let snapshot = try? store.readLatest() {
            entry = StatsEntry(date: Date(), snapshot: snapshot)
        } else {
            entry = placeholder(in: context)
        }
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct StatsWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StatsEntry

    var body: some View {
        switch family {
        case .systemSmall:
            StatsSmallView(snapshot: entry.snapshot)
        case .systemMedium:
            StatsMediumView(snapshot: entry.snapshot)
        case .systemLarge:
            StatsLargeView(snapshot: entry.snapshot)
        default:
            StatsMediumView(snapshot: entry.snapshot)
        }
    }
}

struct StatsWidget: Widget {
    let kind: String = AppConstants.statsWidgetKind

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind,
                            intent: ConfigurationAppIntent.self,
                            provider: StatsProvider()) { entry in
            StatsWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct StatsWidgetBundle: WidgetBundle {
    var body: some Widget {
        StatsWidget()
    }
}

private struct StatsSmallView: View {
    let snapshot: StatsSnapshot

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                header
                GaugeView(value: snapshot.cpu.total)
                Sparkline(values: snapshot.history.cpu)
                    .frame(height: 36)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("CPU")
                .font(.caption)
            Text(snapshot.cpu.total, format: .percent.precision(.fractionLength(0)))
                .font(.title3.monospacedDigit())
        }
    }
}

private struct StatsMediumView: View {
    let snapshot: StatsSnapshot

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                header
                HStack(alignment: .center, spacing: DesignTokens.Spacing.medium) {
                    GaugeView(value: snapshot.cpu.total)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memoryString)
                            .font(.headline.monospacedDigit())
                        Sparkline(values: snapshot.history.memory)
                            .frame(height: 44)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("System Load")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(snapshot.cpu.total, format: .percent.precision(.fractionLength(0)))
                    .font(.title2.monospacedDigit())
            }
            Spacer()
            Button(intent: ClearStatsHistoryIntent()) {
                Label("Reset", systemImage: "gobackward")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var memoryString: String {
        StatsFormatters.memoryString(used: snapshot.memory.usedBytes, total: snapshot.memory.totalBytes)
    }
}

private struct StatsLargeView: View {
    let snapshot: StatsSnapshot

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Performance")
                        .font(.title3.weight(.semibold))
                    Spacer()
                    Button(intent: OpenDashboardIntent()) {
                        Label("Open App", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: DesignTokens.Spacing.large) {
                    GaugeGrid(snapshot: snapshot)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                        Text("History")
                            .font(.headline)
                        Sparkline(values: snapshot.history.cpu)
                            .frame(height: 48)
                        Sparkline(values: snapshot.history.memory)
                            .frame(height: 48)
                    }
                }
            }
        }
    }
}

private struct GaugeView: View {
    var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text("CPU")
                .font(.caption)
                .foregroundStyle(.secondary)
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(AngularGradient(colors: [.blue, .cyan], center: .center),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.4), value: value)
                Text(value, format: .percent.precision(.fractionLength(0)))
                    .font(.headline.monospacedDigit())
            }
            .frame(width: 96, height: 96)
        }
    }
}

private struct GaugeGrid: View {
    let snapshot: StatsSnapshot

    var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                MetricCell(title: "Total CPU", value: snapshot.cpu.total, unit: "%")
                MetricCell(title: "RAM", value: Double(snapshot.memory.usedBytes) / Double(snapshot.memory.totalBytes), unit: "%")
            }
            GridRow {
                MetricCell(title: "Swap", value: Double(snapshot.memory.swapUsedBytes) / 10_737_418_240, unit: "GB")
                MetricCell(title: "Uptime", value: snapshot.uptime / 3600, unit: "h")
            }
        }
    }
}

private struct MetricCell: View {
    var title: String
    var value: Double
    var unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formattedValue)
                .font(.subheadline.monospacedDigit())
            ProgressView(value: min(max(valueNormalized, 0), 1))
                .progressViewStyle(.linear)
        }
        .padding(10)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.small))
    }

    private var formattedValue: String {
        switch unit {
        case "%":
            return value.formatted(.percent.precision(.fractionLength(0)))
        case "GB":
            return String(format: "%.1f GB", value)
        default:
            return String(format: "%.0f %@", value, unit)
        }
    }

    private var valueNormalized: Double {
        switch unit {
        case "%": return value
        case "GB": return min(value / 16, 1)
        default: return min(value / 48, 1)
        }
    }
}

private extension ProgressViewStyle where Self == LinearProgressViewStyle {
    static var linear: LinearProgressViewStyle { .init() }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Stats Configuration"
    static var description = IntentDescription("Configure the stats widget")

    @Parameter(title: "Show per-core detail")
    var showPerCore: Bool?
}

struct StatsWidget_Previews: PreviewProvider {
    static var previews: some View {
        StatsWidgetEntryView(entry: StatsProvider().placeholder(in: .init()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
