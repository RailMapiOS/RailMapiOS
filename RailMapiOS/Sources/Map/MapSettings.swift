//
//  MapSettings.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 28/02/2025.
//

import SwiftUI
import MapKit

class MapSettings: ObservableObject {
    @Published var mapType: MKMapType = .standard
    @Published var showsUserLocation: Bool = true
}
