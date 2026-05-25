//
//  LocationManager.swift
//  E-Presensi
//

import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var isAuthorized = false
    @Published var isGpsEnabled = CLLocationManager.locationServicesEnabled()
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        refreshAuthorizationStatus()
    }

    func start() {
        isGpsEnabled = CLLocationManager.locationServicesEnabled()
        guard isGpsEnabled else { return }
        manager.requestWhenInUseAuthorization()
        refreshAuthorizationStatus()
        if isAuthorized {
            manager.startUpdatingLocation()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    func refreshServices() {
        isGpsEnabled = CLLocationManager.locationServicesEnabled()
        refreshAuthorizationStatus()
        if !isGpsEnabled {
            location = nil
        }
    }

    private func refreshAuthorizationStatus() {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }

    private func evaluate(_ location: CLLocation) {
        self.location = location
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        evaluate(latest)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshAuthorizationStatus()
        if isAuthorized, isGpsEnabled {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            isAuthorized = false
        }
    }
}
