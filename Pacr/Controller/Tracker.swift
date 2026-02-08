//
//  File.swift
//  Pacr
//
//  Created by Kaspar Elmans on 07/10/2025.
//

import CoreLocation
import Combine

class Tracker {
    let locationManager: LocationManager
    private var cancellable: AnyCancellable?
    
    private let maxCount: Int = 200
    private let maxAge: TimeInterval = 200
    
    /// Window locations
    var locations: [CLLocation] = []
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    func start() {
        locationManager.requestAuthorization()
        cancellable = locationManager.$debugLocations
            .map { [maxCount, maxAge] all -> [CLLocation] in
                var locations = Array(all.suffix(maxCount))
                
                let cutoff = Date().addingTimeInterval(-maxAge)
                locations.removeAll { $0.timestamp < cutoff }
                
                return locations
            }
            .sink { [weak self] w in
                self?.locations = w
            }
    }
    
    func stop() {
        locationManager.stop()
        locationManager.reset()
    }
    
    func reset() {
        locationManager.reset()
    }
    
    var pace: String {
        // Suppose `locations` is your rolling buffer (newest last)
        if let pace = locations.pace(windowSeconds: 12) {
            return formatPace(minPerKm: pace)  // e.g. "04:45 /km"
        } else {
            return "--:-- /km"
        }
    }
}
