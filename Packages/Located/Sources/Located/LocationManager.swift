import Foundation
import CoreLocation
import Combine

public final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public typealias ManagerConfigurator = (CLLocationManager, CLLocationManagerDelegate) -> Void

    private let manager: CLLocationManager
    private var cancellables = Set<AnyCancellable>()

    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var lastLocation: CLLocation? {
        didSet {
            print(Date(), "§ last location", lastLocation as Any)
        }
    }
    @Published public var recentLocations: [CLLocation] = []
    @Published public var debugLocations: [CLLocation] = []

    public init(manager: CLLocationManager, configureManager: ManagerConfigurator) {
        self.manager = manager
        super.init()
        configureManager(self.manager, self)

        $authorizationStatus
            .sink { _ in }
            .store(in: &cancellables)
    }

    public func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    public func start() {
        manager.startUpdatingLocation()
    }

    public func stop() {
        manager.stopUpdatingLocation()
    }

    public func reset() {
        lastLocation = nil
        recentLocations = []
        debugLocations = []
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.start()
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty else { return }

        print("§", locations)

        for loc in locations {
            debugLocations.append(loc)
            if loc.horizontalAccuracy < 0 || loc.horizontalAccuracy > 50 { continue }
            if loc.timestamp.timeIntervalSinceNow > 5 { continue }
            if loc.speed >= 0 { continue }

            Task { @MainActor in
                self.lastLocation = loc
                self.recentLocations.append(loc)
                let cutoff = Date().addingTimeInterval(-30)
                self.recentLocations.removeAll { $0.timestamp < cutoff }
                if self.recentLocations.count > 200 {
                    self.recentLocations.removeFirst(self.recentLocations.count - 200)
                }
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error)
    }
}
