import Foundation
import CoreGraphics
import AppKit

public struct DisplaysSampler: Sendable {
    public enum Error: Swift.Error {
        case unableToQueryDisplays(CGError)
    }

    public init() {}

    public func captureSnapshot() throws -> DisplaySnapshot {
        var displayCount: UInt32 = 0
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        guard result == .success else {
            throw Error.unableToQueryDisplays(result)
        }

        let capacity = Int(displayCount)
        var displayIDs = Array(repeating: CGDirectDisplayID(), count: capacity)
        result = CGGetActiveDisplayList(displayCount, &displayIDs, &displayCount)
        guard result == .success else {
            throw Error.unableToQueryDisplays(result)
        }

        let screensByID: [CGDirectDisplayID: NSScreen] = Dictionary(uniqueKeysWithValues: NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return nil }
            return (CGDirectDisplayID(number.uint32Value), screen)
        })

        let displays: [DisplaySnapshot.Display] = displayIDs.map { id in
            let bounds = CGDisplayBounds(id)
            let pixelWidth = Double(CGDisplayPixelsWide(id))
            let pixelHeight = Double(CGDisplayPixelsHigh(id))
            let screen = screensByID[id]
            let name = screen?.localizedName ?? "Display \(id)"
            let pointWidth = Double(screen?.frame.width ?? bounds.width)
            let pointHeight = Double(screen?.frame.height ?? bounds.height)
            let fallbackScale = pointWidth > 0 ? pixelWidth / pointWidth : 1
            let scale = Double(screen?.backingScaleFactor ?? CGFloat(fallbackScale))
            let mirroredID = CGDisplayMirrorsDisplay(id)
            return DisplaySnapshot.Display(
                id: id,
                name: name,
                isMain: CGDisplayIsMain(id) != 0,
                isBuiltin: CGDisplayIsBuiltin(id) != 0,
                pixelSize: .init(width: pixelWidth, height: pixelHeight),
                pointSize: .init(width: pointWidth, height: pointHeight),
                scale: scale,
                bounds: .init(x: Double(bounds.origin.x),
                               y: Double(bounds.origin.y),
                               width: Double(bounds.width),
                               height: Double(bounds.height)),
                mirroredTo: mirroredID == 0 ? nil : mirroredID
            )
        }

        return DisplaySnapshot(version: DisplaySnapshot.schemaVersion,
                               timestamp: Date(),
                               displays: displays.sorted { $0.id < $1.id })
    }
}
