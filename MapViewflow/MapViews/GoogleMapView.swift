import SwiftUI
import NukeUI
import GoogleMapsUtils
import GoogleMaps

struct CustomGoogleMapView: UIViewRepresentable {
    @Binding var cameraPosition: GMSCameraPosition
    var markers: [SimpleMarker]
    var onCameraIdle: (GMSCameraPosition, GMSVisibleRegion) -> Void
    var onMarkerTap: (SimpleMarker) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> GMSMapView {
        let mapView = GMSMapView(frame: .zero, camera: cameraPosition)
        mapView.delegate = context.coordinator
        mapView.settings.compassButton = false
        mapView.settings.myLocationButton = false

//        let iconGenerator = GMUDefaultClusterIconGenerator()
        let iconGenerator = GMUDefaultClusterIconGenerator(buckets: [20, 50, 100], backgroundColors: [.black, .red, .blue])
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = CustomClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        renderer.delegate = context.coordinator

        let clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        context.coordinator.clusterManager = clusterManager
        context.coordinator.renderer = renderer

        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        if mapView.camera != cameraPosition {
            mapView.moveCamera(.setCamera(cameraPosition))
        }

        let newMarkersByID = Dictionary(uniqueKeysWithValues: markers.map { ($0.id, $0) })
        let oldMarkersByID = context.coordinator.markerItems

        // Remove deleted markers
        for (id, item) in oldMarkersByID where newMarkersByID[id] == nil {
            context.coordinator.clusterManager?.remove(item)
            context.coordinator.markerItems.removeValue(forKey: id)
        }

        // Add or update
        for (id, newMarker) in newMarkersByID {
            if let oldItem = oldMarkersByID[id], oldItem.markerData == newMarker {
                continue // no change
            }

            if let oldItem = oldMarkersByID[id] {
                context.coordinator.clusterManager?.remove(oldItem)
            }

            let newItem = POIItem(position: newMarker.coordinate, markerData: newMarker)
            context.coordinator.clusterManager?.add(newItem)
            context.coordinator.markerItems[id] = newItem
        }

        context.coordinator.clusterManager?.cluster()
    }

    class Coordinator: NSObject, GMSMapViewDelegate, GMUClusterRendererDelegate {
        var parent: CustomGoogleMapView
        var clusterManager: GMUClusterManager?
        var renderer: CustomClusterRenderer?
        var markerItems: [String: POIItem] = [:]
        var markerViewCache: [String: UIView] = [:]
        var cachedMarkerData: [String: SimpleMarker] = [:] // Cache to track selected state

        init(_ parent: CustomGoogleMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            let region = mapView.projection.visibleRegion()
            parent.onCameraIdle(position, region)
        }

        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            parent.cameraPosition = position
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let poi = marker.userData as? POIItem {
                // Toggle selected state when marker is tapped
                poi.markerData.selected.toggle()
                parent.onMarkerTap(poi.markerData)
                return true
            }
            return false
        }

        // For clustered markers, apply custom SwiftUI marker rendering
        func renderer(_ renderer: GMUClusterRenderer, willRenderMarker marker: GMSMarker) {
            guard let poi = marker.userData as? POIItem else { return }

            let markerID = poi.markerData.id
            let currentMarkerData = poi.markerData

            // Always re-render if selection state has changed
            if let cachedView = markerViewCache[markerID],
               let cachedData = cachedMarkerData[markerID],
               cachedData == currentMarkerData {
                marker.iconView = cachedView
                return
            }

            // Create new SwiftUI view
            let markerView = MyCustomMarkerView(text: currentMarkerData.title ?? "", imageURL: currentMarkerData.imageURL, isSelected: currentMarkerData.selected)
                .frame(width: 80, height: 80)
            let hc = UIHostingController(rootView: markerView)
            hc.view.backgroundColor = .clear
            hc.view.frame = CGRect(origin: .zero, size: CGSize(width: 80, height: 80))

            marker.iconView = hc.view
            markerViewCache[markerID] = hc.view
            cachedMarkerData[markerID] = currentMarkerData
        }
    }
}

class CustomClusterRenderer: GMUDefaultClusterRenderer {
    override func shouldRender(as cluster: GMUCluster, atZoom zoom: Float) -> Bool {
        return cluster.count > 1
    }
}

class POIItem: NSObject, GMUClusterItem {
    var position: CLLocationCoordinate2D
    var markerData: SimpleMarker

    init(position: CLLocationCoordinate2D, markerData: SimpleMarker) {
        self.position = position
        self.markerData = markerData
    }
}

struct MyCustomMarkerView: View {
    let text: String
    let imageURL: URL?
    let isSelected: Bool

    var body: some View {
        VStack {
            // Async image in a circle
            LazyImage(source: imageURL) { state in
                if let image = state.image {
                    image
                        .resizingMode(.aspectFill)
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                }
            }
            .shadow(radius: 4)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 4)
            )
            Text(text)
                .font(.caption2)
        }
    }
}
