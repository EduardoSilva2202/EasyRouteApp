import Foundation

struct RouteStop: Identifiable, Equatable {
    let id: UUID
    var address: String
    var isCompleted: Bool

    init(id: UUID = UUID(), address: String, isCompleted: Bool = false) {
        self.id = id
        self.address = address
        self.isCompleted = isCompleted
    }
}
