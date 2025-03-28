//
//  AccessibilityID.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 28/03/2025.
//

//  AccessibilityID.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 28/03/2025.
//

import Foundation
import CoreData

public enum AccessibilityID {
    public enum BottomSheetView {
        static let navigationStack = "railmapapp.bottomsheetview.navigation_stack"
        static let searchBar = "railmapapp.bottomsheetview.search_bar"
        static let userProfileButton = "railmapapp.bottomsheetview.user_profile_button"
        static let journeyList = "railmapapp.bottomsheetview.journey_list"
        static let toolbarTitle = "railmapapp.bottomsheetview.toolbar_title"
        static let emptyState = "railmapapp.bottomsheetview.empty_state"
        
        public enum JourneyRow {
            static func base(for journeyID: NSManagedObjectID) -> String {
                "railmapapp.bottomsheetview.journeyrow.\(journeyID.uriRepresentation().lastPathComponent)"
            }
        }
        
        public enum Sheet {
            static let signInView = "railmapapp.bottomsheetview.sheet.signin"
            static let accountView = "railmapapp.bottomsheetview.sheet.account"
        }
    }
    
    public enum AddTicketView {
        static let vStack = "railmapapp.addticketview.v_stack"
        static let datePicker = "railmapapp.addticketview.date_picker"
        static let stationPicker = "railmapapp.addticketview.station_picker"
        static let confirmationPicker = "railmapapp.addticketview.confirmation_picker"
        static let emptyState = "railmapapp.addticketview.empty_state"
        static let searchField = "railmapapp.addticketview.search_field"
        
        public enum DateRow {
            static func base(for date: Date) -> String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd"
                return "railmapapp.addticketview.daterow.\(formatter.string(from: date))"
            }
        }
    }
    
    enum Common {
        static let backButton = "railmapapp.common.back_button"
        static let closeButton = "railmapapp.common.close_button"
        static let confirmationButton = "railmapapp.common.confirmation_button"
    }
}
