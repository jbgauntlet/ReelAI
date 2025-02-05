//
//  ColorPalette.swift
//  ReelAI
//
//

import Foundation
import UIKit

class ColorPalette {
    // New colors
    static let newSkyBlue = UIColor(hex: "#63A7F6")
    static let midnightBlue = UIColor(hex: "#001328")
    static let slateBlue = UIColor(hex: "#5E6D78")
    static let iceBlue = UIColor(hex: "#EBF0F6")
    static let newSteelBlue = UIColor(hex: "#425C72")
    static let paleBlue = UIColor(hex: "#EBECEF")
    static let newPowderBlue = UIColor(hex: "#EDF2FA")
    static let navyBlue = UIColor(hex: "#023456")
    static let tealBlue = UIColor(hex: "#004C6B")
    
    // Main theme
    static let lightBlue = UIColor(hex: "#ADD8E6")
    static let powderBlue = UIColor(hex: "#B0E0E6")
    
    // Lights
    static let skyBlue = UIColor(hex: "#87CEEB")
    static let softBlueGray = UIColor(hex: "#E0FFFF")
    static let pureWhite = UIColor(hex: "#FFFFFF")
    static let blueOffWhite = UIColor(hex: "#F8F8FF")
    static let offWhite = UIColor(hex: "#FAFAFA")

    // Darks
    static let steelBlue = UIColor(hex: "#4682B4")
    static let darkBlue = UIColor(hex: "#1C1F4A")
    static let charcoal = UIColor(hex: "#2C2C2C")
    static let pureBlack = UIColor(hex: "#000000")
    
    // Grays
    static let silverGray = UIColor(hex: "#C0C0C0")
    static let mediumGray = UIColor(hex: "#A9A9A9")
    static let slateGray = UIColor(hex: "#708090")
    static let charcoalGray = UIColor(hex: "#2F4F4F")
    static let gunmetalGray = UIColor(hex: "#4B4B4B")
    static let whiteGray = UIColor(hex: "#F2F2F2")
    static let redWhiteGray = UIColor(hex: "#F2B7B7")
    static let tabBarGray = UIColor(hex: "#999999")
    
    // Tertiary colors
    static let softLavender = UIColor(hex: "#D8BFD8")
    static let paleGreen = UIColor(hex: "#98FB98")
    
    // Old palette
    static let lightBeige = UIColor(hex: "#FAF5DB")
    static let deepDarkBlue = UIColor(hex: "#000C27")
    static let slightlyDarkerBeige = UIColor(hex: "#E8E3C7")
    static let slightlyLighterDarkBlue = UIColor(hex: "#02163A")
    static let complementaryNeutral = UIColor(hex: "#A49E86")
    static let complementaryBlueGray = UIColor(hex: "#334D5C")
    static let goldAccent = UIColor(hex: "#D4AF37")
    static let lightYellowHighlight = UIColor(hex: "#F2E3B5")
    
    // 3rd Party color
    static let googleBlue = UIColor(hex: "#4185F3")
    static let facebookBlue = UIColor(hex: "#3B5996")
    static let appleBlack = UIColor(hex: "#010101")
    
    static let baylorGreen = UIColor(hex: "#154734")
    //static let baylorGold = UIColor(hex: "#FFB81C")
    static let baylorGold = UIColor(hex: "#FFF9EA")
    static let amazonCyan = UIColor(hex: "#82D7E2")
    static let amazonTeal = UIColor(hex: "#A6E7CE")
    
    static let blue0 = UIColor(hex: "#EDF2FA")
    static let blue1 = UIColor(hex: "#2EB4EF")
    static let blue2 = UIColor(hex: "#CEE3F3")
    static let blue3 = UIColor(hex: "#023C99")
    static let gray0 = UIColor(hex: "#505050")
    
    
    
    static let lightGray = UIColor(hex: "#EEEFF3")
    static let placeholderGray = UIColor(hex: "#50525E")
    static let successGreen = UIColor(hex: "#359624")
    static let gray = UIColor(hex: "#7F7F7F")
}

extension UIColor {
    convenience init(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        
        if hexString.hasPrefix("#") {
            scanner.currentIndex = hexString.index(after: hexString.startIndex)
        }
        
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        
        let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(color & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
