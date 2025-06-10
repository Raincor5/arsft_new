
// MARK: - PlayerAnnotationView.swift
import SwiftUI
import MapKit

struct PlayerAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let heading: Double
    let callsign: String
    let teamColor: Color
    let isCurrentPlayer: Bool
}

struct PlayerAnnotationView: View {
    let annotation: PlayerAnnotation
    
    var body: some View {
        VStack(spacing: 2) {
            // Direction indicator
            Image(systemName: "arrowtriangle.up.fill")
                .foregroundColor(annotation.teamColor)
                .font(.system(size: annotation.isCurrentPlayer ? 20 : 16))
                .rotationEffect(.degrees(annotation.heading))
                .shadow(color: .black, radius: 2)
            
            // Callsign
            Text(annotation.callsign)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(annotation.teamColor.opacity(0.8))
                )
                .shadow(color: .black, radius: 2)
        }
    }
}
