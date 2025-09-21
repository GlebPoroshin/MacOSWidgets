import XCTest
@testable import CoreStats

final class StatsHistoryBufferTests: XCTestCase {
    func testBufferKeepsMostRecentValues() {
        var buffer = StatsHistoryBuffer<Double>(capacity: 5)
        (0..<10).forEach { buffer.append(Double($0)) }
        XCTAssertEqual(buffer.valuesOldestFirst(), [5, 6, 7, 8, 9])
        XCTAssertEqual(buffer.valuesNewestFirst(), [9, 8, 7, 6, 5])
    }

    func testAppendBeforeCapacity() {
        var buffer = StatsHistoryBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        XCTAssertEqual(buffer.valuesOldestFirst(), [1, 2])
        XCTAssertEqual(buffer.count, 2)
    }
}
