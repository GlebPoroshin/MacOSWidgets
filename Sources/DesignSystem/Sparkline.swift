import SwiftUI

public struct Sparkline: View {
    private var values: [Double]
    private var lineWidth: CGFloat
    private var lineGradient: Gradient
    private var fillGradient: Gradient

    public init(values: [Double],
                lineWidth: CGFloat = 2,
                lineGradient: Gradient = Gradient(colors: [.white.opacity(0.9), .white.opacity(0.4)]),
                fillGradient: Gradient = Gradient(colors: [.white.opacity(0.25), .white.opacity(0.05), .clear])) {
        self.values = values
        self.lineWidth = lineWidth
        self.lineGradient = lineGradient
        self.fillGradient = fillGradient
    }

    public var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                guard values.count > 1 else { return }
                let cgPath = sparklinePath(in: size)
                let path = Path(cgPath)

                context.stroke(
                    path,
                    with: .linearGradient(
                        lineGradient,
                        startPoint: CGPoint(x: 0, y: size.height / 2),
                        endPoint: CGPoint(x: size.width, y: size.height / 2)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )

                var fillPath = Path(cgPath)
                fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
                fillPath.addLine(to: CGPoint(x: 0, y: size.height))
                fillPath.closeSubpath()
                context.fill(
                    fillPath,
                    with: .linearGradient(
                        self.fillGradient,
                        startPoint: CGPoint(x: size.width / 2, y: 0),
                        endPoint: CGPoint(x: size.width / 2, y: size.height)
                    )
                )
            }
        }
        .drawingGroup()
    }

    private func sparklinePath(in size: CGSize) -> CGPath {
        let maxValue = max(values.max() ?? 1, 0.0001)
        let minValue = min(values.min() ?? 0, maxValue - 0.0001)
        let range = max(maxValue - minValue, 0.0001)
        let stepX = size.width / CGFloat(values.count - 1)
        let path = CGMutablePath()

        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * stepX
            let normalized = (value - minValue) / range
            let y = size.height - CGFloat(normalized) * size.height
            let point = CGPoint(x: x, y: y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}
