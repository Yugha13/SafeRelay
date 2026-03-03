//
// MapViewModel.swift
// SafeRelay
//

import Foundation
import MapKit
import Combine
import CoreLocation

struct SOSMarker: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let timestamp: Date
    let isCluster: Bool
}

@MainActor
final class MapViewModel: ObservableObject {
    static let shared = MapViewModel()
    
    @Published var region = MKCoordinateRegion(
        // Default to a central location (e.g. SF) if no GPS
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @Published var sosMarkers: [SOSMarker] = []
    
    private init() {}
    
    // We update this from ChatViewModel when SOS messages arrive
    func addSOS(latitude: Double, longitude: Double, sender: String) {
        let newMarker = SOSMarker(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            title: "SOS: \(sender)",
            timestamp: Date(),
            isCluster: false
        )
        sosMarkers.append(newMarker)
        updateClustering()
    }
    
    private func updateClustering() {
        // Distance-based clustering (1km radius)
        var clusters: [SOSMarker] = []
        var processed = Set<UUID>()
        
        let individualMarkers = sosMarkers.filter { !$0.isCluster }
        
        for i in 0..<individualMarkers.count {
            let base = individualMarkers[i]
            if processed.contains(base.id) { continue }
            
            var localCluster = [base]
            processed.insert(base.id)
            
            for j in (i+1)..<individualMarkers.count {
                let other = individualMarkers[j]
                if processed.contains(other.id) { continue }
                
                let dist = distance(from: base.coordinate, to: other.coordinate)
                if dist < 1000 { // 1 km
                    localCluster.append(other)
                    processed.insert(other.id)
                }
            }
            
            if localCluster.count >= 3 {
                // Geo-cluster detected
                let centerLat = localCluster.map { $0.coordinate.latitude }.reduce(0, +) / Double(localCluster.count)
                let centerLon = localCluster.map { $0.coordinate.longitude }.reduce(0, +) / Double(localCluster.count)
                
                let clusterMarker = SOSMarker(
                    coordinate: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    title: "CRITICAL RED ZONE: \(localCluster.count) SOS Signals",
                    timestamp: localCluster.map { $0.timestamp }.max() ?? Date(),
                    isCluster: true
                )
                clusters.append(clusterMarker)
            } else {
                // Keep individual
                clusters.append(contentsOf: localCluster)
            }
        }
        
        self.sosMarkers = clusters
    }
    
    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLoc = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLoc = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLoc.distance(from: toLoc)
    }
}
