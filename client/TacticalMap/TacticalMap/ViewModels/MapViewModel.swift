// MARK: - MapViewModel.swift
import Foundation
import MapKit
import Combine
import CoreLocation
import SwiftUI

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
    
    func setup(with stateManager: StateManager) {
        self.stateManager = stateManager
        
        // Subscribe to location updates
        LocationService.shared.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateRegion(for: location)
            }
            .store(in: &cancellables)
        
        // Subscribe to heading updates
        LocationService.shared.$heading
            .compactMap { $0 }
            .sink { [weak self] heading in
                self?.heading = heading
            }
            .store(in: &cancellables)
        
        // Start update timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateAnnotations()
        }
        
        // Initial update
        updateAnnotations()
    }
    
    private func updateRegion(for location: CLLocation) {
        region.center = location.coordinate
    }
    
    private func updateAnnotations() {
        guard let stateManager = stateManager,
              let currentTeam = stateManager.currentTeam else { return }
        
        var newAnnotations: [PlayerAnnotation] = []
        
        // Add team players
        for player in stateManager.getTeamPlayers(for: currentTeam.id) {
            guard let position = player.position else { continue }
            
            let annotation = PlayerAnnotation(
                id: player.id,
                coordinate: position.coordinate,
                heading: position.heading,
                callsign: player.callsign,
                teamColor: currentTeam.swiftUIColor,
                isCurrentPlayer: player.id == stateManager.currentPlayer?.id
            )
            
            newAnnotations.append(annotation)
        }
        
        annotations = newAnnotations
    }
    
    func centerOnUser() {
        if let location = LocationService.shared.currentLocation {
            region.center = location.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        }
    }
}
