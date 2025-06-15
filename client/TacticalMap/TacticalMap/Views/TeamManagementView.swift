// MARK: - TeamManagementView.swift
import SwiftUI

struct TeamManagementView: View {
    @EnvironmentObject var stateManager: StateManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlayer: Player?
    @State private var showingTeamPicker = false
    
    private var allPlayers: [Player] {
        stateManager.getAllPlayers().sorted { $0.callsign < $1.callsign }
    }
    
    private var teamsArray: [Team] {
        Array(stateManager.teams.values).sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background with subtle pattern
                Color.black.ignoresSafeArea()
                
                // Subtle grid pattern
                VStack(spacing: 0) {
                    ForEach(0..<20, id: \.self) { _ in
                        HStack(spacing: 0) {
                            ForEach(0..<10, id: \.self) { _ in
                                Rectangle()
                                    .stroke(TacticalColors.primary.opacity(0.05), lineWidth: 0.5)
                                    .frame(width: 40, height: 40)
                            }
                        }
                    }
                }
                .allowsHitTesting(false)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(TacticalColors.warning)
                                    .font(.title2)
                                
                                Text("TEAM MANAGEMENT")
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(TacticalColors.primary)
                            }
                            
                            Text("HOST CONTROLS")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(TacticalColors.secondary)
                        }
                        .padding(.top, 20)
                        
                        // Teams Section
                        ForEach(teamsArray, id: \.id) { team in
                            TeamManagementCard(
                                team: team,
                                players: stateManager.getTeamPlayers(for: team.id),
                                onPlayerTap: { player in
                                    selectedPlayer = player
                                    showingTeamPicker = true
                                    HapticFeedback.impact(.medium)
                                }
                            )
                        }
                        
                        // Unassigned Players
                        let unassignedPlayers = allPlayers.filter { $0.teamId == nil }
                        if !unassignedPlayers.isEmpty {
                            UnassignedPlayersCard(
                                players: unassignedPlayers,
                                onPlayerTap: { player in
                                    selectedPlayer = player
                                    showingTeamPicker = true
                                    HapticFeedback.impact(.medium)
                                }
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingTeamPicker) {
                if let player = selectedPlayer {
                    TeamPickerView(
                        player: player,
                        teams: teamsArray,
                        onTeamSelected: { teamId in
                            stateManager.assignPlayerToTeam(playerId: player.id, teamId: teamId)
                            showingTeamPicker = false
                            selectedPlayer = nil
                            HapticFeedback.notification(.success)
                        }
                    )
                }
            }
            .overlay(
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(TacticalColors.primary)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.8))
                                        .overlay(
                                            Circle()
                                                .stroke(TacticalColors.primary, lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            )
        }
        .preferredColorScheme(.dark)
    }
}

struct TeamManagementCard: View {
    let team: Team
    let players: [Player]
    let onPlayerTap: (Player) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Team header
            HStack {
                Circle()
                    .fill(team.swiftUIColor)
                    .frame(width: 20, height: 20)
                    .shadow(color: team.swiftUIColor, radius: 4)
                
                Text("TEAM \(team.name.uppercased())")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(team.swiftUIColor)
                
                Spacer()
                
                Text("\(players.count) OPERATORS")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(TacticalColors.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(team.swiftUIColor.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(team.swiftUIColor.opacity(0.5), lineWidth: 1)
                            )
                    )
            }
            
            // Players grid
            if players.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.title)
                            .foregroundColor(TacticalColors.secondary.opacity(0.5))
                        
                        Text("No operators assigned")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(TacticalColors.secondary.opacity(0.7))
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(players, id: \.id) { player in
                        PlayerCard(player: player, teamColor: team.swiftUIColor) {
                            onPlayerTap(player)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    team.swiftUIColor.opacity(0.6),
                                    team.swiftUIColor.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: team.swiftUIColor.opacity(0.3), radius: 8)
        )
    }
}

struct UnassignedPlayersCard: View {
    let players: [Player]
    let onPlayerTap: (Player) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .foregroundColor(TacticalColors.warning)
                    .font(.title2)
                
                Text("UNASSIGNED OPERATORS")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(TacticalColors.warning)
                
                Spacer()
                
                Text("\(players.count)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Circle()
                            .fill(TacticalColors.warning)
                    )
            }
            
            // Players
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(players, id: \.id) { player in
                    PlayerCard(player: player, teamColor: TacticalColors.warning) {
                        onPlayerTap(player)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(TacticalColors.warning.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: TacticalColors.warning.opacity(0.3), radius: 8)
        )
    }
}

struct PlayerCard: View {
    let player: Player
    let teamColor: Color
    let onTap: () -> Void
    
    private var statusIcon: String {
        switch player.connectionStatus {
        case .connected: return "wifi"
        case .disconnected: return "wifi.slash"
        case .inactive: return "moon.zzz"
        case .connecting: return "wifi.exclamationmark"
        }
    }
    
    private var statusColor: Color {
        switch player.connectionStatus {
        case .connected: return TacticalColors.primary
        case .disconnected: return TacticalColors.danger
        case .inactive: return TacticalColors.warning
        case .connecting: return TacticalColors.warning
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Status and callsign
                HStack(spacing: 6) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 12))
                        .foregroundColor(statusColor)
                    
                    Text(player.callsign)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                // Move button
                HStack {
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 12))
                        Text("MOVE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(teamColor)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(teamColor.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TeamPickerView: View {
    let player: Player
    let teams: [Team]
    let onTeamSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("REASSIGN OPERATOR")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(TacticalColors.primary)
                        
                        Text(player.callsign)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(TacticalColors.primary.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(TacticalColors.primary, lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.top, 20)
                    
                    // Team options
                    VStack(spacing: 16) {
                        ForEach(teams, id: \.id) { team in
                            Button(action: {
                                onTeamSelected(team.id)
                            }) {
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(team.swiftUIColor)
                                        .frame(width: 24, height: 24)
                                        .shadow(color: team.swiftUIColor, radius: 4)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("TEAM \(team.name.uppercased())")
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundColor(team.swiftUIColor)
                                        
                                        let teamPlayers = teams.first(where: { $0.id == team.id })?.players.count ?? 0
                                        Text("\(teamPlayers) operators")
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .foregroundColor(TacticalColors.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(team.swiftUIColor)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(team.swiftUIColor.opacity(0.5), lineWidth: 1.5)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .overlay(
                // Close button
                VStack {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(TacticalColors.primary)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            )
        }
        .preferredColorScheme(.dark)
    }
}