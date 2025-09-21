import Foundation

public struct DisplaySnapshot: Codable, Sendable {
    public struct Display: Codable, Sendable, Identifiable {
        public var id: UInt32
        public var name: String
        public var isMain: Bool
        public var isBuiltin: Bool
        public var pixelSize: Size
        public var pointSize: Size
        public var scale: Double
        public var bounds: Rect
        public var mirroredTo: UInt32?

        public struct Size: Codable, Sendable {
            public var width: Double
            public var height: Double

            public init(width: Double, height: Double) {
                self.width = width
                self.height = height
            }
        }

        public struct Rect: Codable, Sendable {
            public var x: Double
            public var y: Double
            public var width: Double
            public var height: Double

            public init(x: Double, y: Double, width: Double, height: Double) {
                self.x = x
                self.y = y
                self.width = width
                self.height = height
            }
        }

        public init(id: UInt32,
                    name: String,
                    isMain: Bool,
                    isBuiltin: Bool,
                    pixelSize: Size,
                    pointSize: Size,
                    scale: Double,
                    bounds: Rect,
                    mirroredTo: UInt32?) {
            self.id = id
            self.name = name
            self.isMain = isMain
            self.isBuiltin = isBuiltin
            self.pixelSize = pixelSize
            self.pointSize = pointSize
            self.scale = scale
            self.bounds = bounds
            self.mirroredTo = mirroredTo
        }
    }

    public var version: Int
    public var timestamp: Date
    public var displays: [Display]

    public init(version: Int = 1, timestamp: Date = Date(), displays: [Display]) {
        self.version = version
        self.timestamp = timestamp
        self.displays = displays
    }
}

public extension DisplaySnapshot {
    static let schemaVersion = 1
}
