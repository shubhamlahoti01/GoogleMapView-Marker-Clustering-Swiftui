//
//  ContentView.swift
//  MapViewflow
//
//  Created by USER on 14/05/25.
//

import SwiftUI
import GoogleMaps
import CoreLocation

struct SimpleMarker: Identifiable, Equatable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let snippet: String?
    var selected: Bool = false
    var imageURL: URL?

    static func == (lhs: SimpleMarker, rhs: SimpleMarker) -> Bool {
        lhs.id == rhs.id &&
        lhs.selected == rhs.selected &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct ContentView: View {
    @State private var cameraPosition = GMSCameraPosition(latitude: 19.0760, longitude: 72.8777, zoom: 5)
    @State private var lastCameraPosition: CLLocationCoordinate2D?
    @State private var lastZoom: Float = 5

    var body: some View {
        CustomGoogleMapView(
            cameraPosition: $cameraPosition,
            markers: markers,
            onCameraIdle: { cam, _ in
                let movedFar = hasMovedFar(from: lastCameraPosition, to: cam.target, thresholdInKm: 10)
                let zoomChanged = abs(cam.zoom - lastZoom) >= 1

                if movedFar || zoomChanged {
                    lastCameraPosition = cam.target
                    lastZoom = cam.zoom
                    if markers.count < 100 {
                        let newMarkers = generateMockMarkers(around: cam.target)
                        markers.append(contentsOf: newMarkers)
                    }  
                }
            },
            onMarkerTap: { tapped in
                if let index = markers.firstIndex(where: { $0.id == tapped.id }) {
                    markers[index].selected.toggle()
                }
            }
        )
    }

    // MARK: Distance check
    func hasMovedFar(from: CLLocationCoordinate2D?, to: CLLocationCoordinate2D, thresholdInKm: Double) -> Bool {
        guard let from = from else { return true }
        let loc1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let loc2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distance = loc1.distance(from: loc2) / 1000  // convert to km
        return distance >= thresholdInKm
    }

    // MARK: Marker generator
    func generateMockMarkers(around center: CLLocationCoordinate2D) -> [SimpleMarker] {
        let newId = UUID().uuidString.prefix(4)
        let offset = 1.0
        let positions = [
            CLLocationCoordinate2D(latitude: center.latitude + offset, longitude: center.longitude),
            CLLocationCoordinate2D(latitude: center.latitude - offset, longitude: center.longitude),
            CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude + offset),
            CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude - offset),
            CLLocationCoordinate2D(latitude: center.latitude + offset * 0.7, longitude: center.longitude + offset * 0.7)
        ]

        return positions.enumerated().map { (index, coordinate) in
            let markerIndex = index + 1
            let randomImageId = Int.random(in: 1...1000) // Picsum supports 1-1000+ IDs
            return SimpleMarker(
                id: "\(newId)-\(markerIndex)",
                coordinate: coordinate,
                title: "Marker \(markerIndex)",
                snippet: nil,
                imageURL: URL(string: "https://picsum.photos/id/\(randomImageId)/200/300")
            )
        }
    }


    @State private var markers: [SimpleMarker] = [
        .init(id: "1", coordinate: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777), title: "Marker 1", snippet: "City of Dreams", imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "2", coordinate: CLLocationCoordinate2D(latitude: 28.7041, longitude: 77.1025), title: "Marker 2", snippet: "Capital Territory", imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "3", coordinate: CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707), title: "Marker 3", snippet: "South India", imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "4", coordinate: CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639), title: "Marker 4", snippet: "City of Joy", imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "5", coordinate: CLLocationCoordinate2D(latitude: 18.5204, longitude: 73.8567), title: "Marker 5", snippet: "Oxford of the East", imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "6", coordinate: CLLocationCoordinate2D(latitude: 23.0225, longitude: 72.5714), title: "Marker 6", snippet: nil, imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "7", coordinate: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946), title: "Marker 7", snippet: nil, imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "8", coordinate: CLLocationCoordinate2D(latitude: 26.9124, longitude: 75.7873), title: "Marker 8", snippet: nil, imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "9", coordinate: CLLocationCoordinate2D(latitude: 21.1702, longitude: 72.8311), title: "Marker 9", snippet: nil, imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "10", coordinate: CLLocationCoordinate2D(latitude: 15.2993, longitude: 74.1240), title: "Marker 10", snippet: nil, imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "11", coordinate: CLLocationCoordinate2D(latitude: 11.0168, longitude: 76.9558), title: "Marker 11", snippet: nil, imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300")),
        .init(id: "12", coordinate: CLLocationCoordinate2D(latitude: 17.3850, longitude: 78.4867), title: "Marker 12", snippet: nil, imageURL: URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/200/300"))
    ]

}
