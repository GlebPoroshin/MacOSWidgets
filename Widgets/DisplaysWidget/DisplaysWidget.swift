import WidgetKit
import SwiftUI
import AppIntents
import DisplaysKit
import DesignSystem

struct DisplaysEntry: TimelineEntry {
    let date: Date
    let snapshot: DisplaySnapshot
}

struct DisplaysProvider: TimelineProvider {
    private let store = DisplaySnapshotStore(appGroupIdentifier: AppConstants.appGroupIdentifier,
                                             fileName: AppConstants.displaysSnapshotFile)

    func placeholder(in context: Context) -> DisplaysEntry {
        let sample = DisplaySnapshot(displays: [
            .init(id: 1,
                  name: "Main",
                  isMain: true,
                  isBuiltin: true,
                  pixelSize: .init(width: 3024, height: 1964),
                  pointSize: .init(width: 1512, height: 982),
                  scale: 2,
                  bounds: .init(x: 0, y: 0, width: 3024, height: 1964),
                  mirroredTo: nil),
            .init(id: 2,
                  name: "External",
                  isMain: false,
                  isBuiltin: false,
                  pixelSize: .init(width: 5120, height: 2880),
                  pointSize: .init(width: 2560, height: 1440),
                  scale: 2,
                  bounds: .init(x: -5120, y: 100, width: 5120, height: 2880),
                  mirroredTo: nil)
        ])
        return DisplaysEntry(date: Date(), snapshot: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (DisplaysEntry) -> Void) {
        if let snapshot = try? store.readLatest() {
            completion(DisplaysEntry(date: Date(), snapshot: snapshot))
        } else {
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DisplaysEntry>) -> Void) {
        let entry: DisplaysEntry
        if let snapshot = try? store.readLatest() {
            entry = DisplaysEntry(date: Date(), snapshot: snapshot)
        } else {
            entry = placeholder(in: context)
        }
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct DisplaysWidget: Widget {
    let kind: String = AppConstants.displaysWidgetKind

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind,
                            intent: DisplayConfigurationIntent.self,
                            provider: DisplaysProvider()) { entry in
            DisplaysWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct DisplaysWidgetBundle: WidgetBundle {
    var body: some Widget {
        DisplaysWidget()
    }
}

struct DisplaysWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DisplaysEntry

    var body: some View {
        switch family {
        case .systemMedium:
            DisplaysMediumView(snapshot: entry.snapshot)
        case .systemLarge:
            DisplaysLargeView(snapshot: entry.snapshot)
        default:
            DisplaysMediumView(snapshot: entry.snapshot)
        }
    }
}

private struct DisplaysMediumView: View {
    let snapshot: DisplaySnapshot

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                header
                DisplaysDiagramView(displays: snapshot.displays)
                    .frame(height: 120)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Displays")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(snapshot.displays.count) active")
                    .font(.headline)
            }
            Spacer()
            ControlButtons()
        }
    }
}

private struct DisplaysLargeView: View {
    let snapshot: DisplaySnapshot

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Display Layout")
                            .font(.title3.weight(.medium))
                        Text(snapshot.timestamp, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ControlButtons()
                }
                DisplaysDiagramView(displays: snapshot.displays)
                    .frame(height: 160)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.medium) {
                        ForEach(snapshot.displays) { display in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(display.name)
                                    .font(.headline)
                                Text("ID: \(display.id)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(display.pixelSize.width))×\(Int(display.pixelSize.height)) @ \(String(format: "%.1f", display.scale))x")
                                    .font(.caption2)
                                if display.isMain {
                                    Text("Primary")
                                        .font(.caption2)
                                        .bold()
                                }
                                Button(intent: SetPrimaryDisplayIntent(displayID: Int(display.id))) {
                                    Label("Set Primary", systemImage: "star")
                                }
                                .buttonStyle(.bordered)
                                .font(.caption2)
                            }
                            .padding(DesignTokens.Spacing.small)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.small))
                        }
                    }
                }
            }
        }
    }
}

private struct ControlButtons: View {
    var body: some View {
        HStack(spacing: 8) {
            Button(intent: OpenDisplaysSettingsIntent()) {
                Label("Displays", systemImage: "display")
            }
            Button(intent: ToggleMirroringIntent()) {
                Label("Mirror", systemImage: "rectangle.on.rectangle")
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderedProminent)
    }
}

private struct DisplaysDiagramView: View {
    let displays: [DisplaySnapshot.Display]

    var body: some View {
        GeometryReader { proxy in
            let normalized = normalize(displays: displays)
            ZStack {
                ForEach(normalized, id: \.id) { item in
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                        .fill(item.isMain ? Color.blue.opacity(0.25) : Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                                .stroke(item.isMain ? Color.blue : Color.white.opacity(0.4), lineWidth: 1)
                        )
                        .overlay(
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.caption2)
                                    .bold()
                                Spacer()
                                Text("#\(item.id)")
                                    .font(.caption2)
                            }
                            .padding(4)
                        )
                        .frame(width: item.rect.width * proxy.size.width,
                               height: item.rect.height * proxy.size.height)
                        .position(x: item.rect.midX * proxy.size.width,
                                  y: item.rect.midY * proxy.size.height)
                }
            }
        }
    }

    private func normalize(displays: [DisplaySnapshot.Display]) -> [NormalizedDisplay] {
        guard displays.count > 0,
              let minX = displays.map({ $0.bounds.x }).min(),
              let minY = displays.map({ $0.bounds.y }).min(),
              let maxX = displays.map({ $0.bounds.x + $0.bounds.width }).max(),
              let maxY = displays.map({ $0.bounds.y + $0.bounds.height }).max(),
              maxX - minX > 0,
              maxY - minY > 0 else {
            return displays.enumerated().map { index, display in
                NormalizedDisplay(id: Int(display.id),
                                   name: display.name,
                                   rect: CGRect(x: Double(index) * 0.1, y: 0.1, width: 0.4, height: 0.6),
                                   isMain: display.isMain)
            }
        }

        return displays.map { display in
            let frame = CGRect(
                x: (display.bounds.x - minX) / (maxX - minX),
                y: 1 - ((display.bounds.y + display.bounds.height - minY) / (maxY - minY)),
                width: display.bounds.width / (maxX - minX),
                height: display.bounds.height / (maxY - minY)
            )
            return NormalizedDisplay(id: Int(display.id), name: display.name, rect: frame, isMain: display.isMain)
        }
    }

    private struct NormalizedDisplay: Identifiable {
        var id: Int
        var name: String
        var rect: CGRect
        var isMain: Bool
    }
}

struct DisplayConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Displays Configuration"
    static var description = IntentDescription("Configure display widget")

    @Parameter(title: "Highlight Main Display")
    var highlightMain: Bool?
}
