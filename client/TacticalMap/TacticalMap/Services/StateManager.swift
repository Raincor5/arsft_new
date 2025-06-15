// MARK: - StateManager.swift
import Foundation
import Combine
import SwiftUI
import CoreLocation

class StateManager: ObservableObject {
    static let shared = StateManager()
    
    // Published state
    @Published var session: Session?
    @Published var currentPlayer: Player?
    @Published var currentTeam: Team?
    @Published var players: [String: Player] = [:]
    @Published var teams: [String: Team] = [:]
    @Published var markers: [String: Marker] = [:]
    @Published var messages: [Message] = []
    
    // Connection info
    @Published var serverURL: URL?
    @Published var sessionId: String?
    @Published var isHost = false
    @Published var callsign = ""
    @Published var isConnected = false
    
    // Services
    private let webSocketService = WebSocketService.shared
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
        
        // Listen for WebSocket connection
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWebSocketConnection),
            name: Notification.Name("webSocketDidConnect"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleWebSocketConnection() {
        print("StateManager: WebSocket connected, sending auth message")
        authenticate(callsign: callsign)
    }
    
    private func setupSubscriptions() {
        // WebSocket messages
        webSocketService.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.handleWebSocketMessage(data)
            }
            .store(in: &cancellables)
        
        // Location updates
        locationService.$currentLocation
            .compactMap { $0 }
            .filter { [weak self] (location: CLLocation) in
                self?.locationService.shouldSendUpdate(for: location) ?? false
            }
            .sink { [weak self] location in
                self?.sendPositionUpdate(location)
            }
            .store(in: &cancellables)
        
        // Connection state
        webSocketService.$connectionState
            .map { $0 == .connected }
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Connection Management
    func connect(to url: URL, sessionId: String?, isHost: Bool, callsign: String) {
        print("StateManager: Connecting to \(url.absoluteString)")
        self.serverURL = url
        self.isHost = isHost
        self.callsign = callsign
        
        if let sessionId = sessionId {
            self.sessionId = sessionId
        }
        
        // Clear any existing state
        clearState()
        webSocketService.connect(to: url)
    }
    
    func disconnect() {
        webSocketService.disconnect()
        locationService.stopTracking()
        clearState()
        isConnected = false
    }
    
    private func authenticate(callsign: String) {
        print("StateManager: Authenticating with callsign: \(callsign)")
        
        let deviceInfo = Player.DeviceInfo(
            deviceType: ProcessInfo.processInfo.hostName,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
        
        var authMessage: [String: Any] = [
            "type": "auth",
            "callsign": callsign,
            "is_host": isHost,
            "device_info": [
                "device_type": deviceInfo.deviceType,
                "os_version": deviceInfo.osVersion,
                "app_version": deviceInfo.appVersion
            ]
        ]
        
        // Only include session_id when joining
        if !isHost, let sessionId = sessionId {
            authMessage["session_id"] = sessionId
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: authMessage) {
            print("StateManager: Sending auth message: \(String(data: data, encoding: .utf8) ?? "")")
            webSocketService.sendRaw(data)
        } else {
            print("StateManager: Failed to encode auth message")
        }
    }
    
    // MARK: - Message Handling
    private func handleWebSocketMessage(_ data: Data) {
        // First, try to decode a generic message to get its type
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        do {
            let genericMessage = try decoder.decode(GenericMessage.self, from: data)
            print("StateManager: Received message type: \(genericMessage.type.rawValue)")
            
            switch genericMessage.type {
            case .authResponse:
                if let authResponse = try? decoder.decode(AuthResponse.self, from: data) {
                    handleAuthResponse(authResponse)
                } else {
                    print("StateManager: Failed to decode AuthResponse")
                }
                
            case .stateDelta:
                if let deltaMessage = try? decoder.decode(StateDeltaMessage.self, from: data) {
                    handleStateDelta(deltaMessage.delta)
                } else {
                    print("StateManager: Failed to decode StateDelta")
                }
                
            case .error:
                if let errorMessage = try? decoder.decode(ErrorMessage.self, from: data) {
                    print("Server error: \(errorMessage.error)")
                }
                
            case .pong:
                print("StateManager: Received pong")
                
            default:
                print("StateManager: Handling for message type '\(genericMessage.type.rawValue)' not implemented.")
            }
        } catch {
            print("Failed to decode WebSocket message: \(error)")
            print("Raw data: \(String(data: data, encoding: .utf8) ?? "binary")")
        }
    }
    
    private func handleAuthResponse(_ response: AuthResponse) {
        print("StateManager: Handling AuthResponse")
        
        guard response.success else {
            print("StateManager: Authentication failed")
            return
        }
        
        let session = response.sessionState
        self.session = session
        self.sessionId = session.id
        
        // Set current player and team
        self.currentPlayer = session.players[response.playerId]
        
        // Handle optional teamId
        if let teamId = response.teamId {
            self.currentTeam = session.teams[teamId]
        }
        
        // Update local state dictionaries
        self.players = session.players
        self.teams = session.teams
        self.markers = session.markers
        self.messages = session.messages
        
        // Start location tracking and ping timer
        locationService.startTracking()
        webSocketService.startPingTimer()
        
        print("StateManager: Authentication complete - session established for player \(response.playerId)")
    }
    
    private func handleStateDelta(_ delta: StateDelta) {
        // Apply changes to the local state
        for change in delta.changes {
            switch (change.entityType, change.type) {
            case (.player, .add), (.player, .update):
                if let playerData = try? JSONEncoder().encode(change.data),
                   let player = try? JSONDecoder().decode(Player.self, from: playerData) {
                    players[change.entityId] = player
                    
                    // Update current player if it's them
                    if player.id == currentPlayer?.id {
                        currentPlayer = player
                    }
                }
                
            case (.player, .remove):
                players.removeValue(forKey: change.entityId)
                
            case (.team, .update):
                if let teamData = try? JSONEncoder().encode(change.data),
                   let team = try? JSONDecoder().decode(Team.self, from: teamData) {
                    teams[change.entityId] = team
                    if team.id == currentTeam?.id {
                        currentTeam = team
                    }
                }
                
            case (.marker, .add), (.marker, .update):
                if let markerData = try? JSONEncoder().encode(change.data),
                   let marker = try? JSONDecoder().decode(Marker.self, from: markerData) {
                    markers[change.entityId] = marker
                }
                
            case (.marker, .remove):
                markers.removeValue(forKey: change.entityId)
                
            case (.message, .add):
                if let messageData = try? JSONEncoder().encode(change.data),
                   let message = try? JSONDecoder().decode(Message.self, from: messageData) {
                    messages.append(message)
                    if messages.count > 100 {
                        messages = Array(messages.suffix(100))
                    }
                }
                
            default:
                print("Unhandled delta change: \(change.entityType) \(change.type)")
            }
        }
        
        // Update sequence number
        if var session = self.session {
            session.sequenceNumber = delta.sequenceNumber
            self.session = session
        }
    }
    
    // MARK: - Outgoing Messages
    func sendPositionUpdate(_ location: CLLocation) {
        guard let playerId = currentPlayer?.id else { return }
        
        let heading = locationService.heading?.trueHeading ?? 0
        let update: [String: Any] = [
            "type": "position_update",
            "player_id": playerId,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "heading": heading,
            "accuracy": location.horizontalAccuracy,
            "elevation": location.altitude,
            "timestamp": location.timestamp.timeIntervalSince1970
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: update) {
            webSocketService.sendRaw(data)
        }
    }
    
    func sendChatMessage(_ content: String, visibility: Visibility = .team) {
        let message: [String: Any] = [
            "type": "chat",
            "content": content,
            "visibility": visibility.rawValue
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message) {
            webSocketService.sendRaw(data)
        }
    }
    
    func sendAlert(_ alertType: AlertType) {
        guard let location = locationService.currentLocation else { return }
        
        let alert: [String: Any] = [
            "type": "alert",
            "alert_type": alertType.rawValue,
            "location": [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: alert) {
            webSocketService.sendRaw(data)
        }
    }
    
    func createMarker(type: MarkerType, label: String, description: String?, visibility: Visibility = .team) {
        guard let location = locationService.currentLocation else { return }
        
        let markerData: [String: Any] = [
            "type": "marker",
            "action": "create",
            "marker_data": [
                "type": type.rawValue,
                "visibility": visibility.rawValue,
                "position": [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude
                ],
                "properties": [
                    "label": label,
                    "description": description ?? "",
                    "icon": "pin",
                    "color": "#FF0000"
                ]
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: markerData) {
            webSocketService.sendRaw(data)
        }
    }
    
    func deleteMarker(_ markerId: String) {
        let message: [String: Any] = [
            "type": "marker",
            "action": "delete",
            "marker_id": markerId
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message) {
            webSocketService.sendRaw(data)
        }
    }
    
    // MARK: - Team Management (Host only)
    func assignPlayerToTeam(playerId: String, teamId: String) {
        guard isHost else { return }
        
        let message: [String: Any] = [
            "type": "team_update",
            "action": "assign_player",
            "player_id": playerId,
            "team_id": teamId
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message) {
            webSocketService.sendRaw(data)
        }
    }
    
    // MARK: - Utility
    private func clearState() {
        session = nil
        currentPlayer = nil
        currentTeam = nil
        players.removeAll()
        teams.removeAll()
        markers.removeAll()
        messages.removeAll()
    }
    
    func getTeamPlayers(for teamId: String) -> [Player] {
        guard let team = teams[teamId] else { return [] }
        return team.players.compactMap { players[$0] }
    }
    
    func getAllPlayers() -> [Player] {
        return Array(players.values)
    }
    
    func getVisibleMarkers() -> [Marker] {
        guard let currentTeamId = currentTeam?.id else { return [] }
        return markers.values.filter { marker in
            marker.visibility == .all || marker.teamId == currentTeamId
        }
    }
    
    func getVisibleMessages() -> [Message] {
        guard let currentTeamId = currentTeam?.id else { return [] }
        return messages.filter { message in
            message.visibility == .all || message.teamId == currentTeamId
        }
    }
}

// MARK: - WebSocket Message Helper Structs
private struct GenericMessage: Decodable {
    let type: MessageType
}

private struct StateDeltaMessage: Decodable {
    let delta: StateDelta
}

private struct ErrorMessage: Decodable {
    let error: String
}