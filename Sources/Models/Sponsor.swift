import Foundation
import Defaults

/// Represents a sponsor from static JSON
struct Sponsor: Identifiable, Codable, Sendable, Hashable {
    let name: String
    let login: String
    let avatar: String
    let amount: Int
    let link: String
    let org: Bool

    var id: String { login }

    var displayName: String {
        name.isEmpty ? login : name
    }

    var avatarUrl: String { avatar }
    var profileUrl: URL? { URL(string: link) }
}

/// Cached sponsor data with timestamp
struct SponsorCache: Codable, Defaults.Serializable {
    let sponsors: [Sponsor]
    let fetchedAt: Date

    var isStale: Bool {
        // Cache is stale after 24 hours
        Date().timeIntervalSince(fetchedAt) > 86400
    }
}

/// Sponsor display interval options
enum SponsorDisplayInterval: String, CaseIterable, Codable, Defaults.Serializable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"
    case never = "Never"

    var days: Int? {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .never: return nil
        }
    }

    var localizedName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        case .never: return "Never"
        }
    }
}
