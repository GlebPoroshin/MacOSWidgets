import XCTest
@testable import DisplaysKit

final class DisplaySnapshotTests: XCTestCase {
    func testEncodingDecodingRoundtrip() throws {
        let snapshot = DisplaySnapshot(displays: [
            .init(id: 1,
                  name: "Built-in",
                  isMain: true,
                  isBuiltin: true,
                  pixelSize: .init(width: 2880, height: 1800),
                  pointSize: .init(width: 1440, height: 900),
                  scale: 2,
                  bounds: .init(x: 0, y: 0, width: 2880, height: 1800),
                  mirroredTo: nil)
        ])
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(DisplaySnapshot.self, from: data)
        XCTAssertEqual(decoded.displays.first?.id, 1)
        XCTAssertEqual(decoded.displays.first?.name, "Built-in")
    }
}
