// MARK: - MapViewRepresentable.swift
import SwiftUI
import MapKit
import UIKit

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var mapType: MKMapType
    var annotations: [PlayerAnnotation]
    var overlays: [MKOverlay]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        mapView.setRegion(region, animated: true)
        
        // Update annotations
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // Convert PlayerAnnotation to MKPointAnnotation
        let mkAnnotations = annotations.map { annotation -> MKPointAnnotation in
            let mkAnnotation = MKPointAnnotation()
            mkAnnotation.coordinate = annotation.coordinate
            return mkAnnotation
        }
        mapView.addAnnotations(mkAnnotations)
        
        // Update overlays
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(overlays)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            // Find the corresponding PlayerAnnotation
            guard let pointAnnotation = annotation as? MKPointAnnotation,
                  let playerAnnotation = parent.annotations.first(where: { $0.coordinate.latitude == pointAnnotation.coordinate.latitude && $0.coordinate.longitude == pointAnnotation.coordinate.longitude }) else {
                return nil
            }
            
            let identifier = "PlayerAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            }
            
            // Create SwiftUI view
            let playerView = PlayerAnnotationView(annotation: playerAnnotation)
            let hostingController = UIHostingController(rootView: playerView)
            hostingController.view.backgroundColor = .clear
            
            // Size the view properly
            let targetSize = CGSize(width: 80, height: 60)
            hostingController.view.frame = CGRect(origin: .zero, size: targetSize)
            
            // Remove any existing subviews
            annotationView?.subviews.forEach { $0.removeFromSuperview() }
            
            // Add the SwiftUI view
            if let hostingView = hostingController.view {
                annotationView?.addSubview(hostingView)
                annotationView?.frame.size = targetSize
                annotationView?.centerOffset = CGPoint(x: 0, y: -targetSize.height / 2)
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Supporting Types

// Enhanced Tactical Player Annotation View
