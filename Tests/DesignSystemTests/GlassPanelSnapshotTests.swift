import XCTest
import SwiftUI
@testable import DesignSystem

final class GlassPanelSnapshotTests: XCTestCase {
    @MainActor
    func testGlassPanelRenders() {
        guard #available(macOS 13.0, *) else {
            return
        }
        let view = GlassPanel {
            VStack {
                Text("Metric")
                Text("Value")
            }
        }
        let renderer = ImageRenderer(content: view.frame(width: 200, height: 120))
        renderer.scale = 2
#if os(macOS)
        let image = renderer.nsImage
#else
        let image = renderer.uiImage
#endif
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
    }
}
