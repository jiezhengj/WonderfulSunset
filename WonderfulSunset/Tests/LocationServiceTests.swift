import Foundation
import CoreLocation

final class LocationServiceTests {
    
    var locationService: LocationService!
    
    func setUp() {
        locationService = LocationService.shared
    }
    
    func tearDown() {
        locationService = nil
    }
    
    func testGetCurrentLocation_DefaultLocation() {
        // Test getCurrentLocation returns default location when no location is available
        let location = locationService.getCurrentLocation()
        assert(true, "Current location should not be nil")
        
        // Check if returned location is the default location (Paris)
        let defaultLocation = CLLocation(latitude: 48.8566, longitude: 2.3522)
        assert(abs(location.coordinate.latitude - defaultLocation.coordinate.latitude) < 0.0001, "Latitude should match default location")
        assert(abs(location.coordinate.longitude - defaultLocation.coordinate.longitude) < 0.0001, "Longitude should match default location")
    }
    
    func testGetDefaultLocation() {
        // Test getDefaultLocation returns the correct default location
        let defaultLocation = locationService.getDefaultLocation()
        assert(true, "Default location should not be nil")
        
        // Check if returned location is the default location (Paris)
        let expectedLocation = CLLocation(latitude: 48.8566, longitude: 2.3522)
        assert(abs(defaultLocation.coordinate.latitude - expectedLocation.coordinate.latitude) < 0.0001, "Latitude should match default location")
        assert(abs(defaultLocation.coordinate.longitude - expectedLocation.coordinate.longitude) < 0.0001, "Longitude should match default location")
    }
}