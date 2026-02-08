//
//  Extensions.swift
//  Pacr
//
//  Created by Kaspar Elmans on 07/10/2025.
//

import CoreLocation

extension CLLocation {
    /// Returns pace in **minutes per kilometer**, or `nil` if speed is invalid.
    var paceMinutesPerKilometer: Double? {
        // convert seconds/km → min/km
        (1000 / speed) / 60.0
    }
}

// MARK: - Pace helpers

extension Array where Element == CLLocation {
    /// Smoothed current pace in **minutes per kilometer** computed over the last `windowSeconds`.
    /// Returns `nil` if there isn't enough movement or data.
    func pace(windowSeconds: TimeInterval = 15) -> Double? {
        guard let last = self.last else { return nil }
        
        // 1) Window recent samples
        let filtered = self.filter { last.timestamp.timeIntervalSince($0.timestamp) <= windowSeconds }
        guard filtered.count >= 2 else { return nil }
        
        // 3) Accumulate distance & time over the polyline inside the window
        var distance: CLLocationDistance = 0
        for i in 1..<filtered.count {
            distance += filtered[i].distance(from: filtered[i-1])
        }
        let duration = filtered.last!.timestamp.timeIntervalSince(filtered.first!.timestamp)
        guard distance > 0, duration > 0 else { return nil }
        
        // 4) Convert to minutes/km
        let secondsPerKm = duration / (distance / 1_000.0)
        return secondsPerKm / 60.0
    }
}

// MARK: - Formatting

/// Formats a pace (minutes per km) as "mm:ss /km". `nil` → "--:-- /km".
func formatPace(minPerKm: Double?) -> String {
    guard let p = minPerKm, p.isFinite else { return "--:-- /km" }
    let minutes = Int(p)
    let seconds = Int((p - Double(minutes)) * 60.0)
    return String(format: "%02d:%02d /km", minutes, seconds)
}

extension Array where Element == CLLocation {
    
    var distance: CLLocationDistance? {
        guard !isEmpty else { return nil }
        
        var distance: CLLocationDistance = 0
        for i in 1..<count {
            distance += self[i].distance(from: self[i-1])
        }
        return distance
    }
}
