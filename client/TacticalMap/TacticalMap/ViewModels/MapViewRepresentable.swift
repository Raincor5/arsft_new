// MARK: - MapViewRepresentable.swift
import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let mapType: MKMapType
    let annotations: [PlayerAnnotation]
    let overlays: [MKOverlay]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.showsUserLocation = false // We'll use custom annotation
        mapView.showsCompass = false // We have custom compass
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        
        // Tactical map style
        mapView.pointOfInterestFilter = .excludingAll
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        if !context.coordinator.isUserInteracting {
            mapView.setRegion(region, animated: true)
        }
        
        // Update map type
        mapView.mapType = mapType
        
        // Update annotations
        let currentAnnotationIds = Set(mapView.annotations.compactMap { ($0 as? MKPlayerAnnotation)?.playerAnnotation.id })
        let newAnnotationIds = Set(annotations.map { $0.id })
        
        // Remove old annotations
        let annotationsToRemove = mapView.annotations.filter { annotation in
            guard let mkAnnotation = annotation as? MKPlayerAnnotation else { return false }
            return !newAnnotationIds.contains(mkAnnotation.playerAnnotation.id)
        }
        mapView.removeAnnotations(annotationsToRemove)
        
        // Add or update annotations
        for annotation in annotations {
            if let existingAnnotation = mapView.annotations.first(where: {
                ($0 as? MKPlayerAnnotation)?.playerAnnotation.id == annotation.id
            }) as? MKPlayerAnnotation {
                // Update existing
                existingAnnotation.coordinate = annotation.coordinate
                existingAnnotation.playerAnnotation = annotation
            } else {
                // Add new
                let mkAnnotation = MKPlayerAnnotation(playerAnnotation: annotation)
                mapView.addAnnotation(mkAnnotation)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        var isUserInteracting = false
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            isUserInteracting = true
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
            isUserInteracting = false
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let mkAnnotation = annotation as? MKPlayerAnnotation else { return nil }
            
            let identifier = "PlayerAnnotation"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            // Create SwiftUI view
            let playerView = PlayerAnnotationView(annotation: mkAnnotation.playerAnnotation)
            let hostingController = UIHostingController(rootView: playerView)
            hostingController.view.backgroundColor = .clear
            
            // Size the view
            let size = hostingController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            hostingController.view.frame = CGRect(origin: .zero, size: size)
            
            // Set as annotation view
            annotationView.addSubview(hostingController.view)
            annotationView.frame.size = size
            annotationView.centerOffset = CGPoint(x: 0, y: -size.height / 2)
            
            return annotationView
        }
    }
}

class MKPlayerAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var playerAnnotation: PlayerAnnotation
    
    init(playerAnnotation: PlayerAnnotation) {
        self.playerAnnotation = playerAnnotation
        self.coordinate = playerAnnotation.coordinate
        super.init()
    }
}//
//  MapViewRepresentable.swift
//  TacticalMap
//
//  Created by Jaroslavs Krots on 09/06/2025.
//

