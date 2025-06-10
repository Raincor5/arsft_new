// MARK: - Message.swift
import Foundation

public struct Message: Identifiable, Codable {
    public let id: String
    public let senderId: String
    public let teamId: String
    public let visibility: Visibility
    public let type: MessageType
    public let content: String
    public let sentAt: Date
    public var location: Position?
    
    public enum Visibility: String, Codable {
        case team
        case all
    }
    
    public enum MessageType: String, Codable {
        case chat
        case alert
        case system
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "message_id"
        case senderId = "sender_id"
        case teamId = "team_id"
        case visibility
        case type
        case content
        case sentAt = "sent_at"
        case location
    }
    
    public init(id: String, senderId: String, teamId: String, visibility: Visibility, type: MessageType, content: String, sentAt: Date, location: Position? = nil) {
        self.id = id
        self.senderId = senderId
        self.teamId = teamId
        self.visibility = visibility
        self.type = type
        self.content = content
        self.sentAt = sentAt
        self.location = location
    }
}
