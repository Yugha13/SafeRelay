//
// DisasterMapView.swift
// SafeRelay
//

import SwiftUI
import MapKit

struct DisasterMapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MapViewModel.shared
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.sosMarkers) { marker in
                MapAnnotation(coordinate: marker.coordinate) {
                    VStack {
                        if marker.isCluster {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.3))
                                    .frame(width: 100, height: 100) // Highlight the area in red
                                
                                Circle()
                                    .fill(Color.red.opacity(0.8))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Text("⚠️")
                                            .font(.caption)
                                    )
                            }
                            .shadow(color: .red, radius: 10)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                                .shadow(radius: 2)
                        }
                        
                        Text(marker.title)
                            .font(.caption)
                            .bold()
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Text("Offline Disaster Map")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
