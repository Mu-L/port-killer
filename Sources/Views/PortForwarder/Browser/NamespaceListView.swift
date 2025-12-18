import SwiftUI

struct NamespaceListView: View {
    let namespaces: [KubernetesNamespace]
    let selectedNamespace: KubernetesNamespace?
    let state: KubernetesDiscoveryState
    let onSelect: (KubernetesNamespace) -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Namespaces")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    onRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(state == .loading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()

            Group {
                switch state {
                case .loading:
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                case .error(let message):
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        Button("Retry") {
                            onRefresh()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        Spacer()
                    }

                case .idle, .loaded:
                    if namespaces.isEmpty && state == .loaded {
                        VStack {
                            Spacer()
                            Text("No namespaces")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 1) {
                                ForEach(namespaces) { namespace in
                                    NamespaceRow(
                                        namespace: namespace,
                                        isSelected: selectedNamespace?.id == namespace.id,
                                        onSelect: onSelect
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .background(Color.primary.opacity(0.02))
    }
}

struct NamespaceRow: View {
    let namespace: KubernetesNamespace
    let isSelected: Bool
    let onSelect: (KubernetesNamespace) -> Void

    var body: some View {
        Button {
            onSelect(namespace)
        } label: {
            HStack {
                Image(systemName: "folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(namespace.name)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
