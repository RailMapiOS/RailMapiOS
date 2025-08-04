//
//  StopInfo.swift
//  
//
//  Created by Jérémie Patot on 04/08/2025.
//
//

public import Foundation
public import SwiftData


@Model public class StopInfosSD {
    public var id: String?
    var adress: String?
    var dropOffAllowed: Bool?
    var label: String?
    var latitude: Double?
    var longitude: Double? = 0.0
    var pickUpAllowed: Bool?
    var skippedStop: Bool?
    var stop: StopSD?
    public init() {

    }
    
}
