import Foundation

struct PortInfo: Identifiable, Hashable, Sendable {
    let id = UUID()
    let port: Int
    let pid: Int
    let processName: String
    let protocolType: String  // TCP/UDP
    let address: String       // 127.0.0.1 or *

    var displayAddress: String {
        if address == "*" {
            return "0.0.0.0"
        }
        return address
    }

    var displayPort: String {
        ":\(port)"
    }
}
