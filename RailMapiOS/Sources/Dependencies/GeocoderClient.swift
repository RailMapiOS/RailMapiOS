//
//  GeocoderClient.swift
//  RailMapiOS
//
//  TCA Dependency wrapping CLGeocoder for reverse geocoding.
//

import CoreLocation
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct GeocoderClient {
    var reverseGeocode: @Sendable (_ latitude: Double, _ longitude: Double) async throws -> String? = { _, _ in nil }
}

extension GeocoderClient: DependencyKey {
    static let liveValue = Self(
        reverseGeocode: { latitude, longitude in
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.locality
        }
    )
}

extension DependencyValues {
    var geocoderClient: GeocoderClient {
        get { self[GeocoderClient.self] }
        set { self[GeocoderClient.self] = newValue }
    }
}
