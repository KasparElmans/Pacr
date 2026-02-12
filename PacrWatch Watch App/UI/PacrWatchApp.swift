//
//  PacrWatchApp.swift
//  PacrWatch Watch App
//
//  Created by Kaspar Elmans on 12/10/2025.
//

import SwiftUI
import CoreLocation
import Located

@main
struct PacrWatch_Watch_AppApp: App {
    @StateObject private var locationManager: LocationManager
    @State private var tracker: Tracker

    init() {
        let manager = CLLocationManager()
        let locatedManager = LocationManager(manager: manager) { manager, delegate in
            manager.delegate = delegate
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = kCLDistanceFilterNone
            manager.activityType = .fitness
        }

        _locationManager = StateObject(wrappedValue: locatedManager)
        _tracker = State(initialValue: Tracker(locationManager: locatedManager))
    }

    var body: some Scene {
        WindowGroup {
            WatchLocationView(tracker: tracker)
                .environmentObject(locationManager)
        }
    }
}
