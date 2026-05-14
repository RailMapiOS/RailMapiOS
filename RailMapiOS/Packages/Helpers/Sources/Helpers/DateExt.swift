//
//  DateExt.swift
//  Helpers
//
//  Created by Jérémie Patot on 15/11/2024.
//

import Foundation

//MARK: Date
public extension Date {
    func formattedTime(with format: String? = "HH:mm") -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = format
        return timeFormatter.string(from: self)
    }

    func timeRemainingDescription() -> String {
        let now = Date()
        let timeInterval = self.timeIntervalSince(now)

        if timeInterval > 0 {
            return timeInterval.formattedTimeRemaining()
        } else {
            // Looked up against the main app bundle's String Catalog so the
            // package contributes translatable copy without owning its own.
            return String(localized: "Already departed", bundle: .main, comment: "Shown when a journey's start date is in the past.")
        }
    }

    func duration(to endDate: Date) -> String {
        let interval = endDate.timeIntervalSince(self)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%02dh%02d", hours, minutes)
    }
}

//MARK: TimeInterval
public extension TimeInterval {
    func formattedTimeRemaining() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month, .day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading

        return formatter.string(from: self) ?? String(localized: "Unknown time", bundle: .main, comment: "Fallback when the duration formatter returns nil.")
    }

    func formattedTimeRemainingDelayed() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading

        return formatter.string(from: self) ?? String(localized: "Unknown time", bundle: .main, comment: "Fallback when the duration formatter returns nil.")
    }
}
