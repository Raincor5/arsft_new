// MARK: - Models.swift
import Foundation
import MapKit
import SwiftUI

// MARK: - Network Models

struct Player: Codable, Identifiable {
    let id: String
    let callsign: String
    var teamId: String?
    var connectionStatus: ConnectionStatus
    var lastActive: TimeInterval
    var position: Position?
    let deviceInfo: DeviceInfo

    struct DeviceInfo: Codable {
        let deviceType: String
        let osVersion: String
        let appVersion: String

        private enum CodingKeys: String, CodingKey {
            case deviceType = "device_type"
            case osVersion = "os_version"
            case appVersion = "app_version"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id = "player_id"
        case callsign
        case teamId = "team_id"
        case connectionStatus = "connection_status"
        case lastActive = "last_active"
        case position
        case deviceInfo = "device_info"
    }
}

struct Team: Codable, Identifiable {
    let id: String
    let name: String
    let color: String
    var players: [String]

    var swiftUIColor: Color {
        Color(color)
    }

    private enum CodingKeys: String, CodingKey {
        case id = "team_id"
        case name, color, players
    }
}

struct Position: Codable {
    let latitude: Double
    let longitude: Double
    let heading: Double?
    let accuracy: Double?
    let elevation: Double?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func distance(to other: Position) -> Double {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }
}

struct Marker: Codable, Identifiable {
    let id: String
    let type: MarkerType
    let createdBy: String
    let teamId: String
    let visibility: Visibility
    let position: Position
    let properties: [String: AnyCodable]?
    let createdAt: TimeInterval
    let expiresAt: TimeInterval?

    private enum CodingKeys: String, CodingKey {
        case id = "marker_id"
        case type
        case createdBy = "created_by"
        case teamId = "team_id"
        case visibility, position, properties
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

struct Message: Codable, Identifiable {
    let id: String
    let senderId: String
    let teamId: String
    let visibility: Visibility
    let type: String
    let content: String
    let sentAt: TimeInterval
    let location: Position?

    private enum CodingKeys: String, CodingKey {
        case id = "message_id"
        case senderId = "sender_id"
        case teamId = "team_id"
        case visibility, type, content
        case sentAt = "sent_at"
        case location
    }
}

struct Session: Codable, Identifiable {
    let id: String
    var sequenceNumber: Int
    var teams: [String: Team]
    var players: [String: Player]
    var markers: [String: Marker]
    var messages: [Message]

    private enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case sequenceNumber = "sequence_number"
        case teams, players, markers, messages
    }
}

// MARK: - Map Annotations

struct PlayerAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let heading: Double
    let player: Player
    let team: Team
    let isCurrentPlayer: Bool
    
    var callsign: String { player.callsign }
    var teamColor: Color { team.swiftUIColor }
}

// MARK: - Enums

enum ConnectionStatus: String, Codable {
    case connected
    case disconnected
    case connecting
    case inactive
}

enum MarkerType: String, Codable, CaseIterable {
    case waypoint
    case objective
    case danger
    case custom
    case pin
}

enum Visibility: String, Codable {
    case all
    case team
    case `private`
}

// MARK: - Message Types

enum MessageType: String, Codable {
    case positionUpdate = "position_update"
    case chat
    case alert
    case marker
    case teamUpdate = "team_update"
    case authResponse = "auth_response"
    case stateDelta = "state_delta"
    case error
    case pong
}

// MARK: - Alert Types

enum AlertType: String, Codable, CaseIterable {
    case warning
    case danger
    
    var displayName: String {
        switch self {
        case .warning: return "Warning"
        case .danger: return "Danger"
        }
    }
    
    var icon: String {
        switch self {
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - State Delta

struct StateDelta: Codable {
    let deltaId: String
    let sessionId: String
    let timestamp: TimeInterval
    let sequenceNumber: Int
    let changes: [StateChange]

    struct StateChange: Codable {
        let type: ChangeType
        let entityType: EntityType
        let entityId: String
        let data: [String: AnyCodable]

        enum ChangeType: String, Codable {
            case add, update, remove
        }

        enum EntityType: String, Codable {
            case player, team, marker, message
        }
        
        private enum CodingKeys: String, CodingKey {
            case type
            case entityType = "entity_type"
            case entityId = "entity_id"
            case data
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case deltaId = "delta_id"
        case sessionId = "session_id"
        case timestamp
        case sequenceNumber = "sequence_number"
        case changes
    }
}

// MARK: - Auth Response

struct AuthResponse: Codable {
    let success: Bool
    let sessionId: String
    let playerId: String
    let teamId: String?
    let token: String
    let sessionState: Session
    
    private enum CodingKeys: String, CodingKey {
        case success
        case sessionId = "session_id"
        case playerId = "player_id"
        case teamId = "team_id"
        case token
        case sessionState = "session_state"
    }
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable cannot decode value"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable cannot encode value"
                )
            )
        }
    }
} 