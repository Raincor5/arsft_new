
// MARK: - MapView.swift
import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var stateManager: StateManager
    @StateObject private var mapViewModel = MapViewModel()
    @State private var showChat = false
    @State private var showTeams = false
    @State private var showAlertMenu = false
    @State private var showMarkerCreation = false
    @State private var mapType: MKMapType = .hybrid
    
    var body: some View {
        ZStack {
            // Map
            MapViewRepresentable(
                region: $mapViewModel.region,
                mapType: mapType,
                annotations: mapViewModel.annotations,
                overlays: mapViewModel.overlays
            )
            .ignoresSafeArea()
            
            // Compass
            CompassView(heading: mapViewModel.heading)
                .frame(width: 80, height: 80)
                .position(x: 60, y: 100)
            
            // Control Buttons
            VStack {
                // Top bar
                HStack {
                    // Session info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stateManager.currentPlayer?.callsign ?? "Unknown")
                            .font(TacticalFonts.caption)
                            .foregroundColor(TacticalColors.primary)
                        
                        Text(stateManager.currentTeam?.name ?? "No Team")
                            .font(TacticalFonts.caption)
                            .foregroundColor(stateManager.currentTeam?.swiftUIColor ?? TacticalColors.primary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(TacticalColors.surface.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(TacticalColors.primary, lineWidth: 1)
                            )
                    )
                    
                    Spacer()
                    
                    // Connection status
                    HStack(spacing: 5) {
                        Circle()
                            .fill(WebSocketService.shared.connectionState == .connected ?
                                  TacticalColors.primary : TacticalColors.danger)
                            .frame(width: 8, height: 8)
                        
                        Text(WebSocketService.shared.connectionState == .connected ?
                             "ONLINE" : "OFFLINE")
                            .font(TacticalFonts.caption)
                            .foregroundColor(TacticalColors.primary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(TacticalColors.surface.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(TacticalColors.primary, lineWidth: 1)
                            )
                    )
                }
                .padding()
                
                Spacer()
                
                // Bottom control panel
                HStack(spacing: 15) {
                    // Teams
                    MapControlButton(
                        icon: "person.3.fill",
                        label: "TEAMS",
                        action: { showTeams = true }
                    )
                    
                    // Alerts
                    MapControlButton(
                        icon: "exclamationmark.triangle.fill",
                        label: "ALERT",
                        color: TacticalColors.warning,
                        action: { showAlertMenu = true }
                    )
                    
                    // Markers
                    MapControlButton(
                        icon: "mappin.circle.fill",
                        label: "MARK",
                        action: { showMarkerCreation = true }
                    )
                    
                    // Center
                    MapControlButton(
                        icon: "location.fill",
                        label: "CENTER",
                        action: { mapViewModel.centerOnUser() }
                    )
                    
                    // Chat
                    MapControlButton(
                        icon: "message.fill",
                        label: "CHAT",
                        badge: mapViewModel.unreadMessages,
                        action: { showChat = true }
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(TacticalColors.surface.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(TacticalColors.primary, lineWidth: 1)
                        )
                )
                .padding()
            }
        }
        .sheet(isPresented: $showChat) {
            ChatView()
                .environmentObject(stateManager)
        }
        .sheet(isPresented: $showTeams) {
            TeamView()
                .environmentObject(stateManager)
        }
        .sheet(isPresented: $showAlertMenu) {
            AlertMenuView()
                .environmentObject(stateManager)
        }
        .sheet(isPresented: $showMarkerCreation) {
            MarkerCreationView()
                .environmentObject(stateManager)
        }
        .onAppear {
            mapViewModel.setup(with: stateManager)
        }
    }
}
