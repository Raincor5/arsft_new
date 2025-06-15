// MARK: - MapViewModel.swift
import Foundation
import MapKit
import Combine
import CoreLocation
import SwiftUI

// All model types (PlayerAnnotation, Player, Team, etc.) are assumed to be defined in Models.swift in the same target.

class MapViewModel: NSObject, ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var annotations: [PlayerAnnotation] = []
    @Published var overlays: [MKOverlay] = []
    @Published var heading: CLHeading?
    @Published var unreadMessages = 0
    
    private var stateManager: StateManager?
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private var lastUpdateTime: Date = Date()
    
    func setup(with stateManager: StateManager) {
        self.stateManager = stateManager
        
        // Subscribe to location updates
        LocationService.shared.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] (location: CLLocation) in
                self?.updateRegion(for: location)
            }
            .store(in: &cancellables)
        
        // Subscribe to heading updates
        LocationService.shared.$heading
            .compactMap { $0 }
            .sink { [weak self] (heading: CLHeading) in
                self?.heading = heading
            }
            .store(in: &cancellables)
        
        // Subscribe to player updates
        stateManager.$players
            .sink { [weak self] (_: [String: Player]) in
                self?.updateAnnotations()
            }
            .store(in: &cancellables)
        
        // Subscribe to current player updates
        stateManager.$currentPlayer
            .sink { [weak self] (_: Player?) in
                self?.updateAnnotations()
            }
            .store(in: &cancellables)
        
        // Subscribe to current team updates
        stateManager.$currentTeam
            .sink { [weak self] (_: Team?) in
                self?.updateAnnotations()
            }
            .store(in: &cancellables)
        
        // Subscribe to message updates
        stateManager.$messages
            .sink { [weak self] (messages: [Message]) in
                self?.updateUnreadCount(messages)
            }
            .store(in: &cancellables)
        
        // Start periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateAnnotations()
        }
        
        // Initial update
        updateAnnotations()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    private func updateRegion(for location: CLLocation) {
        let newRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )
        
        // Only update if the change is significant
        let currentCenter = region.center
        let distance = location.distance(from: CLLocation(
            latitude: currentCenter.latitude,
            longitude: currentCenter.longitude
        ))
        
        if distance > 10 { // 10 meters threshold
            DispatchQueue.main.async {
                self.region = newRegion
            }
        }
    }
    
    func updateAnnotations() {
        guard let stateManager = stateManager,
              let currentTeam = stateManager.currentTeam else { 
            annotations = []
            return 
        }
        
        var newAnnotations: [PlayerAnnotation] = []
        
        // Get all players in the current team
        let teamPlayers = stateManager.getTeamPlayers(for: currentTeam.id)
        
        for player in teamPlayers {
            guard let position = player.position else { continue }
            
            // Only show connected or recently active players
            let currentTime = Date().timeIntervalSince1970
            let timeSinceLastActive = currentTime - player.lastActive
            let isRecentlyActive = timeSinceLastActive < 300 // 5 minutes
            guard player.connectionStatus == .connected || isRecentlyActive else { continue }
            
            let annotation = PlayerAnnotation(
                id: player.id,
                coordinate: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude),
                heading: position.heading ?? 0,
                player: player,
                team: currentTeam,
                isCurrentPlayer: player.id == stateManager.currentPlayer?.id
            )
            
            newAnnotations.append(annotation)
        }
        
        // Update on main thread
        DispatchQueue.main.async {
            self.annotations = newAnnotations
        }
    }
    
    private func updateUnreadCount(_ messages: [Message]) {
        guard let stateManager = stateManager else { return }
        
        // For now, just use total visible messages count
        let visibleMessages = stateManager.getVisibleMessages()
        unreadMessages = min(visibleMessages.count, 99) // Cap at 99
    }
    
    func centerOnUser() {
        guard let location = LocationService.shared.currentLocation else { return }
        
        let newRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = newRegion
        }
        
        // Haptic feedback
        HapticFeedback.impact(.medium)
    }
    
    func addMarkerOverlay(at coordinate: CLLocationCoordinate2D, radius: Double = 50) {
        let circle = MKCircle(center: coordinate, radius: radius)
        overlays.append(circle)
    }
    
    func clearOverlays() {
        overlays.removeAll()
    }
}