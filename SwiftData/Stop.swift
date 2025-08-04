//
//  Stop.swift
//  
//
//  Created by Jérémie Patot on 04/08/2025.
//
//

public import Foundation
public import SwiftData


@Model public class Stop {
    var arrivalTimeUTC: Date?
    var departureTimeUTC: Date?
    var status: String?
    var journey: Journey?
    @Relationship(inverse: \StopInfos.stop) var stopinfo: StopInfos?
    public init() {

    }
    
}
