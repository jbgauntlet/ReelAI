import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1y" : "\(years)y"
        }
        
        if let months = components.month, months > 0 {
            return months == 1 ? "1mo" : "\(months)mo"
        }
        
        if let days = components.day, days > 0 {
            if days >= 7 {
                let weeks = days / 7
                return weeks == 1 ? "1w" : "\(weeks)w"
            }
            return days == 1 ? "1d" : "\(days)d"
        }
        
        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1h" : "\(hours)h"
        }
        
        if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1m" : "\(minutes)m"
        }
        
        if let seconds = components.second, seconds > 0 {
            return seconds < 30 ? "now" : "\(seconds)s"
        }
        
        return "now"
    }
} 