import SwiftUI
import Foundation
import AppKit
import CoreStats
import DisplaysKit
import WidgetKit

@main
struct SamplerAgentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            VStack {
                Text("LiquidGlass Sampler Agent")
                    .font(.headline)
                Text("Runs in the background to collect system stats and display configurations.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: SamplerController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.prohibited)
        controller = SamplerController()
        Task { await controller?.start() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { await controller?.stop() }
    }
}

actor SamplerController {
    private let statsSampler: StatsSampler
    private let displaysSampler = DisplaysSampler()
    private let statsStore: StatsSnapshotStore
    private let displayStore: DisplaySnapshotStore
    private let defaults: UserDefaults

    private var timerTask: Task<Void, Never>?
    private var currentInterval: TimeInterval

    init() {
        defaults = UserDefaults(suiteName: AppConstants.samplerDefaultsSuite) ?? .standard
        let interval = defaults.double(forKey: AppConstants.samplerIntervalKey)
        currentInterval = interval > 0 ? interval : AppConstants.defaultSampleInterval

        let configuration = StatsSampler.Configuration(sampleInterval: currentInterval,
                                                        historyWindow: AppConstants.historyWindow)
        statsSampler = StatsSampler(configuration: configuration)
        statsStore = StatsSnapshotStore(appGroupIdentifier: AppConstants.appGroupIdentifier,
                                        fileName: AppConstants.statsSnapshotFile)
        displayStore = DisplaySnapshotStore(appGroupIdentifier: AppConstants.appGroupIdentifier,
                                            fileName: AppConstants.displaysSnapshotFile)

        if let snapshot = try? statsStore.readLatest() {
            statsSampler.seed(with: snapshot)
        }
    }

    func start() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.tick()
                let interval = await self.resolveInterval()
                do {
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    break
                }
            }
        }
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func resolveInterval() -> TimeInterval {
        let interval = defaults.double(forKey: AppConstants.samplerIntervalKey)
        if interval > 0, abs(interval - currentInterval) > 0.1 {
            currentInterval = interval
        }
        return currentInterval
    }

    private func tick() async {
        do {
            let stats = try statsSampler.takeSnapshot()
            try statsStore.write(stats)
            WidgetCenter.shared.reloadTimelines(ofKind: AppConstants.statsWidgetKind)
        } catch {
            NSLog("SamplerAgent: stats sampling failed: \(String(describing: error))")
        }

        do {
            let displays = try displaysSampler.captureSnapshot()
            try displayStore.write(displays)
            WidgetCenter.shared.reloadTimelines(ofKind: AppConstants.displaysWidgetKind)
        } catch {
            NSLog("SamplerAgent: display sampling failed: \(String(describing: error))")
        }
    }
}
