//
//  App.swift
//  Pacr
//
//  Created by Kaspar Elmans on 18/09/2025.
//

import SwiftUI
import CoreLocation
import Located

@main
struct RunningPaceApp: App {
    @StateObject var locationManager = {
        let manager = CLLocationManager()
        return LocationManager(manager: manager) { manager, delegate in
            manager.delegate = delegate
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = kCLDistanceFilterNone
            manager.activityType = .fitness
            manager.pausesLocationUpdatesAutomatically = false
            let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
            if backgroundModes?.contains("location") == true {
                manager.allowsBackgroundLocationUpdates = true
                manager.showsBackgroundLocationIndicator = true
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            LocationView(tracker: Tracker(locationManager: locationManager))
        }
    }
}
