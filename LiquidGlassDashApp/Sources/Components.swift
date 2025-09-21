import SwiftUI
import AppKit
import DesignSystem

struct MetricGauge: View {
    var title: String
    var value: Double
    var unit: String
    var maxValue: Double
    var accent: Color
    var footer: String?

    private var fraction: Double {
        guard maxValue > 0 else { return 0 }
        return min(max(value / maxValue, 0), 1)
    }

    var body: some View {
        VStack(alignment: .center, spacing: DesignTokens.Spacing.small) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(AngularGradient(gradient: Gradient(colors: [accent, accent.opacity(0.4)]),
                                             center: .center),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: fraction)
                VStack(spacing: 2) {
                    Text(value, format: .number.precision(.fractionLength( (unit == "%") ? 0 : 1 )))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text(unit)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 84, height: 84)

            if let footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 120)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

enum DisplaysActions {
    static func openSystemDisplays() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }
}
