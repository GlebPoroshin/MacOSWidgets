import Foundation
import CoreStats
import DisplaysKit
import ServiceManagement
import AppKit

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var stats: StatsSnapshot?
    @Published var displays: DisplaySnapshot?
    @Published var samplerInterval: TimeInterval
    @Published var loginItemEnabled: Bool

    private let statsStore = StatsSnapshotStore(appGroupIdentifier: AppConstants.appGroupIdentifier,
                                                fileName: AppConstants.statsSnapshotFile)
    private let displaysStore = DisplaySnapshotStore(appGroupIdentifier: AppConstants.appGroupIdentifier,
                                                     fileName: AppConstants.displaysSnapshotFile)
    private let defaults: UserDefaults
    private var refreshTask: Task<Void, Never>?

    init() {
        defaults = UserDefaults(suiteName: AppConstants.samplerDefaultsSuite) ?? .standard
        let interval = defaults.double(forKey: AppConstants.samplerIntervalKey)
        samplerInterval = interval > 0 ? interval : AppConstants.defaultSampleInterval
        loginItemEnabled = SMAppService.loginItem(identifier: AppConstants.loginItemIdentifier).status == .enabled

        stats = try? statsStore.readLatest()
        displays = try? displaysStore.readLatest()
    }

    func start() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                self.refresh()
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() {
        stats = try? statsStore.readLatest()
        displays = try? displaysStore.readLatest()
        let interval = defaults.double(forKey: AppConstants.samplerIntervalKey)
        if interval > 0, abs(interval - samplerInterval) > 0.1 {
            samplerInterval = interval
        }
    }

    func setSamplerInterval(_ interval: TimeInterval) {
        samplerInterval = interval
        defaults.set(interval, forKey: AppConstants.samplerIntervalKey)
    }

    func toggleLoginItem(_ enabled: Bool) async {
        let previous = loginItemEnabled
        loginItemEnabled = enabled
        do {
            let service = SMAppService.loginItem(identifier: AppConstants.loginItemIdentifier)
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.alertStyle = .warning
            alert.runModal()
            loginItemEnabled = previous
        }
    }
}
