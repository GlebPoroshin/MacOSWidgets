import XCTest
@testable import CoreStats

final class StatsFormattersTests: XCTestCase {
    func testMemoryString() {
        let string = StatsFormatters.memoryString(used: 16_200_000_000, total: 18_000_000_000)
        XCTAssertTrue(string.contains("GB"))
        XCTAssertTrue(string.contains("("))
    }
}
