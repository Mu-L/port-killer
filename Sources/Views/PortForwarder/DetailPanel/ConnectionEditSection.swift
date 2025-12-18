import SwiftUI

struct ConnectionEditSection: View {
    @Environment(AppState.self) private var appState
    let connection: PortForwardConnectionState
    @Binding var isExpanded: Bool

    @State private var name: String = ""
    @State private var namespace: String = ""
    @State private var service: String = ""
    @State private var localPort: String = ""
    @State private var remotePort: String = ""
    @State private var proxyPort: String = ""
    @State private var proxyEnabled: Bool = false
    @State private var autoReconnect: Bool = true
    @State private var isEnabled: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with collapse toggle
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .font(.caption)
                        Text("Details")
                            .font(.headline)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if isExpanded {
                VStack(spacing: 12) {
                    // Name
                    LabeledField("Name") {
                        TextField("Connection name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Namespace & Service
                    HStack(spacing: 12) {
                        LabeledField("Namespace") {
                            TextField("default", text: $namespace)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledField("Service") {
                            TextField("service-name", text: $service)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Ports
                    HStack(spacing: 12) {
                        LabeledField("Local Port") {
                            TextField("8080", text: $localPort)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledField("Remote Port") {
                            TextField("80", text: $remotePort)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Proxy
                    HStack(spacing: 12) {
                        Toggle("Proxy", isOn: $proxyEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)

                        if proxyEnabled {
                            LabeledField("Proxy Port") {
                                TextField("8081", text: $proxyPort)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        Spacer()
                    }

                    // Options
                    HStack(spacing: 16) {
                        Toggle("Auto Reconnect", isOn: $autoReconnect)
                            .toggleStyle(.checkbox)
                        Toggle("Enabled", isOn: $isEnabled)
                            .toggleStyle(.checkbox)
                        Spacer()
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .onAppear { loadFromConnection() }
        .onChange(of: connection.id) { loadFromConnection() }
        .onChange(of: name) { saveToConnection() }
        .onChange(of: namespace) { saveToConnection() }
        .onChange(of: service) { saveToConnection() }
        .onChange(of: localPort) { saveToConnection() }
        .onChange(of: remotePort) { saveToConnection() }
        .onChange(of: proxyPort) { saveToConnection() }
        .onChange(of: proxyEnabled) { saveToConnection() }
        .onChange(of: autoReconnect) { saveToConnection() }
        .onChange(of: isEnabled) { saveToConnection() }
    }

    private var statusColor: Color {
        if connection.portForwardStatus == .error || connection.proxyStatus == .error {
            return .red
        } else if connection.isFullyConnected {
            return .green
        } else if connection.portForwardStatus == .connecting || connection.proxyStatus == .connecting {
            return .orange
        }
        return .gray
    }

    private var statusText: String {
        if connection.portForwardStatus == .error || connection.proxyStatus == .error {
            return "Error"
        } else if connection.isFullyConnected {
            return "Connected"
        } else if connection.portForwardStatus == .connecting || connection.proxyStatus == .connecting {
            return "Connecting"
        }
        return "Stopped"
    }

    private func loadFromConnection() {
        name = connection.config.name
        namespace = connection.config.namespace
        service = connection.config.service
        localPort = String(connection.config.localPort)
        remotePort = String(connection.config.remotePort)
        proxyEnabled = connection.config.proxyPort != nil
        proxyPort = connection.config.proxyPort.map { String($0) } ?? ""
        autoReconnect = connection.config.autoReconnect
        isEnabled = connection.config.isEnabled
    }

    private func saveToConnection() {
        let newConfig = PortForwardConnectionConfig(
            id: connection.id,
            name: name,
            namespace: namespace,
            service: service,
            localPort: Int(localPort) ?? connection.config.localPort,
            remotePort: Int(remotePort) ?? connection.config.remotePort,
            proxyPort: proxyEnabled ? Int(proxyPort) : nil,
            isEnabled: isEnabled,
            autoReconnect: autoReconnect,
            useDirectExec: connection.config.useDirectExec
        )
        appState.portForwardManager.updateConnection(newConfig)
    }
}
