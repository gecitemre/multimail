import Foundation

enum SendStatus: Equatable {
    case idle
    case sending
    case paused
    case completed
    case error(String)
}

struct Contact: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let email: String
    var status: DeliveryStatus = .pending
    
    enum DeliveryStatus: Hashable {
        case pending
        case sent
        case failed(String)
    }
}

struct EmailJob: Identifiable {
    let id = UUID()
    let subject: String
    let bodyTemplate: String
    let contacts: [Contact]
}
