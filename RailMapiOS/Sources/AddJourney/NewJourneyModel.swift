//
//  NewJourneyModel.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import Foundation

struct NewJourneyModel {
    var startDate: Date
    var endDate: Date
    var headsign: String
    var idVehicleJourney: String
    var company: String
    
    var stops: [NewStop]
    
    init(
        startDate: Date,
        endDate: Date,
        headsign: String,
        idVehicleJourney: String,
        company: String,
        stops: [NewStop] = []
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.headsign = headsign
        self.idVehicleJourney = idVehicleJourney
        self.company = company
        self.stops = stops
    }
}

struct NewStop {
    var arrivalTimeUTC: Date
    var departureTimeUTC: Date
    var status: String
    var stopInfo: NewStopInfo?
    
    
    init(
        id: UUID = UUID(),
        arrivalTimeUTC: Date,
        departureTimeUTC: Date,
        status: String,
        stopInfo: NewStopInfo
    ) {
        self.arrivalTimeUTC = arrivalTimeUTC
        self.departureTimeUTC = departureTimeUTC
        self.status = status
        self.stopInfo = stopInfo
    }
}

struct NewStopInfo {
    let id: String
    let label: String
    let latitude: Double
    let longitude: Double
    let adress: String
    let pickUpAllowed: Bool
    let dropOffAllowed: Bool
    let skippedStop: Bool
    
    
    init(
        id: String,
        label: String,
        latitude: Double,
        longitude: Double,
        adress: String,
        pickUpAllowed: Bool,
        dropOffAllowed: Bool,
        skippedStop: Bool
    ) {
        self.id = id
        self.label = label
        self.latitude = latitude
        self.longitude = longitude
        self.adress = adress
        self.pickUpAllowed = pickUpAllowed
        self.dropOffAllowed = dropOffAllowed
        self.skippedStop = skippedStop
    }
}

