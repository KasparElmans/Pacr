//
//  GPXShareView.swift
//  Pacr
//
//  Created by Kaspar Elmans on 07/10/2025.
//

import SwiftUI
import CoreLocation

struct GPXShareView: View {
    @State private var exportURL: URL?
    let locations: [CLLocation]
    let includeDebug: Bool

    var body: some View {
        VStack(spacing: 16) {
            if let url = exportURL {
                ShareLink("Deel GPX-bestand", item: url)
            }

            Button("Genereer GPX") {
                do {
                    exportURL = try GPXWriter.writeGPXFile(from: locations, fileName: includeDebug ? "MyRouteDebug" : "MyRoute", trackName: "My GPX Track")
                } catch {
                    print("❌ GPX export error:", error)
                }
            }
        }
        .padding()
    }
}
