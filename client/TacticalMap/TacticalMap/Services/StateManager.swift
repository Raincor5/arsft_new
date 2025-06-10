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
    var extensionCancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
        
        // Listen for WebSocket connection
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWebSocketConnection),
            name: .webSocketDidConnect,
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
            .filter { [weak self] location in
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
            deviceType: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
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
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = json["type"] as? String {
                
                print("StateManager: Received message type: \(type)")
                
                switch type {
                case "auth_response":
                    handleAuthResponse(json)
                case "state_delta":
                    if let deltaData = json["delta"] as? [String: Any] {
                        handleStateDelta(deltaData)
                    }
                case "error":
                    if let error = json["error"] as? String {
                        print("Server error: \(error)")
                    }
                case "pong":
                    print("StateManager: Received pong")
                default:
                    print("StateManager: Unknown message type: \(type)")
                }
            }
        } catch {
            print("Failed to parse WebSocket message: \(error)")
            print("Raw data: \(String(data: data, encoding: .utf8) ?? "binary")")
        }
    }
    
    private func handleAuthResponse(_ data: [String: Any]) {
        print("StateManager: Received auth response: \(data)")
        guard let success = data["success"] as? Bool, success,
              let playerId = data["player_id"] as? String,
              let teamId = data["team_id"] as? String,
              let sessionState = data["session_state"] as? [String: Any] else {
            print("StateManager: Authentication failed - missing required fields")
            return
        }
        
        print("StateManager: Parsing session state")
        // Parse session state
        if let sessionData = try? JSONSerialization.data(withJSONObject: sessionState),
           let session = try? JSONDecoder().decode(Session.self, from: sessionData) {
            print("StateManager: Session parsed successfully")
            self.session = session
            self.sessionId = session.id
            
            // Set current player and team
            currentPlayer = session.players[playerId]
            currentTeam = session.teams[teamId]
            
            // Update local state
            players = session.players
            teams = session.teams
            markers = session.markers
            messages = session.messages
            
            // Start location tracking
            locationService.startTracking()
            
            // Start ping timer after successful authentication
            webSocketService.startPingTimer()
            
            print("StateManager: Authentication complete - session established")
        } else {
            print("StateManager: Failed to parse session state")
        }
    }
    
    private func handleStateDelta(_ deltaData: [String: Any]) {
        guard let changes = deltaData["changes"] as? [[String: Any]] else { return }
        
        for change in changes {
            guard let changeType = change["type"] as? String,
                  let entityType = change["entity_type"] as? String,
                  let entityId = change["entity_id"] as? String,
                  let data = change["data"] as? [String: Any] else { continue }
            
            switch (entityType, changeType) {
            case ("player", "add"), ("player", "update"):
                updatePlayer(entityId, with: data)
            case ("player", "remove"):
                players.removeValue(forKey: entityId)
                
            case ("team", "update"):
                updateTeam(entityId, with: data)
                
            case ("marker", "add"), ("marker", "update"):
                updateMarker(entityId, with: data)
            case ("marker", "remove"):
                markers.removeValue(forKey: entityId)
                
            case ("message", "add"):
                if let messageData = try? JSONSerialization.data(withJSONObject: data),
                   let message = try? JSONDecoder().decode(Message.self, from: messageData) {
                    messages.append(message)
                    // Keep only last 100 messages
                    if messages.count > 100 {
                        messages = Array(messages.suffix(100))
                    }
                }
                
            default:
                break
            }
        }
    }
    
    private func updatePlayer(_ playerId: String, with data: [String: Any]) {
        if var player = players[playerId] {
            // Update existing player
            if let positionData = data["position"] as? [String: Any],
               let positionJSON = try? JSONSerialization.data(withJSONObject: positionData),
               let position = try? JSONDecoder().decode(Position.self, from: positionJSON) {
                player.position = position
            }
            
            if let status = data["connection_status"] as? String {
                player.connectionStatus = Player.ConnectionStatus(rawValue: status) ?? .disconnected
            }
            
            players[playerId] = player
        } else if let playerData = try? JSONSerialization.data(withJSONObject: data),
                  let player = try? JSONDecoder().decode(Player.self, from: playerData) {
            // Add new player
            players[playerId] = player
        }
    }
    
    private func updateTeam(_ teamId: String, with data: [String: Any]) {
        if var team = teams[teamId] {
            if let playerIds = data["players"] as? [String] {
                team.players = Set(playerIds)
            }
            teams[teamId] = team
        }
    }
    
    private func updateMarker(_ markerId: String, with data: [String: Any]) {
        if let markerData = try? JSONSerialization.data(withJSONObject: data),
           let marker = try? JSONDecoder().decode(Marker.self, from: markerData) {
            markers[markerId] = marker
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
    
    func sendChatMessage(_ content: String, visibility: Message.Visibility = .team) {
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
    
    func createMarker(type: Marker.MarkerType, label: String, description: String?, visibility: Message.Visibility = .team) {
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
