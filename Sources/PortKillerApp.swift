import SwiftUI

@main
struct PortKillerApp: App {
    @State private var manager = PortManager()

    init() {
        // Hide from Dock
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(manager: manager)
        } label: {
            Image(systemName: manager.ports.isEmpty ? "network.slash" : "network")
        }
        .menuBarExtraStyle(.window)
    }
}
