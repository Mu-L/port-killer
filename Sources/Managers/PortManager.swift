import Foundation
import SwiftUI

@Observable
@MainActor
final class PortManager {
    var ports: [PortInfo] = []
    var isScanning = false

    private let scanner = PortScanner()
    private var refreshTask: Task<Void, Never>?
    private var autoRefreshEnabled = true
    private let refreshInterval: TimeInterval = 5.0

    init() {
        startAutoRefresh()
    }

    func refresh() async {
        guard !isScanning else { return }
        isScanning = true
        defer { isScanning = false }

        let scannedPorts = await scanner.scanPorts()
        ports = scannedPorts
    }

    func killPort(_ port: PortInfo) async {
        let success = await scanner.killProcessGracefully(pid: port.pid)
        if success {
            // Remove from list immediately
            ports.removeAll { $0.id == port.id }
            // Refresh to confirm
            await refresh()
        }
    }

    func killAll() async {
        for port in ports {
            _ = await scanner.killProcessGracefully(pid: port.pid)
        }
        ports.removeAll()
        await refresh()
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        stopAutoRefresh()
        autoRefreshEnabled = true

        refreshTask = Task {
            // Initial scan
            await refresh()

            while !Task.isCancelled && autoRefreshEnabled {
                try? await Task.sleep(for: .seconds(refreshInterval))
                if !Task.isCancelled && autoRefreshEnabled {
                    await refresh()
                }
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshEnabled = false
        refreshTask?.cancel()
        refreshTask = nil
    }
}
