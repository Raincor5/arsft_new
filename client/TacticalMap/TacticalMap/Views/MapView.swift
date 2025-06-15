// MARK: - MapView.swift
import SwiftUI
import MapKit
import UIKit

struct MapView: View {
    @EnvironmentObject var stateManager: StateManager
    @StateObject private var mapViewModel = MapViewModel()
    @State private var showChat = false
    @State private var showTeams = false
    @State private var showAlertMenu = false
    @State private var showMarkerCreation = false
    @State private var mapType: MKMapType = .mutedStandard
    @State private var showingTeamManagement = false
    
    var body: some View {
        ZStack {
            // Map with enhanced dark theme
            MapViewRepresentable(
                region: $mapViewModel.region,
                mapType: mapType,
                annotations: mapViewModel.annotations,
                overlays: mapViewModel.overlays
            )
            .ignoresSafeArea()
            .onAppear {
                // Ensure proper map styling for dark theme
                UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
                // Initialize MapViewModel with StateManager
                mapViewModel.setup(with: stateManager)
            }
            
            // Dark overlay for better contrast
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.3), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(height: 200)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // Enhanced Compass with glow effect
            CompassView(heading: mapViewModel.heading)
                .frame(width: 90, height: 90)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [TacticalColors.primary, TacticalColors.primary.opacity(0.6)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: TacticalColors.primary.opacity(0.5), radius: 10)
                )
                .position(x: 70, y: 120)
            
            VStack {
                // Enhanced Top Status Bar
                HStack {
                    // Player & Session Info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .foregroundColor(TacticalColors.primary)
                                .font(.system(size: 14))
                            
                            Text(stateManager.currentPlayer?.callsign ?? "Unknown")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(stateManager.currentTeam?.swiftUIColor ?? TacticalColors.primary)
                                .frame(width: 12, height: 12)
                                .shadow(color: stateManager.currentTeam?.swiftUIColor ?? TacticalColors.primary, radius: 3)
                            
                            Text(stateManager.currentTeam?.name ?? "No Team")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(stateManager.currentTeam?.swiftUIColor ?? TacticalColors.primary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [TacticalColors.primary, TacticalColors.primary.opacity(0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: TacticalColors.primary.opacity(0.3), radius: 8)
                    )
                    
                    Spacer()
                    
                    // Connection Status & Map Type
                    VStack(spacing: 6) {
                        // Connection indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(WebSocketService.shared.connectionState == .connected ?
                                      TacticalColors.primary : TacticalColors.danger)
                                .frame(width: 10, height: 10)
                                .shadow(color: WebSocketService.shared.connectionState == .connected ?
                                        TacticalColors.primary : TacticalColors.danger, radius: 4)
                            
                            Text(WebSocketService.shared.connectionState == .connected ?
                                 "ONLINE" : "OFFLINE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(WebSocketService.shared.connectionState == .connected ?
                                               TacticalColors.primary : TacticalColors.danger)
                        }
                        
                        // Map type toggle
                        Button(action: toggleMapType) {
                            HStack(spacing: 4) {
                                Image(systemName: mapType == .mutedStandard ? "map" : "globe.americas")
                                    .font(.system(size: 12))
                                Text(mapType == .mutedStandard ? "DARK" : "SAT")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            }
                            .foregroundColor(TacticalColors.primary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(TacticalColors.primary.opacity(0.6), lineWidth: 1)
                            )
                            .shadow(color: TacticalColors.primary.opacity(0.3), radius: 6)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Enhanced Bottom Control Panel
                HStack(spacing: 18) {
                    // Teams - Enhanced for host
                    if stateManager.isHost {
                        EnhancedMapControlButton(
                            icon: "person.3.fill",
                            label: "TEAMS",
                            color: TacticalColors.warning,
                            showBadge: true,
                            action: { showingTeamManagement = true }
                        )
                    } else {
                        EnhancedMapControlButton(
                            icon: "person.3.fill",
                            label: "TEAMS",
                            action: { showTeams = true }
                        )
                    }
                    
                    // Alerts
                    EnhancedMapControlButton(
                        icon: "exclamationmark.triangle.fill",
                        label: "ALERT",
                        color: TacticalColors.danger,
                        pulseAnimation: true,
                        action: { showAlertMenu = true }
                    )
                    
                    // Markers
                    EnhancedMapControlButton(
                        icon: "mappin.circle.fill",
                        label: "MARK",
                        color: TacticalColors.warning,
                        action: { showMarkerCreation = true }
                    )
                    
                    // Center
                    EnhancedMapControlButton(
                        icon: "location.fill",
                        label: "CENTER",
                        action: { mapViewModel.centerOnUser() }
                    )
                    
                    // Chat
                    EnhancedMapControlButton(
                        icon: "message.fill",
                        label: "CHAT",
                        badge: mapViewModel.unreadMessages,
                        action: { showChat = true }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            TacticalColors.primary.opacity(0.8),
                                            TacticalColors.primary.opacity(0.3),
                                            TacticalColors.primary.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: TacticalColors.primary.opacity(0.3), radius: 12, x: 0, y: -4)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showChat) {
            ChatView()
                .environmentObject(stateManager)
        }
        .sheet(isPresented: $showTeams) {
            TeamView()
                .environmentObject(stateManager)
        }
        .sheet(isPresented: $showingTeamManagement) {
            TeamManagementView()
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
        .onChange(of: stateManager.players.count) { _ in
            // Update annotations when players change
            mapViewModel.updateAnnotations()
        }
    }
    
    private func toggleMapType() {
        withAnimation(.easeInOut(duration: 0.3)) {
            mapType = mapType == .mutedStandard ? .hybridFlyover : .mutedStandard
        }
        HapticFeedback.impact(.light)
    }
}

// Enhanced Map Control Button
struct EnhancedMapControlButton: View {
    let icon: String
    let label: String
    var color: Color = TacticalColors.primary
    var badge: Int = 0
    var showBadge: Bool = false
    var pulseAnimation: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var pulseOpacity: Double = 1.0
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.medium)
            action()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    // Pulse effect for alerts
                    if pulseAnimation {
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .scaleEffect(pulseOpacity)
                            .opacity(2 - pulseOpacity)
                            .onAppear {
                                withAnimation(
                                    Animation.easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true)
                                ) {
                                    pulseOpacity = 1.5
                                }
                            }
                    }
                    
                    // Main button background
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(isPressed ? 0.8 : 0.4),
                                    color.opacity(isPressed ? 0.4 : 0.1)
                                ]),
                                center: .center,
                                startRadius: 5,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(color, lineWidth: 2)
                        )
                        .shadow(color: color.opacity(0.5), radius: isPressed ? 3 : 8)
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                    
                    // Badge
                    if badge > 0 || showBadge {
                        VStack {
                            HStack {
                                Spacer()
                                
                                if badge > 0 {
                                    Text("\(badge)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Circle().fill(TacticalColors.danger))
                                        .shadow(color: TacticalColors.danger, radius: 3)
                                } else if showBadge {
                                    Circle()
                                        .fill(TacticalColors.warning)
                                        .frame(width: 12, height: 12)
                                        .shadow(color: TacticalColors.warning, radius: 3)
                                }
                            }
                            Spacer()
                        }
                        .frame(width: 50, height: 50)
                    }
                }
                
                // Label
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                    .shadow(color: .black, radius: 1)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}