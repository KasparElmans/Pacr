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
    @State private var mode: ExportMode = .gpx
    let gpxLocations: [CLLocation]
    let debugLocations: [CLLocation]

    private enum ExportMode: String, CaseIterable, Identifiable {
        case gpx = "GPX"
        case debug = "Debug"

        var id: String { rawValue }

        var fileName: String {
            switch self {
            case .gpx: return "MyRoute"
            case .debug: return "MyRouteDebug"
            }
        }

        var title: String {
            switch self {
            case .gpx: return "Standard GPX Export"
            case .debug: return "Debug Export (Raw)"
            }
        }

        var subtitle: String {
            switch self {
            case .gpx: return "Filtered route points for sharing and analysis."
            case .debug: return "All debug points, including noisy and rejected updates."
            }
        }

        var tint: Color {
            switch self {
            case .gpx: return .blue
            case .debug: return .orange
            }
        }
    }

    private var selectedLocations: [CLLocation] {
        mode == .gpx ? gpxLocations : debugLocations
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Export Mode", selection: $mode) {
                ForEach(ExportMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 6) {
                Text(mode.title)
                    .font(.headline)
                    .foregroundStyle(mode.tint)
                Text(mode.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("\(selectedLocations.count) points selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if let url = exportURL {
                ShareLink("Share File", item: url)
                    .buttonStyle(.borderedProminent)
            }

            Button("Generate Export") {
                do {
                    exportURL = try GPXWriter.writeGPXFile(
                        from: selectedLocations,
                        fileName: mode.fileName,
                        trackName: mode.title
                    )
                } catch {
                    print("❌ GPX export error:", error)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
