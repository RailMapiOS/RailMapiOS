// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation

/// A utility structure providing various date-related helper functions.
struct Datehelpers {
    
    /// Converts active periods in a given calendar to an array of `Date` objects in DDMMYY format.
       /// - Parameter calendar: The calendar object containing active periods and week pattern.
       /// - Returns: An array of `Date` objects representing the active periods, or `nil` if conversion fails.
    public func convertCalendarToDDMMYY(calendar: VehicleCalendar) -> [Date]? {
        guard let activePeriod = calendar.activePeriods.first else {
            return nil // Aucune période active
        }
        
        let weekDaysPattern = calendar.weekPattern
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        // Convertir les dates de début de din en objets Date
        guard let startDate = dateFormatter.date(from: activePeriod.begin),
              let endDate = dateFormatter.date(from: activePeriod.end) else {
            return nil // Impossible de convertir les dates
        }
        
        var currentDate = startDate
        var formattedDates : [Date] = []
        
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            let dayOfWeek = calendar.component(.weekday, from: currentDate)
            
            switch dayOfWeek {
            case 1 where calendar.weekdaySymbols[dayOfWeek - 1] == (weekDaysPattern.sunday ? "Sunday" : "prout") :
                formattedDates.append((currentDate))
            case 2 where calendar.weekdaySymbols[dayOfWeek - 1] == (weekDaysPattern.monday ? "Monday" : "prout") :
                formattedDates.append((currentDate))
            case 3 where calendar.weekdaySymbols[dayOfWeek - 1] == (weekDaysPattern.tuesday ? "Tuesday" : "prout") :
                formattedDates.append((currentDate))
            case 4 where calendar.weekdaySymbols[dayOfWeek - 1] == (weekDaysPattern.wednesday ? "Wednesday" : "prout") :
                formattedDates.append((currentDate))
            case 5 where calendar.weekdaySymbols[dayOfWeek - 1] == (weekDaysPattern.thursday ? "Thursday" : "prout") :
                formattedDates.append((currentDate))
            case 6 where calendar.weekdaySymbols[dayOfWeek - 1] == (weekDaysPattern.friday ? "Friday" : "prout") :
                formattedDates.append((currentDate))
            case 7 where calendar.weekdaySymbols[dayOfWeek - 1] == (weekDaysPattern.saturday ? "Saturday" : "prout") :
                formattedDates.append((currentDate))
            default:
                break
            }
            
            // Passe au jour suivvant
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? Date()
            
        }
        
        return formattedDates
        
    }
    
    /// Formats a `Date` object into a string with the format "dd/MM/yy".
       /// - Parameter date: The `Date` object to be formatted.
       /// - Returns: A string representing the formatted date.
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        return dateFormatter.string(from: date)
    }
    
    /// Converts a date string from "dd/MM/yyyy" format to "dd MMMM" format.
       /// - Parameter dateString: The date string to be converted.
       /// - Returns: A string representing the date in "dd MMMM" format, or "N/A" if conversion fails.
    func formatDateLettre(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        if let date = dateFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "dd MMMM"
            return outputFormatter.string(from: date)
        } else {
            return "N/A"
        }
    }
    
    /// Extracts a name from an input string based on a specific pattern.
       /// - Parameter input: The input string containing the name.
       /// - Returns: The extracted name, or an empty string if extraction fails.
    func extractName(from input: String) -> String {
        let pattern = ".*:(OCE[\\w ]+)-\\d+"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            if let match = regex.firstMatch(in: input, options: [], range: NSRange(input.startIndex..., in: input)) {
                let range = Range(match.range(at: 1), in: input)!
                var extractedString = String(input[range])
                
                if extractedString.hasPrefix("OCE") {
                    extractedString = String(extractedString.dropFirst(3))
                }
                
                return extractedString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("Rege Error: \(error)")
        }
        return ""
    }
    
    /// Formats a time string from "HHmmss" format to "HH:mm" format.
        /// - Parameter dateString: The time string to be formatted.
        /// - Returns: A string representing the formatted time, or an error message if conversion fails.
    func formattedHour(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmss"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        if let date = formatter.date(from: dateString) {
            return dateFormatter.string(from: date)
        }
        return "Erreur, mauvais format de date"
    }
}
