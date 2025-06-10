// MARK: - Player.swift
import Foundation
import CoreLocation

public struct Player: Identifiable, Codable {
    public let id: String
    public let callsign: String
    public var teamId: String?
    public var connectionStatus: ConnectionStatus
    public var lastActive: Date
    public var position: Position?
    public var deviceInfo: DeviceInfo
    
    public enum ConnectionStatus: String, Codable {
        case connected
        case disconnected
        case inactive
    }
    
    public struct DeviceInfo: Codable {
        public let deviceType: String
        public let osVersion: String
        public let appVersion: String
        
        public init(deviceType: String, osVersion: String, appVersion: String) {
            self.deviceType = deviceType
            self.osVersion = osVersion
            self.appVersion = appVersion
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
    
    public init(id: String, callsign: String, teamId: String? = nil, connectionStatus: ConnectionStatus = .disconnected, lastActive: Date = Date(), position: Position? = nil, deviceInfo: DeviceInfo) {
        self.id = id
        self.callsign = callsign
        self.teamId = teamId
        self.connectionStatus = connectionStatus
        self.lastActive = lastActive
        self.position = position
        self.deviceInfo = deviceInfo
    }
}
