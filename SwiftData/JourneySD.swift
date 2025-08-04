//
//  Journey.swift
//  
//
//  Created by Jérémie Patot on 04/08/2025.
//
//

public import Foundation
public import SwiftData


@Model public class JourneySD {
    public var id: UUID?
    var archived: Bool? = false
    var company: String?
    var endDate: Date?
    var headsign: String?
    var idVehiculeJourney: String?
    var startDate: Date?
    @Relationship(inverse: \StopSD.journey) var stops: [StopSD]?
    public init() {

    }
    
}
