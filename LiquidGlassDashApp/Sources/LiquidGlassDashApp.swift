import SwiftUI
import CoreStats
import DisplaysKit
import DesignSystem

@main
struct LiquidGlassDashApp: App {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some Scene {
        WindowGroup {
            DashboardView(viewModel: viewModel)
                .frame(minWidth: 640, minHeight: 420)
                .onAppear { viewModel.start() }
                .onDisappear { viewModel.stop() }
        }
        .defaultSize(width: 720, height: 520)
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Open Displays Settings") {
                    DisplaysActions.openSystemDisplays()
                }
                .keyboardShortcut(",", modifiers: [.command, .shift])
            }
        }
    }
}
