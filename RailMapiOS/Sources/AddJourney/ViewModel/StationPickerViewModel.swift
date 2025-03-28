//
//  StationPickerViewModel.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 17/01/2025.
//

import Foundation
import CoreLocation
import MapKit

@MainActor
class StationPickerViewModel: ObservableObject {
    @Published var pickedJourney: DateRow
    @Published var cityNames: [String: String] = [:]
    
    private let geocoder = CLGeocoder()
    private var geocodingTasks: [String: Task<Void, Never>] = [:]
    
    init(pickedJourney: DateRow) {
        self.pickedJourney = pickedJourney
    }
    
    func fetchCityName(for stopPoint: StopPoint) {
        geocodingTasks[stopPoint.id]?.cancel()
        
        let localGeocoder = geocoder
        let stopPointId = stopPoint.id
        
        let task = Task { [weak self] in
            guard let self = self else { return }
            
            guard let lat = self.convertToDouble(from: stopPoint.coord.lat),
                  let lon = self.convertToDouble(from: stopPoint.coord.lon) else {
                LogManager.error("Invalid coordinates for StopPoint \(stopPointId)")
                return
            }
            
            let location = CLLocation(latitude: lat, longitude: lon)
            LogManager.debug("Fetching city for StopPoint \(stopPointId) at coordinates: \(lat), \(lon)")
            
            do {
                let placemarks = try await localGeocoder.reverseGeocodeLocation(location)
                
                if Task.isCancelled { return }
                
                if let placemark = placemarks.first {
                    LogManager.debug("Placemark details: \(placemark)")
                    if let city = placemark.locality {
                        LogManager.debug("City found: \(city)")
                        await MainActor.run {
                            self.cityNames[stopPointId] = city
                        }
                    } else {
                        LogManager.error("Locality not found for \(stopPointId), full placemark: \(placemark)")
                    }
                } else {
                    LogManager.error("No placemarks found")
                }
            } catch {
                LogManager.error("Geocoding error: \(error)")
            }
        }
        
        geocodingTasks[stopPoint.id] = task
    }

    
    func cancelAllGeocoding() {
        for task in geocodingTasks.values {
            task.cancel()
        }
        geocodingTasks.removeAll()
    }
    
    deinit {
        for task in geocodingTasks.values {
            task.cancel()
        }
        geocodingTasks.removeAll()
    }
    
    private func convertToDouble(from string: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        
        if let number = formatter.number(from: string) {
            return number.doubleValue
        } else {
            LogManager.error("Conversion failed for string: \(string)")
            return nil
        }
    }
}
