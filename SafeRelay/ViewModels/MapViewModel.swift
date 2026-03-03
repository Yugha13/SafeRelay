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

// CLLocationManagerDelegate must live in a non-isolated class
private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onUpdate: ((CLLocation) -> Void)?
    var onAuthChange: ((CLAuthorizationStatus) -> Void)?

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        onUpdate?(loc)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthChange?(manager.authorizationStatus)
    }
}

@MainActor
final class MapViewModel: ObservableObject {
    static let shared = MapViewModel()

    // India center as default
    private static let indiaCenter = CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629)

    @Published var region = MKCoordinateRegion(
        center: indiaCenter,
        span: MKCoordinateSpan(latitudeDelta: 28.0, longitudeDelta: 24.0)
    )
    @Published var sosMarkers: [SOSMarker] = []
    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private let locationDelegate = LocationDelegate()

    private init() {
        locationManager.delegate = locationDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        locationDelegate.onUpdate = { [weak self] location in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let coord = location.coordinate
                self.userLocation = coord
                // Zoom to user on first fix
                let authorized: Bool
                #if os(iOS)
                authorized = self.locationAuthStatus == .authorizedWhenInUse || self.locationAuthStatus == .authorizedAlways
                #else
                authorized = self.locationAuthStatus == .authorized || self.locationAuthStatus == .authorizedAlways
                #endif
                if authorized {
                    self.region = MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                    )
                }
            }
        }

        locationDelegate.onAuthChange = { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.locationAuthStatus = status
                let startNow: Bool
                #if os(iOS)
                startNow = status == .authorizedWhenInUse || status == .authorizedAlways
                #else
                startNow = status == .authorized || status == .authorizedAlways
                #endif
                if startNow {
                    self.locationManager.startUpdatingLocation()
                }
            }
        }
    }

    func requestLocation() {
        let status = locationManager.authorizationStatus
        #if os(iOS)
        let isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
        #else
        let isAuthorized = status == .authorized || status == .authorizedAlways
        #endif
        if status == .notDetermined {
            #if os(iOS)
            locationManager.requestWhenInUseAuthorization()
            #else
            locationManager.requestAlwaysAuthorization()
            #endif
        } else if isAuthorized {
            locationManager.startUpdatingLocation()
        }
    }

    // Called from ChatViewModel when SOS w/ geo arrives
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
                if distance(from: base.coordinate, to: other.coordinate) < 1000 {
                    localCluster.append(other)
                    processed.insert(other.id)
                }
            }

            if localCluster.count >= 3 {
                let centerLat = localCluster.map { $0.coordinate.latitude }.reduce(0, +) / Double(localCluster.count)
                let centerLon = localCluster.map { $0.coordinate.longitude }.reduce(0, +) / Double(localCluster.count)
                clusters.append(SOSMarker(
                    coordinate: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    title: "⚠️ RED ZONE: \(localCluster.count) SOS Signals",
                    timestamp: localCluster.map { $0.timestamp }.max() ?? Date(),
                    isCluster: true
                ))
            } else {
                clusters.append(contentsOf: localCluster)
            }
        }
        self.sosMarkers = clusters
    }

    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: from.latitude, longitude: from.longitude)
            .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }
}

    

