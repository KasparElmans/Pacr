//
//  LocationManager.swift
//  Pacr
//
//  Created by Kaspar Elmans on 06/10/2025.
//

import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation? {
        didSet {
            print(Date(), "§ last location", lastLocation)
        }
    }
    @Published var recentLocations: [CLLocation] = []
    @Published var debugLocations: [CLLocation] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false

        // publish authorization
        $authorizationStatus
            .sink { _ in }
            .store(in: &cancellables)
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }
    
    func reset() {
        lastLocation = nil
        recentLocations = []
        debugLocations = []
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.start()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty else { return }
        
        print("§", locations)
        
        // append only good quality locations
        for loc in locations {
            debugLocations.append(loc)
            // ignore obviously bad fixes
            if loc.horizontalAccuracy < 0 || loc.horizontalAccuracy > 50 { continue }
            // ignore future timestamps
            if loc.timestamp.timeIntervalSinceNow > 5 { continue }
            // Ignore invalid speeds
            if loc.speed >= 0 { continue }

            Task { @MainActor in
                self.lastLocation = loc
                self.recentLocations.append(loc)
                // keep only last 30 seconds of samples (or up to 100 samples)
                let cutoff = Date().addingTimeInterval(-30)
                self.recentLocations.removeAll { $0.timestamp < cutoff }
                if self.recentLocations.count > 200 {
                    self.recentLocations.removeFirst(self.recentLocations.count - 200)
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error)
    }
}
