// MARK: - CompassView.swift
import SwiftUI
import CoreLocation

struct CompassView: View {
    let heading: CLHeading?
    
    var rotation: Double {
        -(heading?.trueHeading ?? 0)
    }
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(Color.black.opacity(0.9))
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                )
            
            // Compass markings
            ForEach(0..<36) { index in
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: index % 9 == 0 ? 2 : 1,
                           height: index % 9 == 0 ? 12 : 8)
                    .offset(y: -30)
                    .rotationEffect(.degrees(Double(index) * 10))
            }
            
            // Cardinal directions
            VStack {
                Text("N")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                    .offset(y: -20)
                Spacer()
            }
            .rotationEffect(.degrees(rotation))
            
            // Center dot
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
        }
        .rotationEffect(.degrees(rotation))
        .animation(.easeInOut(duration: 0.3), value: rotation)
    }
}
