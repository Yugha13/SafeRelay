//
// DisasterMapView.swift
// SafeRelay
//

import SwiftUI
import MapKit
import CoreLocation

struct UserLocationMarker: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct DisasterMapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MapViewModel.shared

    private var allAnnotations: [SOSMarker] {
        viewModel.sosMarkers
    }

    var body: some View {
        ZStack {
            // Map with SOS markers
            Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: allAnnotations) { marker in
                MapAnnotation(coordinate: marker.coordinate) {
                    VStack(spacing: 2) {
                        if marker.isCluster {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.25))
                                    .frame(width: 90, height: 90)
                                Circle()
                                    .fill(Color.red.opacity(0.85))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text("⚠️").font(.title3)
                                    )
                                    .shadow(color: .red, radius: 6)
                            }
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                                .shadow(radius: 3)
                        }

                        Text(marker.title)
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(5)
                            .frame(maxWidth: 120)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                // Header bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding(.leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Disaster Map")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(locationSubtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)

                    Spacer()

                    // SOS count badge
                    if !viewModel.sosMarkers.isEmpty {
                        Text("🚨 \(viewModel.sosMarkers.count) SOS")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.85))
                            .cornerRadius(8)
                            .padding(.trailing)
                    }
                }
                .padding(.top, 12)

                Spacer()

                // Bottom controls
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        // My Location button
                        Button(action: centerOnUser) {
                            Image(systemName: viewModel.userLocation != nil ? "location.fill" : "location")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(viewModel.userLocation != nil ? .blue : .white)
                                .padding(12)
                                .background(Color.black.opacity(0.75))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }

                        // India overview button
                        Button(action: centerOnIndia) {
                            Image(systemName: "globe.asia.australia.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.75))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            viewModel.requestLocation()
        }
    }

    private var locationSubtitle: String {
        switch viewModel.locationAuthStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return viewModel.userLocation != nil ? "📍 Location active" : "Getting location…"
        case .denied, .restricted:
            return "⚠️ Location denied"
        default:
            return "Requesting location…"
        }
    }

    private func centerOnUser() {
        if let loc = viewModel.userLocation {
            withAnimation {
                viewModel.region = MKCoordinateRegion(
                    center: loc,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
            }
        } else {
            viewModel.requestLocation()
        }
    }

    private func centerOnIndia() {
        withAnimation {
            viewModel.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
                span: MKCoordinateSpan(latitudeDelta: 28.0, longitudeDelta: 24.0)
            )
        }
    }
}

