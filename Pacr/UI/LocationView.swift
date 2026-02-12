//
//  LocationView.swift
//  Pacr
//
//  Created by Kaspar Elmans on 06/10/2025.
//

import SwiftUI
import Combine
import CoreLocation
import MapKit
import Located

struct LocationView: View {
    @State var tracker: Tracker
    
    @State private var updateDate: Date?
    @State private var showGPXShare = false
    @State private var paceText: String = "—"
    @State private var distanceText: String = "0 m"
    @State private var timer: AnyCancellable?
    
    @State private var cancellable: AnyCancellable? = nil
    @State private var lastKnownLocationCount: Int = 0
    @State private var now = Date()
    @State private var isTracking = true
    @State private var mapPosition: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tracker")
                            .font(.largeTitle.bold())
                        if let last = tracker.locations.last {
                            lastLocationCard(last: last, updateDate: updateDate)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(isTracking ? Color.red : Color.gray)
                                        .frame(width: 8, height: 8)
                                    Text(isTracking ? "Waiting for location..." : "Tracking stopped")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Metrics Card
                    VStack(spacing: 16) {
                        metricRow(title: "Running Pace", value: paceText, systemImage: "figure.run")
                        Divider()
                        metricRow(title: "Distance", value: distanceText, systemImage: "ruler")
                        Divider()
                        metricRow(title: "Locations", value: "\(tracker.locations.count)", systemImage: "mappin.and.ellipse")
                    }
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Map Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Track Map")
                            .font(.headline)

                        ZStack {
                            Map(position: $mapPosition) {
                                ForEach(Array(tracker.locations.enumerated()), id: \.offset) { _, location in
                                    Annotation("", coordinate: location.coordinate) {
                                        Circle()
                                            .fill(Color.accentColor)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }

                            if tracker.locations.isEmpty {
                                Text("No locations yet")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                        }
                        .frame(height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                bottomControlGrid
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            tracker.start()
            isTracking = true
            updateMapPosition()
        }
        .onAppear {
            // Start a repeating timer that fires every 0.5s
            timer = Timer.publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    tick()
                }
        }
        .sheet(isPresented: $showGPXShare) {
            GPXShareView(
                gpxLocations: tracker.locationManager.recentLocations,
                debugLocations: tracker.locationManager.debugLocations
            )
                .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private func metricRow(title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder 
    private func labeledButtonLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var controlGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
    }

    @ViewBuilder
    private var bottomControlGrid: some View {
        LazyVGrid(columns: controlGridColumns, spacing: 8) {
            if isTracking {
                Button {
                    tracker.stop()
                    isTracking = false
                } label: {
                    compactControlLabel(title: "Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button {
                    tracker.start()
                    isTracking = true
                } label: {
                    compactControlLabel(title: "Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            Button {
                showGPXShare = true
            } label: {
                compactControlLabel(title: "Export", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func compactControlLabel(title: String, systemImage: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 2)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func lastLocationView(last: CLLocation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Location")
                .font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lat: \(formatted(last.coordinate.latitude))  Lon: \(formatted(last.coordinate.longitude))")
                        .font(.subheadline.monospaced())
                    HStack(spacing: 8) {
                        if last.horizontalAccuracy > 0 {
                            badge(text: "±\(Int(last.horizontalAccuracy)) m", systemImage: "scope")
                        }
                        badge(text: last.timestamp.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    }
                }
                Spacer()
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func lastLocationCard(last: CLLocation, updateDate: Date?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Last Location")
                    .font(.headline)
                Spacer(minLength: 0)
                if !isTracking {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                        Text("Stopped")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if let updateDate {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor(for: updateDate))
                            .frame(width: 8, height: 8)
                        Text(relativeTimeString(since: updateDate))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lat: \(formatted(last.coordinate.latitude))  Lon: \(formatted(last.coordinate.longitude))")
                        .font(.subheadline.monospaced())
                    HStack(spacing: 8) {
                        if last.horizontalAccuracy > 0 {
                            badge(text: "±\(Int(last.horizontalAccuracy)) m", systemImage: "scope")
                        }
                        badge(text: timeWithSeconds(last.timestamp), systemImage: "clock")
                    }
                }
                Spacer()
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func badge(text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.secondary.opacity(0.12), in: Capsule())
        .foregroundStyle(.secondary)
    }

    private func formatted(_ value: CLLocationDegrees) -> String {
        String(format: "%.5f", value)
    }
    
    private func timeWithSeconds(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium // includes seconds
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func statusColor(for updateDate: Date?) -> Color {
        // No locations ever received: show red
        if tracker.locations.count == 0 {
            return .red
        }
        // If we have at least one location but no updateDate, treat as stale
        guard let updateDate else {
            return .orange
        }
        // Fresh within 5 seconds: green, otherwise stale (orange)
        return now.timeIntervalSince(updateDate) <= 5 ? .green : .orange
    }
    
    private func relativeTimeString(since date: Date) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h ago" 
    }

    private func tick() {
        now = Date()
        updatePace()
        
        // Only update the last update timestamp when a new location arrives
        let currentCount = tracker.locations.count
        if currentCount != lastKnownLocationCount {
            lastKnownLocationCount = currentCount
            updateDate = Date()
            updateMapPosition()
        }
    }

    private func updateMapPosition() {
        guard let region = mapRegion(for: tracker.locations) else { return }
        mapPosition = .region(region)
    }

    private func mapRegion(for locations: [CLLocation]) -> MKCoordinateRegion? {
        guard !locations.isEmpty else { return nil }

        if locations.count == 1, let location = locations.first {
            return MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }

        let latitudes = locations.map { $0.coordinate.latitude }
        let longitudes = locations.map { $0.coordinate.longitude }

        guard
            let minLat = latitudes.min(),
            let maxLat = latitudes.max(),
            let minLon = longitudes.min(),
            let maxLon = longitudes.max()
        else {
            return nil
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latDelta = max((maxLat - minLat) * 1.5, 0.002)
        let lonDelta = max((maxLon - minLon) * 1.5, 0.002)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    private func updatePace() {
        // Kept for compatibility; tick() handles timestamp updates
        paceText = tracker.pace
        distanceText = String("\(tracker.locations.distance ?? 0)") + " m"
    }
}
