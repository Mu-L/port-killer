import SwiftUI

struct PortForwarderSidebarContent: View {
    @Environment(AppState.self) private var appState
    @State private var discoveryManager: KubernetesDiscoveryManager?

    var body: some View {
        VStack(spacing: 0) {
            // Header with action buttons
            HStack {
                Text("K8s Port Forward")
                    .font(.headline)

                Spacer()

                Button {
                    let config = PortForwardConnectionConfig(
                        name: "New Connection",
                        namespace: "default",
                        service: "service-name",
                        localPort: 8080,
                        remotePort: 80
                    )
                    appState.portForwardManager.addConnection(config)
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
                .help("Add Connection")

                Button {
                    let dm = KubernetesDiscoveryManager(processManager: appState.portForwardManager.processManager)
                    Task { await dm.loadNamespaces() }
                    discoveryManager = dm
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down.fill")
                }
                .buttonStyle(.bordered)
                .disabled(!DependencyChecker.shared.allRequiredInstalled)
                .help("Import from Kubernetes")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            // Dependency warning banner
            if !DependencyChecker.shared.allRequiredInstalled {
                DependencyWarningBanner()
            }

            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Connection cards
                    ForEach(appState.portForwardManager.connections) { connection in
                        PortForwardConnectionCard(connection: connection)
                    }
                }
                .padding(20)
            }

            Divider()

            // Status bar
            PortForwarderStatusBar()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $discoveryManager) { dm in
            ServiceBrowserView(
                discoveryManager: dm,
                onServiceSelected: { config in
                    appState.portForwardManager.addConnection(config)
                    discoveryManager = nil
                },
                onCancel: {
                    discoveryManager = nil
                }
            )
        }
    }
}

// MARK: - Dependency Warning Banner

struct DependencyWarningBanner: View {
    @State private var isInstalling = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Missing Dependencies")
                    .font(.headline)
                Text("kubectl is required for port forwarding")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isInstalling {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button("Install") {
                    installDependencies()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .overlay(
            Rectangle()
                .fill(Color.orange)
                .frame(height: 2),
            alignment: .top
        )
    }

    private func installDependencies() {
        isInstalling = true
        Task {
            _ = await DependencyChecker.shared.checkAndInstallMissing()
            await MainActor.run { isInstalling = false }
        }
    }
}

// MARK: - Add Connection Buttons

struct AddConnectionButtons: View {
    @Environment(AppState.self) private var appState
    @Binding var discoveryManager: KubernetesDiscoveryManager?

    var body: some View {
        HStack(spacing: 16) {
            // Manual add button
            Button {
                let config = PortForwardConnectionConfig(
                    name: "New Connection",
                    namespace: "default",
                    service: "service-name",
                    localPort: 8080,
                    remotePort: 80
                )
                appState.portForwardManager.addConnection(config)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Connection")
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            // Import from Kubernetes button
            Button {
                let dm = KubernetesDiscoveryManager(processManager: appState.portForwardManager.processManager)
                Task { await dm.loadNamespaces() }
                discoveryManager = dm
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import from Kubernetes")
                }
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .disabled(!DependencyChecker.shared.allRequiredInstalled)
        }
        .padding(.top, 4)
    }
}

// MARK: - Status Bar

struct PortForwarderStatusBar: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            // Connection count
            let manager = appState.portForwardManager
            if manager.connections.isEmpty {
                Text("No connections configured")
            } else {
                Text("\(manager.connectedCount) of \(manager.connections.count) connected")
            }

            Spacer()

            // Start/Stop All buttons
            if !manager.connections.isEmpty {
                Button {
                    manager.startAll()
                } label: {
                    Text("Start All")
                }
                .buttonStyle(.bordered)
                .disabled(manager.allConnected)

                Button {
                    manager.stopAll()
                } label: {
                    Text("Stop All")
                }
                .buttonStyle(.bordered)
                .disabled(manager.connectedCount == 0)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
