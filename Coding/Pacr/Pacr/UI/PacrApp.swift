//
//  PacrApp.swift
//  Pacr
//
//  Created by Kaspar Elmans on 18/09/2025.
//

import SwiftUI
import CoreLocation
import Combine

@main
struct RunningPaceApp: App {
    @StateObject var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(tracker: Tracker(locationManager: locationManager))
        }
    }
}
