//
//  PacrWatchApp.swift
//  PacrWatch Watch App
//
//  Created by Kaspar Elmans on 12/10/2025.
//

import SwiftUI

@main
struct PacrWatch_Watch_AppApp: App {
    
    @State var value: Double = 0
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: .init(measurement: .init(value: value, unit: .meters)))
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
