// MARK: - Position.swift
import Foundation
import CoreLocation

public struct Position: Codable, Equatable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    public let accuracy: Double
    public let heading: Double
    public let speed: Double
    public let timestamp: Date
    
    public init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.accuracy = location.horizontalAccuracy
        self.heading = location.course
        self.speed = location.speed
        self.timestamp = location.timestamp
    }
    
    public init(latitude: Double, longitude: Double, altitude: Double, accuracy: Double, heading: Double, speed: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.accuracy = accuracy
        self.heading = heading
        self.speed = speed
        self.timestamp = timestamp
    }
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public var clLocation: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: accuracy,
            verticalAccuracy: -1,
            course: heading,
            speed: speed,
            timestamp: timestamp
        )
    }
} 