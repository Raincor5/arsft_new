
// MARK: - Constants.swift
import SwiftUI
import CoreLocation

struct TacticalColors {
    static let primary = Color(red: 0, green: 1, blue: 0) // Bright green
    static let secondary = Color.gray
    static let background = Color.black
    static let surface = Color(white: 0.1)
    static let danger = Color.red
    static let warning = Color.orange
    static let alphaTeam = Color(red: 0, green: 1, blue: 0)
    static let bravoTeam = Color.red
}

struct TacticalFonts {
    static let title = Font.system(size: 24, weight: .bold, design: .monospaced)
    static let heading = Font.system(size: 18, weight: .semibold, design: .monospaced)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let caption = Font.system(size: 14, weight: .regular, design: .monospaced)
}

struct GameConstants {
    static let updateFrequency: TimeInterval = 1.0 // 1Hz
    static let positionUpdateThreshold: CLLocationDistance = 2.0 // meters
    static let mapUpdateInterval: TimeInterval = 0.1
    static let connectionTimeout: TimeInterval = 30.0
    static let maxReconnectAttempts = 5
}
