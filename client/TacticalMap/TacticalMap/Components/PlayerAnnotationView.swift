// MARK: - PlayerAnnotationView.swift
import SwiftUI
import MapKit

struct PlayerAnnotationView: View {
    let annotation: PlayerAnnotation
    
    var body: some View {
        ZStack {
            // Pulsing effect for current player
            if annotation.isCurrentPlayer {
                Circle()
                    .fill(annotation.team.swiftUIColor.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .scaleEffect(1.2)
                    .opacity(0.5)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )
            }
            
            // Player direction indicator
            ZStack {
                // Outer arrow
                Image(systemName: "arrowtriangle.up.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(annotation.team.swiftUIColor)
                    .rotationEffect(.degrees(annotation.heading))
                
                // Inner arrow (white)
                Image(systemName: "arrowtriangle.up.fill")
                    .resizable()
                    .frame(width: 12, height: 12)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(annotation.heading))
            }
            
            // Enhanced callsign label
            Text(annotation.player.callsign)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(annotation.team.swiftUIColor)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                )
                .offset(y: -25)
        }
    }
}
