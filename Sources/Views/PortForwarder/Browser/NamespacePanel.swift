import SwiftUI

struct NamespacePanel: View {
    let namespaces: [KubernetesNamespace]
    let selectedNamespace: KubernetesNamespace?
    let state: KubernetesDiscoveryState
    let onSelect: (KubernetesNamespace) -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Namespaces")
                    .font(.headline)
                Spacer()
                Button {
                    onRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .disabled(state == .loading)
            }
            .padding(12)

            Divider()

            if state == .loading {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else if case .error(let msg) = state {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry", action: onRefresh)
                        .buttonStyle(.bordered)
                    Spacer()
                }
                .padding()
            } else {
                List(namespaces, selection: .constant(selectedNamespace?.id)) { ns in
                    Text(ns.name)
                        .font(.system(.body, design: .monospaced))
                        .tag(ns.id)
                        .onTapGesture { onSelect(ns) }
                }
                .listStyle(.plain)
            }
        }
    }
}
