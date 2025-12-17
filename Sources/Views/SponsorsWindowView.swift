import SwiftUI

struct SponsorsWindowView: View {
    @Bindable var sponsorManager: SponsorManager
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                if sponsorManager.sponsors.isEmpty && !sponsorManager.isLoading {
                    emptyState
                } else {
                    sponsorsGrid
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            footer
        }
        .frame(width: 500, height: 450)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundStyle(.pink)

            Text("Thank You, Sponsors!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("PortKiller is made possible by these amazing supporters")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
    }

    // MARK: - Sponsors Grid

    private var sponsorsGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(sponsorManager.sponsors) { sponsor in
                SponsorCard(sponsor: sponsor)
            }
        }
        .padding(24)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            if sponsorManager.error != nil {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("Couldn't load sponsors")
                    .font(.headline)

                Button("Try Again") {
                    Task {
                        await sponsorManager.refreshSponsors()
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("Be the first sponsor!")
                    .font(.headline)

                if let url = URL(string: AppInfo.githubSponsors) {
                    Link("Become a Sponsor", destination: url)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if let url = URL(string: AppInfo.githubSponsors) {
                Link(destination: url) {
                    Label("Become a Sponsor", systemImage: "heart")
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if sponsorManager.isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Button("Close") {
                sponsorManager.markWindowShown()
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }
}

// MARK: - Sponsor Card

struct SponsorCard: View {
    let sponsor: Sponsor
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: sponsor.avatarUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundStyle(.secondary)
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )

            Text(sponsor.displayName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 80)
        .padding(8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if let url = URL(string: "https://github.com/\(sponsor.login)") {
                NSWorkspace.shared.open(url)
            }
        }
        .help("@\(sponsor.login)")
    }
}
