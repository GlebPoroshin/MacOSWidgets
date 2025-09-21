import AppIntents

struct OpenDisplaysSettingsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Displays"

    func perform() async throws -> some IntentResult {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") else {
            return .result()
        }
        return .openURL(url)
    }
}

struct ToggleMirroringIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Mirroring"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        #if NON_MAS
        // Placeholder for optional displayplacer integration
        return .result(dialog: "Mirroring control requires displayplacer integration.")
        #else
        return .result(dialog: "Adjust mirroring from System Settings → Displays.")
        #endif
    }
}

struct SetPrimaryDisplayIntent: AppIntent {
    static var title: LocalizedStringResource = "Set as Primary"

    @Parameter(title: "Display ID")
    var displayID: Int

    init() {}

    init(displayID: Int) {
        self._displayID = .init(value: displayID)
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
#if NON_MAS
        return .result(dialog: "Use displayplacer for automation in NON_MAS builds.")
#else
        return .result(dialog: "Select display #\(displayID) in System Settings → Displays and set it as primary.")
        #endif
    }
}
