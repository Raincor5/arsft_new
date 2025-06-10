// MARK: - Session.swift
import Foundation

struct Session: Codable {
    let id: String
    let createdAt: Date
    var lastActive: Date
    var hostId: String?
    var teams: [String: Team]
    var settings: SessionSettings
    var players: [String: Player]
    var markers: [String: Marker]
    var messages: [Message]
    var sequenceNumber: Int
    
    struct SessionSettings: Codable {
        var mapBounds: MapBounds?
        var updateFrequency: Int
        var sessionName: String?
        var allowJoin: Bool
        
        struct MapBounds: Codable {
            let north: Double
            let south: Double
            let east: Double
            let west: Double
        }
        
        private enum CodingKeys: String, CodingKey {
            case mapBounds = "map_bounds"
            case updateFrequency = "update_frequency"
            case sessionName = "session_name"
            case allowJoin = "allow_join"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case createdAt = "created_at"
        case lastActive = "last_active"
        case hostId = "host_id"
        case teams
        case settings
        case players
        case markers
        case messages
        case sequenceNumber = "sequence_number"
    }
}

