import Foundation

public struct StatsSnapshot: Codable, Sendable {
    public struct CPU: Codable, Sendable {
        public var total: Double
        public var perCore: [Double]

        public init(total: Double, perCore: [Double]) {
            self.total = total
            self.perCore = perCore
        }
    }

    public struct Memory: Codable, Sendable {
        public var usedBytes: UInt64
        public var totalBytes: UInt64
        public var swapUsedBytes: UInt64

        public init(usedBytes: UInt64, totalBytes: UInt64, swapUsedBytes: UInt64) {
            self.usedBytes = usedBytes
            self.totalBytes = totalBytes
            self.swapUsedBytes = swapUsedBytes
        }
    }

    public struct History: Codable, Sendable {
        public var cpu: [Double]
        public var memory: [Double]
        public var windowSec: TimeInterval

        public init(cpu: [Double], memory: [Double], windowSec: TimeInterval) {
            self.cpu = cpu
            self.memory = memory
            self.windowSec = windowSec
        }
    }

    public var version: Int
    public var timestamp: Date
    public var cpu: CPU
    public var memory: Memory
    public var uptime: TimeInterval
    public var history: History

    public init(version: Int = 1,
                timestamp: Date = Date(),
                cpu: CPU,
                memory: Memory,
                uptime: TimeInterval,
                history: History) {
        self.version = version
        self.timestamp = timestamp
        self.cpu = cpu
        self.memory = memory
        self.uptime = uptime
        self.history = history
    }
}

public extension StatsSnapshot {
    static let schemaVersion = 1
}
