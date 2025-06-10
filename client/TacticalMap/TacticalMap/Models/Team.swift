// MARK: - Team.swift
import Foundation
import SwiftUI

public struct Team: Identifiable, Codable {
    public let id: String
    public let name: String
    public let color: String
    public var players: Set<String>
    public var markers: Set<String>
    
    private enum CodingKeys: String, CodingKey {
        case id = "team_id"
        case name
        case color
        case players
        case markers
    }
    
    public var swiftUIColor: Color {
        switch name.lowercased() {
        case "alpha":
            return Color.blue
        case "bravo":
            return Color.red
        default:
            return Color.gray
        }
    }
    
    public init(id: String, name: String, color: String, players: Set<String> = [], markers: Set<String> = []) {
        self.id = id
        self.name = name
        self.color = color
        self.players = players
        self.markers = markers
    }
}
