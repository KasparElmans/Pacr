//
//  GPXWriter.swift
//  Pacr
//
//  Created by Kaspar Elmans on 07/10/2025.
//

import Foundation
import CoreLocation

enum GPXWriter {
    
    static func writeGPXFile(from locations: [CLLocation], fileName: String = "route", trackName: String = "Track") throws -> URL {
        let data = try makeGPX(from: locations, trackName: trackName)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName).gpx")
        try data.write(to: url, options: .atomic)
        return url
    }
    
    private static func makeGPX(from locations: [CLLocation], trackName: String = "Track") throws -> Data {
        guard !locations.isEmpty else {
            throw NSError(domain: "GPXWriter", code: -1, userInfo: [NSLocalizedDescriptionKey: "No locations provided"])
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        func fmt(_ v: Double) -> String {
            var s = String(format: "%.6f", v)
            if s.contains(",") { s = s.replacingOccurrences(of: ",", with: ".") }
            return s
        }
        
        var xml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <gpx version="1.1" creator="YourApp"
                xmlns="http://www.topografix.com/GPX/1/1">
                <metadata>
                <name>\(trackName)</name>
                <time>\(iso.string(from: locations.first!.timestamp))</time>
                </metadata>
                <trk>
                <name>\(trackName)</name>
                <trkseg>
                """
        
        for loc in locations {
            xml += """
                <trkpt lat="\(fmt(loc.coordinate.latitude))" lon="\(fmt(loc.coordinate.longitude))">
                  <ele>\(fmt(loc.altitude))</ele>
                  <time>\(iso.string(from: loc.timestamp))</time>
                </trkpt>
                """
        }
        
        xml += """
                </trkseg>
                </trk>
                </gpx>
                """

        guard let data = xml.data(using: .utf8) else {
            throw NSError(domain: "GPXWriter", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "UTF-8 encoding failed"])
        }
        return data
    }
}
