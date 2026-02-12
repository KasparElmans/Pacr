//
//  ContentView.swift
//  PacrWatch Watch App
//
//  Created by Kaspar Elmans on 12/10/2025.
//

import SwiftUI
import Located

class ChaserViewModel {
    var measurement: Measurement<UnitLength>
    var scale: Double { measurement.value / 100 }

    var status: Status {
        switch measurement.value {
        case 0...5: .almost
        case ...5: .far
        default: .almost
        }
    }

    init(measurement: Measurement<UnitLength>) {
        self.measurement = measurement
    }

    enum Status {
        case almost, far
    }

    enum Sense {
        case falling, rising
    }
}

struct ContentView: View {
    
    var viewModel: ChaserViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("\"3:46")
                    .foregroundStyle(.cyan)
                    .bold()
                Spacer()
                Text("♥️")
                Text("♥️")
                Text("♥️")
            }
            Spacer()
            HStack {
//                Text(DateComponentsFormatter.secondsAndMinutes.string(from: seconds) ?? "-")
//                Text(" / ")
                Text(MeasurementFormatter.distance.string(from: viewModel.measurement))
            }
            .font(.largeTitle)
            Spacer()
            HStack {
                Spacer()
                Text("🦁")
                    .font(.system(size: 80 * (1 - viewModel.scale)))
//                Capsule()
//                    .frame(height: 4)
                Spacer()
                Text("🏃🏻‍♂️")
                    .flipped()
                    .font(.system(size: max(80 * viewModel.scale, 20)))
                Spacer()
            }
        }
        .fontDesign(.rounded)
    }
}

#Preview {
    ContentView(viewModel: .init(measurement: .init(value: 39, unit: .meters)))
}

struct FlippedModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scaleEffect(x: -1, y: 1)
            // Optionally, flip layout direction back so text alignment isn’t reversed
            .environment(\.layoutDirection, .leftToRight)
    }
}

extension View {
    /// Flips the view horizontally (mirror effect)
    func flipped() -> some View {
        self.modifier(FlippedModifier())
    }
}
