import Foundation

public struct DisplaySnapshotStore: Sendable {
    public enum StoreError: Error {
        case appGroupNotAvailable
    }

    private let appGroupIdentifier: String
    private let fileName: String

    public init(appGroupIdentifier: String, fileName: String = "displays.json") {
        self.appGroupIdentifier = appGroupIdentifier
        self.fileName = fileName
    }

    private func containerURL() throws -> URL {
        let fileManager = FileManager.default
        guard let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw StoreError.appGroupNotAvailable
        }
        let folder = url.appendingPathComponent("Snapshots", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    @discardableResult
    public func write(_ snapshot: DisplaySnapshot) throws -> URL {
        let fileManager = FileManager.default
        let directory = try containerURL()
        let fileURL = directory.appendingPathComponent(fileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    public func readLatest() throws -> DisplaySnapshot? {
        let fileManager = FileManager.default
        let directory = try containerURL()
        let fileURL = directory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DisplaySnapshot.self, from: data)
    }
}
