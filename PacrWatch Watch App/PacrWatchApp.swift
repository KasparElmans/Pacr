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
    @StateObject var locationManager = {
        let manager = CLLocationManager()
        return LocationManager(manager: manager) { manager, delegate in
            manager.delegate = delegate
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = kCLDistanceFilterNone
            manager.activityType = .fitness
        }
    }()

    @State var value: Double = 0
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: .init(measurement: .init(value: value, unit: .meters)))
                .environmentObject(locationManager)
                .task {
                    let ticks = Timer.publish(every: 1, on: .main, in: .common)
                        .autoconnect()
                        .values
                    for await _ in ticks {
                        value += 1
                    }
                }
        }
    }
}
