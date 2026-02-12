//
//  ContetView.swift
//  Pacr
//
//  Created by Kaspar Elmans on 06/10/2025.
//

import SwiftUI
import Combine
import CoreLocation
import Located

struct ContentView: View {
    @State var tracker: Tracker
    
    @State private var updateDate: Date?
    @State private var showGPXShare = false
    @State var includeDebug = false
    @State private var paceText: String = "—"
    @State private var distanceText: String = "0.0 m"
    @State private var timer: AnyCancellable?
    
    @State private var cancellable: AnyCancellable? = nil
    @State private var lastKnownLocationCount: Int = 0
    @State private var now = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pacr")
                            .font(.largeTitle.bold())
                        if let last = tracker.locations.last {
                            lastLocationCard(last: last, updateDate: updateDate)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("Waiting for location…")
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
                    
                    Text("Controls")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    // Controls
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button {
                                tracker.start()
                            } label: {
                                labeledButtonLabel(title: "Start", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)

                            Button {
                                tracker.stop()
                            } label: {
                                labeledButtonLabel(title: "Stop", systemImage: "stop.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)

                            Button {
                                tracker.reset()
                            } label: {
                                labeledButtonLabel(title: "Reset", systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(.bordered)
                        }

                        HStack(spacing: 12) {
                            Button {
                                includeDebug = false
                                showGPXShare = true
                            } label: {
                                labeledButtonLabel(title: "Export GPX", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                includeDebug = true
                                showGPXShare = true
                            } label: {
                                labeledButtonLabel(title: "Export Debug", systemImage: "ladybug.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear(perform: tracker.start)
        .onAppear {
            // Start a repeating timer that fires every 0.5s
            timer = Timer.publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    tick()
                }
        }
        .sheet(isPresented: $showGPXShare) {
            let locations = includeDebug ? tracker.locationManager.debugLocations : tracker.locationManager.recentLocations
            GPXShareView(locations: locations, includeDebug: includeDebug)
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
                if let updateDate {
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
        // Update metrics every tick
        paceText = tracker.pace
        distanceText = String("\(tracker.locations.distance ?? 0)") + " m"

        // Only update the last update timestamp when a new location arrives
        let currentCount = tracker.locations.count
        if currentCount != lastKnownLocationCount {
            lastKnownLocationCount = currentCount
            updateDate = Date()
        }
    }

    private func updatePace() {
        // Kept for compatibility; tick() handles timestamp updates
        paceText = tracker.pace
        distanceText = String("\(tracker.locations.distance ?? 0)") + " m"
    }
}
