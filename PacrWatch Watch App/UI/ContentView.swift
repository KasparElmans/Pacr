//
//  ContentView.swift
//  PacrWatch Watch App
//
//  Created by Kaspar Elmans on 12/10/2025.
//

import SwiftUI
import Combine
import CoreLocation
import Located

struct ContentView: View {
    @State var tracker: Tracker

    @State private var updateDate: Date?
    @State private var paceText: String = "--:-- /km"
    @State private var distanceText: String = "0 m"
    @State private var timer: AnyCancellable?
    @State private var lastKnownLocationCount: Int = 0
    @State private var now = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pacr")
                        .font(.title3.bold())

                    if let last = tracker.locations.last {
                        lastLocationCard(last: last, updateDate: updateDate)
                    } else {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Waiting for location...")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    metricRow(title: "Pace", value: paceText, systemImage: "figure.run")
                    Divider()
                    metricRow(title: "Distance", value: distanceText, systemImage: "ruler")
                    Divider()
                    metricRow(title: "Locations", value: "\(tracker.locations.count)", systemImage: "mappin.and.ellipse")
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button {
                            tracker.start()
                        } label: {
                            Image(systemName: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.green)

                        Button {
                            tracker.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.red)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        tracker.reset()
                        updateDate = nil
                        lastKnownLocationCount = 0
                        tick()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .onAppear(perform: tracker.start)
        .onAppear {
            timer = Timer.publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    tick()
                }
        }
        .onDisappear {
            timer?.cancel()
            timer = nil
        }
    }

    @ViewBuilder
    private func metricRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(.accentColor)
                .frame(width: 18)
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(value)
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    @ViewBuilder
    private func lastLocationCard(last: CLLocation, updateDate: Date?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Last Location")
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 0)
                if let updateDate {
                    Circle()
                        .fill(statusColor(for: updateDate))
                        .frame(width: 7, height: 7)
                    Text(relativeTimeString(since: updateDate))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Lat \(formatted(last.coordinate.latitude))")
                Text("Lon \(formatted(last.coordinate.longitude))")
            }
            .font(.caption2.monospaced())
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            HStack(spacing: 6) {
                if last.horizontalAccuracy > 0 {
                    badge(text: "±\(Int(last.horizontalAccuracy))m", systemImage: "scope")
                }
                badge(text: timeWithSeconds(last.timestamp), systemImage: "clock")
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func badge(text: String, systemImage: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption2.weight(.semibold))
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(Color.secondary.opacity(0.15), in: Capsule())
        .foregroundStyle(.secondary)
    }

    private func formatted(_ value: CLLocationDegrees) -> String {
        String(format: "%.5f", value)
    }

    private func timeWithSeconds(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private func statusColor(for updateDate: Date?) -> Color {
        if tracker.locations.isEmpty {
            return .red
        }
        guard let updateDate else {
            return .orange
        }
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
        paceText = tracker.pace
        distanceText = "\(Int((tracker.locations.distance ?? 0).rounded())) m"

        let currentCount = tracker.locations.count
        if currentCount != lastKnownLocationCount {
            lastKnownLocationCount = currentCount
            updateDate = Date()
        }
    }
}

#Preview {
    ContentView(
        tracker: Tracker(
            locationManager: LocationManager(manager: CLLocationManager()) { manager, delegate in
                manager.delegate = delegate
                manager.desiredAccuracy = kCLLocationAccuracyBest
                manager.distanceFilter = kCLDistanceFilterNone
                manager.activityType = .fitness
            }
        )
    )
}
