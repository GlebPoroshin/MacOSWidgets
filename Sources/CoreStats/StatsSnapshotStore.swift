import Foundation

public struct StatsSnapshotStore: Sendable {
    public enum StoreError: Error {
        case appGroupNotAvailable
    }

    private let appGroupIdentifier: String
    private let statsFileName: String

    public init(appGroupIdentifier: String, fileName: String = "stats.json") {
        self.appGroupIdentifier = appGroupIdentifier
        self.statsFileName = fileName
    }

    private func containerURL() throws -> URL {
        let fileManager = FileManager.default
        guard let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw StoreError.appGroupNotAvailable
        }
        let snapshotsURL = url.appendingPathComponent("Snapshots", isDirectory: true)
        if !fileManager.fileExists(atPath: snapshotsURL.path) {
            try fileManager.createDirectory(at: snapshotsURL, withIntermediateDirectories: true)
        }
        return snapshotsURL
    }

    @discardableResult
    public func write(_ snapshot: StatsSnapshot) throws -> URL {
        let directory = try containerURL()
        let fileURL = directory.appendingPathComponent(statsFileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    public func readLatest() throws -> StatsSnapshot? {
        let directory = try containerURL()
        let fileURL = directory.appendingPathComponent(statsFileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(StatsSnapshot.self, from: data)
    }

    public func reset() throws {
        let directory = try containerURL()
        let fileURL = directory.appendingPathComponent(statsFileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
