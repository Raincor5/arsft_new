// MARK: - NetworkModels.swift
import Foundation

// WebSocket message types
enum MessageType: String {
    case auth
    case authResponse = "auth_response"
    case positionUpdate = "position_update"
    case stateDelta = "state_delta"
    case stateSnapshot = "state_snapshot"
    case chat
    case alert
    case marker
    case teamUpdate = "team_update"
    case error
    case ping
    case pong
}

// Alert types
enum AlertType: String, CaseIterable {
    case contact
    case danger
    case rally
    case help
    
    var displayName: String {
        switch self {
        case .contact: return "Enemy Contact"
        case .danger: return "Danger"
        case .rally: return "Rally Point"
        case .help: return "Need Assistance"
        }
    }
    
    var icon: String {
        switch self {
        case .contact: return "eye.fill"
        case .danger: return "exclamationmark.triangle.fill"
        case .rally: return "flag.fill"
        case .help: return "cross.circle.fill"
        }
    }
}

// State delta
struct StateDelta: Codable {
    let deltaId: String
    let sessionId: String
    let timestamp: Date
    let sequenceNumber: Int
    let changes: [StateChange]
    
    struct StateChange: Codable {
        let type: ChangeType
        let entityType: EntityType
        let entityId: String
        let data: [String: Any]
        let path: String?
        
        enum ChangeType: String, Codable {
            case add
            case update
            case remove
        }
        
        enum EntityType: String, Codable {
            case player
            case marker
            case message
            case team
        }
        
        private enum CodingKeys: String, CodingKey {
            case type
            case entityType = "entity_type"
            case entityId = "entity_id"
            case data
            case path
        }
        
        // Custom encoding/decoding for Any type
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(ChangeType.self, forKey: .type)
            entityType = try container.decode(EntityType.self, forKey: .entityType)
            entityId = try container.decode(String.self, forKey: .entityId)
            path = try container.decodeIfPresent(String.self, forKey: .path)
            
            // Decode data as generic JSON
            if let dataContainer = try? container.decodeIfPresent([String: AnyCodable].self, forKey: .data) {
                data = dataContainer.mapValues { $0.value }
            } else {
                data = [:]
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(entityType, forKey: .entityType)
            try container.encode(entityId, forKey: .entityId)
            try container.encodeIfPresent(path, forKey: .path)
            
            // Encode data
            let anyCodableData = data.mapValues { AnyCodable($0) }
            try container.encode(anyCodableData, forKey: .data)
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

// Helper for encoding/decoding Any types
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let anyCodableArray = array.map { AnyCodable($0) }
            try container.encode(anyCodableArray)
        case let dictionary as [String: Any]:
            let anyCodableDictionary = dictionary.mapValues { AnyCodable($0) }
            try container.encode(anyCodableDictionary)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Cannot encode value"))
        }
    }
}
