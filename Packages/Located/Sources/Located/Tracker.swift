import Foundation
import CoreLocation
import Combine

public final class Tracker {
    public let locationManager: LocationManager
    private var cancellable: AnyCancellable?

    private let maxCount: Int = 200
    private let maxAge: TimeInterval = 200

    public var locations: [CLLocation] = []

    public init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }

    public func start() {
        locationManager.requestAuthorization()
        // Ensure location updates resume after a previous stop/reset cycle.
        locationManager.start()
        cancellable = locationManager.$debugLocations
            .map { [maxCount, maxAge] all -> [CLLocation] in
                var locations = Array(all.suffix(maxCount))

                let cutoff = Date().addingTimeInterval(-maxAge)
                locations.removeAll { $0.timestamp < cutoff }

                return locations
            }
            .sink { [weak self] window in
                self?.locations = window
            }
    }

    public func stop() {
        locationManager.stop()
        locationManager.reset()
    }

    public func reset() {
        locationManager.reset()
    }

    public var pace: String {
        if let pace = locations.pace(windowSeconds: 12) {
            return formatPace(minPerKm: pace)
        }
        return "--:-- /km"
    }
}
