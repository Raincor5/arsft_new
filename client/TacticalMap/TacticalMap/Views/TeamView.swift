// MARK: - TeamView.swift
import SwiftUI

struct TeamView: View {
    @EnvironmentObject var stateManager: StateManager
    @Environment(\.dismiss) private var dismiss
    
    private var teamName: String {
        stateManager.currentTeam?.name ?? "NO TEAM"
    }
    
    private var teamPlayers: [String] {
        Array(stateManager.currentTeam?.players ?? [])
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Team name
                    Text(teamName)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    // Team members
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(teamPlayers, id: \.self) { playerId in
                                if let player = stateManager.players[playerId] {
                                    PlayerRow(player: player, teamColor: .blue)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("TEAM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct TeamSection: View {
    let team: Team
    @EnvironmentObject var stateManager: StateManager
    
    var teamPlayers: [Player] {
        stateManager.getTeamPlayers(for: team.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Team header
            HStack {
                Text(team.name.uppercased())
                    .font(TacticalTheme.Fonts.heading)
                    .foregroundColor(team.swiftUIColor)
                
                Spacer()
                
                Text("\(teamPlayers.count) PLAYERS")
                    .font(TacticalTheme.Fonts.caption)
                    .foregroundColor(TacticalTheme.Colors.primary)
            }
            
            // Players
            VStack(spacing: 8) {
                ForEach(teamPlayers) { player in
                    PlayerRow(player: player, teamColor: team.swiftUIColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(TacticalTheme.Colors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(team.swiftUIColor.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
}

struct PlayerRow: View {
    let player: Player
    let teamColor: Color
    
    private var statusColor: Color {
        switch player.connectionStatus {
        case .connected: return TacticalTheme.Colors.primary
        case .disconnected: return TacticalTheme.Colors.warning
        case .inactive: return TacticalTheme.Colors.warning
        case .connecting: return TacticalTheme.Colors.warning
        }
    }
    
    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Callsign
            Text(player.callsign)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            // Connection status
            Text(player.connectionStatus.rawValue.uppercased())
                .font(TacticalTheme.Fonts.caption)
                .foregroundColor(statusColor.opacity(0.7))
        }
        .padding(.vertical, 5)
    }
}
