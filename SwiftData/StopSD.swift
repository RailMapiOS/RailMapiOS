//
//  Stop.swift
//  
//
//  Created by Jérémie Patot on 04/08/2025.
//
//

public import Foundation
public import SwiftData


@Model public class StopSD {
    var arrivalTimeUTC: Date?
    var departureTimeUTC: Date?
    var status: String?
    var journey: JourneySD?
    @Relationship(inverse: \StopInfosSD.stop) var stopinfo: StopInfosSD?
    public init() {

    }
    
}
