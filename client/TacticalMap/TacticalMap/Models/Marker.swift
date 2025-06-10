// MARK: - Marker.swift
import Foundation
import CoreLocation

public struct Marker: Identifiable, Codable {
    public let id: String
    public let type: MarkerType
    public let createdBy: String
    public let teamId: String
    public let visibility: Visibility
    public let position: Position
    public var properties: MarkerProperties
    public let createdAt: Date
    public var expiresAt: Date?
    
    public enum MarkerType: String, Codable {
        case pin
        case area
        case line
    }
    
    public enum Visibility: String, Codable {
        case team
        case all
    }
    
    public struct MarkerProperties: Codable {
        public var label: String
        public var description: String?
        public var icon: String
        public var color: String
        
        public init(label: String, description: String? = nil, icon: String, color: String) {
            self.label = label
            self.description = description
            self.icon = icon
            self.color = color
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "marker_id"
        case type
        case createdBy = "created_by"
        case teamId = "team_id"
        case visibility
        case position
        case properties
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
    
    public init(id: String, type: MarkerType, createdBy: String, teamId: String, visibility: Visibility, position: Position, properties: MarkerProperties, createdAt: Date, expiresAt: Date? = nil) {
        self.id = id
        self.type = type
        self.createdBy = createdBy
        self.teamId = teamId
        self.visibility = visibility
        self.position = position
        self.properties = properties
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}
