import SwiftUI

struct MenuBarView: View {
    @Bindable var manager: PortManager
    @State private var hoveredPort: UUID?
    @State private var searchText = ""

    private var filteredPorts: [PortInfo] {
        if searchText.isEmpty {
            return manager.ports
        }
        return manager.ports.filter {
            String($0.port).contains(searchText) ||
            $0.processName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchBar
            Divider()
            portsList
            Divider()
            actionsBar
            Divider()
            footer
        }
        .frame(width: 320)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "network")
                .foregroundStyle(.blue)
            Text("PortKiller")
                .font(.headline)

            Spacer()

            if manager.isScanning {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Button {
                    Task { await manager.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Refresh")
            }

            Text("\(manager.ports.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.tertiary.opacity(0.3))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search port or process...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Ports List

    private var portsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filteredPorts.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredPorts) { port in
                        PortRow(
                            port: port,
                            isHovered: hoveredPort == port.id,
                            onKill: {
                                Task { await manager.killPort(port) }
                            }
                        )
                        .onHover { hovering in
                            hoveredPort = hovering ? port.id : nil
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 300)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("No open ports")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Actions Bar

    private var actionsBar: some View {
        HStack(spacing: 12) {
            ActionButton(
                title: "Refresh",
                icon: "arrow.clockwise",
                action: { Task { await manager.refresh() } }
            )

            ActionButton(
                title: "Kill All",
                icon: "xmark.circle",
                isDestructive: true,
                action: { Task { await manager.killAll() } }
            )
            .disabled(manager.ports.isEmpty)

            Spacer()

            Button {
                // Settings will be added later
            } label: {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footer: some View {
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Port Row

struct PortRow: View {
    let port: PortInfo
    let isHovered: Bool
    let onKill: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
                .shadow(color: .green.opacity(0.5), radius: 3)

            // Port number
            Text(port.displayPort)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)

            // Process name
            Text(port.processName)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            // PID
            Text("PID \(port.pid)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Kill button (visible on hover)
            Button {
                onKill()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.callout)
            .foregroundStyle(isDestructive ? .red : .primary)
        }
        .buttonStyle(.plain)
    }
}
