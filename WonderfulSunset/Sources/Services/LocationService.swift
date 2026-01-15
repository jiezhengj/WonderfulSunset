import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    static let shared = LocationService()
    
    @Published var currentLocation: CLLocation?
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let defaultLocation = CLLocation(latitude: 48.8566, longitude: 2.3522) // Paris, France
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() -> CLLocation {
        return currentLocation ?? defaultLocation
    }
    
    func getDefaultLocation() -> CLLocation {
        return defaultLocation
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            locationStatus = manager.authorizationStatus
            errorMessage = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
        currentLocation = defaultLocation
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            errorMessage = "Location access denied. Using default location: Paris"
            currentLocation = defaultLocation
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}