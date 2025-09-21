import AppIntents
import CoreStats

struct ClearStatsHistoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Clear Charts"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = StatsSnapshotStore(appGroupIdentifier: AppConstants.appGroupIdentifier,
                                       fileName: AppConstants.statsSnapshotFile)
        try store.reset()
        return .result(dialog: "History cleared")
    }
}

struct OpenDashboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Dashboard"

    func perform() async throws -> some IntentResult {
        guard let url = URL(string: "liquidglassdash://dashboard") else {
            return .result()
        }
        return .openURL(url)
    }
}
