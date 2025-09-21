import SwiftUI

public enum DesignTokens {
    public enum Spacing {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
        public static let xlarge: CGFloat = 24
    }

    public enum Radius {
        public static let card: CGFloat = 18
        public static let small: CGFloat = 10
    }

    public enum Shadow {
        public static let radius: CGFloat = 20
        public static let y: CGFloat = 6
        public static let opacity: Double = 0.18
    }

    public enum Opacity {
        public static let glassStroke: Double = 0.18
        public static let highlightTop: Double = 0.30
        public static let highlightMid: Double = 0.08
    }
}
