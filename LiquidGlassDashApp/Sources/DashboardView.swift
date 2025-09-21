import SwiftUI
import CoreStats
import DisplaysKit
import DesignSystem

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                    Text("LiquidGlass Dash")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .padding(.horizontal, DesignTokens.Spacing.large)
                        .padding(.top, DesignTokens.Spacing.large)

                    statsSection
                    displaysSection
                    samplerSection
                }
                .padding(.bottom, DesignTokens.Spacing.xlarge)
            }
            .background(
                LinearGradient(colors: [Color(.sRGB, red: 0.07, green: 0.08, blue: 0.12, opacity: 1),
                                        Color(.sRGB, red: 0.02, green: 0.03, blue: 0.05, opacity: 1)],
                               startPoint: .top,
                               endPoint: .bottom)
            )
        }
    }

    private var statsSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                sectionHeader(title: "System Load", subtitle: "CPU, memory and uptime")
                if let stats = viewModel.stats {
                    StatsOverviewView(snapshot: stats)
                } else {
                    placeholder(text: "Waiting for sampler agent…")
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
    }

    private var displaysSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                sectionHeader(title: "Displays", subtitle: "Active layout and quick actions")
                if let displays = viewModel.displays {
                    DisplaysOverviewView(snapshot: displays)
                } else {
                    placeholder(text: "No display data yet")
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
    }

    private var samplerSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                sectionHeader(title: "Sampler Service", subtitle: "Controls for the background agent")
                SamplerControlsView(viewModel: viewModel)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func placeholder(text: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            ProgressView()
            Text(text)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, DesignTokens.Spacing.medium)
    }
}

private struct StatsOverviewView: View {
    let snapshot: StatsSnapshot

    private var totalCPUPercent: Double { snapshot.cpu.total * 100 }
    private var memoryFraction: Double {
        snapshot.memory.totalBytes > 0 ? Double(snapshot.memory.usedBytes) / Double(snapshot.memory.totalBytes) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.large) {
                MetricGauge(title: "CPU", value: totalCPUPercent, unit: "%", maxValue: 100, accent: .blue)
                MetricGauge(title: "Memory", value: memoryFraction * 100, unit: "%", maxValue: 100, accent: .mint,
                            footer: StatsFormatters.memoryString(used: snapshot.memory.usedBytes,
                                                                total: snapshot.memory.totalBytes))
                MetricGauge(title: "Swap", value: Double(snapshot.memory.swapUsedBytes) / 1_073_741_824,
                            unit: "GB", maxValue: 32, accent: .purple)
            }

            Grid(horizontalSpacing: DesignTokens.Spacing.medium, verticalSpacing: DesignTokens.Spacing.small) {
                GridRow {
                    labeledValue("Uptime", formattedUptime(snapshot.uptime))
                    labeledValue("Cores", "\(snapshot.cpu.perCore.count)")
                    labeledValue("Timestamp", snapshot.timestamp.formatted(date: .omitted, time: .standard))
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text("History")
                    .font(.subheadline.weight(.medium))
                HStack(alignment: .center, spacing: DesignTokens.Spacing.medium) {
                    Sparkline(values: snapshot.history.cpu)
                        .frame(height: 48)
                        .accessibilityLabel("CPU history")
                    Sparkline(values: snapshot.history.memory)
                        .frame(height: 48)
                        .accessibilityLabel("Memory history")
                }
            }
        }
    }

    private func labeledValue(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospacedDigit())
        }
    }

    private func formattedUptime(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: interval) ?? "—"
    }
}

private struct DisplaysOverviewView: View {
    let snapshot: DisplaySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            DisplaysDiagram(displays: snapshot.displays)
                .frame(height: 160)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.medium) {
                    ForEach(snapshot.displays) { display in
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                            Text(display.name)
                                .font(.headline)
                            Text("\(Int(display.pixelSize.width)) × \(Int(display.pixelSize.height)) @ \(String(format: "%.1f", display.scale))x")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if display.isMain {
                                Label("Main Display", systemImage: "star.fill")
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .padding(DesignTokens.Spacing.medium)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.small))
                    }
                }
            }

            HStack(spacing: DesignTokens.Spacing.medium) {
                Button("Open Displays Settings") {
                    DisplaysActions.openSystemDisplays()
                }
                Button(snapshot.displays.contains(where: { $0.isMain && $0.mirroredTo != nil }) ? "Disable Mirroring" : "Enable Mirroring") {
                    DisplaysActions.openSystemDisplays()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private struct SamplerControlsView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Toggle(isOn: Binding(get: { viewModel.loginItemEnabled }, set: { enabled in
                Task { await viewModel.toggleLoginItem(enabled) }
            })) {
                Text("Run Sampler Agent at login")
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                HStack {
                    Text("Sample Interval: \(Int(viewModel.samplerInterval))s")
                    Spacer()
                }
                Slider(value: Binding(get: { viewModel.samplerInterval }, set: { viewModel.setSamplerInterval($0) }),
                       in: 5...60,
                       step: 5) {
                    Text("Interval")
                }
                .frame(maxWidth: 280)
            }
        }
    }
}

private struct DisplaysDiagram: View {
    let displays: [DisplaySnapshot.Display]

    var body: some View {
        GeometryReader { proxy in
            let normalized = normalize(displays: displays)
            ZStack {
                ForEach(normalized, id: \.id) { display in
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                        .fill(display.isMain ? Color.blue.opacity(0.25) : Color.gray.opacity(0.18))
                        .overlay(
                            VStack(alignment: .leading, spacing: 4) {
                                Text(display.name)
                                    .font(.caption)
                                    .bold()
                                Text("\(Int(display.pixelSize.width)) × \(Int(display.pixelSize.height))")
                                    .font(.caption2)
                                if display.isMain {
                                    Label("Main", systemImage: "star.fill")
                                        .font(.caption2)
                                }
                            }
                            .padding(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                                .stroke(display.isMain ? Color.blue.opacity(0.7) : Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .position(x: display.rect.midX * proxy.size.width,
                                  y: display.rect.midY * proxy.size.height)
                        .frame(width: display.rect.width * proxy.size.width,
                               height: display.rect.height * proxy.size.height)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: displays)
                }
            }
        }
    }

    private func normalize(displays: [DisplaySnapshot.Display]) -> [NormalizedDisplay] {
        guard let minX = displays.map({ $0.bounds.x }).min(),
              let minY = displays.map({ $0.bounds.y }).min(),
              let maxX = displays.map({ $0.bounds.x + $0.bounds.width }).max(),
              let maxY = displays.map({ $0.bounds.y + $0.bounds.height }).max(),
              maxX - minX > 0,
              maxY - minY > 0 else {
            return displays.map {
                NormalizedDisplay(id: $0.id,
                                   name: $0.name,
                                   rect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5),
                                   pixelSize: $0.pixelSize,
                                   isMain: $0.isMain)
            }
        }

        return displays.map { display in
            let normalizedRect = CGRect(
                x: (display.bounds.x - minX) / (maxX - minX),
                y: 1 - ((display.bounds.y + display.bounds.height - minY) / (maxY - minY)),
                width: display.bounds.width / (maxX - minX),
                height: display.bounds.height / (maxY - minY)
            )
            return NormalizedDisplay(id: display.id,
                                     name: display.name,
                                     rect: normalizedRect,
                                     pixelSize: display.pixelSize,
                                     isMain: display.isMain)
        }
    }

    private struct NormalizedDisplay: Identifiable {
        var id: UInt32
        var name: String
        var rect: CGRect
        var pixelSize: DisplaySnapshot.Display.Size
        var isMain: Bool
    }
}

#Preview("Dashboard Placeholder") {
    let viewModel = DashboardViewModel()
    viewModel.stats = StatsSnapshot(
        cpu: .init(total: 0.42, perCore: [0.52, 0.36, 0.41, 0.39]),
        memory: .init(usedBytes: 16_222_222_222, totalBytes: 32_000_000_000, swapUsedBytes: 2_120_000_000),
        uptime: 72_000,
        history: .init(cpu: stride(from: 0.2, through: 0.8, by: 0.02).map { $0 },
                       memory: stride(from: 0.4, through: 0.9, by: 0.02).map { $0 },
                       windowSec: 180)
    )
    viewModel.displays = DisplaySnapshot(displays: [
        .init(id: 1,
              name: "Built-in",
              isMain: true,
              isBuiltin: true,
              pixelSize: .init(width: 3024, height: 1964),
              pointSize: .init(width: 1512, height: 982),
              scale: 2,
              bounds: .init(x: 0, y: 0, width: 3024, height: 1964),
              mirroredTo: nil),
        .init(id: 2,
              name: "Studio Display",
              isMain: false,
              isBuiltin: false,
              pixelSize: .init(width: 5120, height: 2880),
              pointSize: .init(width: 2560, height: 1440),
              scale: 2,
              bounds: .init(x: -5120, y: 0, width: 5120, height: 2880),
              mirroredTo: nil)
    ])
    viewModel.samplerInterval = 15
    viewModel.loginItemEnabled = true
    return DashboardView(viewModel: viewModel)
        .frame(width: 720, height: 520)
}
