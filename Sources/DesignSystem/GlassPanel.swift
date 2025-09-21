import SwiftUI

public struct GlassPanel<Content: View>: View {
    private let content: Content
    private let padding: CGFloat

    public init(padding: CGFloat = DesignTokens.Spacing.large,
                @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    public var body: some View {
        content
            .padding(padding)
            .background(materialBackground)
            .overlay(noiseOverlay)
            .overlay(glassStroke)
            .overlay(highlightOverlay)
            .shadow(color: .black.opacity(DesignTokens.Shadow.opacity),
                    radius: DesignTokens.Shadow.radius,
                    x: 0,
                    y: DesignTokens.Shadow.y)
    }

    private var materialBackground: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
            .fill(.ultraThinMaterial)
    }

    private var glassStroke: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
            .strokeBorder(.white.opacity(DesignTokens.Opacity.glassStroke), lineWidth: 1)
    }

    private var highlightOverlay: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(DesignTokens.Opacity.highlightTop), location: 0.0),
                        .init(color: .white.opacity(DesignTokens.Opacity.highlightMid), location: 0.35),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.plusLighter)
    }

    private var noiseOverlay: some View {
        NoiseTexture()
            .opacity(0.04)
            .blendMode(.overlay)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
            .allowsHitTesting(false)
    }
}

private struct NoiseTexture: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Canvas { context, size in
            let intensity = Int(size.width * size.height / 220)
            for _ in 0..<intensity {
                let x = Double.random(in: 0..<size.width)
                let y = Double.random(in: 0..<size.height)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                let alpha = colorScheme == .dark ? 0.25 : 0.15
                context.fill(Path(rect), with: .color(.white.opacity(alpha)))
            }
        }
    }
}
