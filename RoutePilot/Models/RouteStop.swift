import CoreLocation
import Foundation

struct RouteStop: Identifiable, Equatable {
    let id: UUID
    var address: String
    var latitude: Double?
    var longitude: Double?
    var uprn: String?
    var udprn: String?
    var coordinateAccuracy: String
    var isCompleted: Bool

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        address: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        uprn: String? = nil,
        udprn: String? = nil,
        coordinateAccuracy: String = "unavailable",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.uprn = uprn
        self.udprn = udprn
        self.coordinateAccuracy = coordinateAccuracy
        self.isCompleted = isCompleted
    }
}
