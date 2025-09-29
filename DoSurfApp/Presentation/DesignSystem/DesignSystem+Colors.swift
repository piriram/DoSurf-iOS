//
//  DesignSystem+Colors.swift
//  DoSurfApp
//
//  Created by Assistant on 9/28/25.
//

import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - UIColor + Design System Palette
extension UIColor {
    /// Initialize a UIColor from a hex integer (e.g., 0x004AC7) and optional alpha.
    /// Values are interpreted as sRGB.
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    /// Initialize a UIColor from a hex string (e.g., "004AC7", "#004AC7", "0x004AC7").
    /// Supports 3, 4, 6, or 8 hex digits. When 8 digits are provided, they are interpreted as RRGGBBAA.
    /// Values are interpreted as sRGB.
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        // Normalize input: trim spaces, remove common prefixes, uppercase
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        if hexString.hasPrefix("0X") {
            hexString.removeFirst(2)
        }
        // Expand shorthand forms (#RGB, #RGBA)
        if hexString.count == 3 || hexString.count == 4 {
            let chars = Array(hexString)
            let expanded = chars.map { String(repeating: $0, count: 2) }.joined()
            hexString = expanded
        }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = alpha
        var value: UInt64 = 0
        let scanned = Scanner(string: hexString).scanHexInt64(&value)
        if scanned {
            switch hexString.count {
            case 6: // RRGGBB
                r = CGFloat((value & 0xFF0000) >> 16) / 255.0
                g = CGFloat((value & 0x00FF00) >> 8) / 255.0
                b = CGFloat(value & 0x0000FF) / 255.0
            case 8: // RRGGBBAA
                r = CGFloat((value & 0xFF000000) >> 24) / 255.0
                g = CGFloat((value & 0x00FF0000) >> 16) / 255.0
                b = CGFloat((value & 0x0000FF00) >> 8) / 255.0
                let parsedA = CGFloat(value & 0x000000FF) / 255.0
                a = a * parsedA // combine provided alpha with parsed alpha
            default:
                break
            }
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    // MARK: Brand & Icon Colors
    static var surfBlue: UIColor { UIColor(hex: 0x004AC7) }        // #004AC7
    static var iconBlue: UIColor { UIColor(hex: 0x4B88EF) }        // #4B88EF
    static var iconSkyblue: UIColor { UIColor(hex: 0x38ABFF) }     // #38ABFF
    static var iconGreen: UIColor { UIColor(hex: 0x20B137) }       // #20B137
    static var iconPurple: UIColor { UIColor(hex: 0xB097F6) }      // #B097F6
    static var iconWaterOrange: UIColor { UIColor(hex: 0xFFB891) } // #FFB891
    static var iconStarOrange: UIColor { UIColor(hex: 0xEA8F5B) }  // #EA8F5B
    
    // MARK: Background / Neutrals
    static var brightGray: UIColor { UIColor(hex: 0xF6F7F9) }      // #F6F7F9
    static var backgroundGray: UIColor { UIColor(hex: 0xDEDFE4) }  // #DEDFE4
    static var backgroundSkyblue: UIColor { UIColor(hex: 0xCCDBF4) } // #CCDBF4
    static var backgroundWhite: UIColor { UIColor(hex:0xEFF1F6)}
    static var backgroundHeader: UIColor { UIColor(hex:0xE5EDF9)}
}

// MARK: - SwiftUI Color Mirrors
#if canImport(SwiftUI)
extension Color {
    /// Initialize a SwiftUI Color from a hex string (e.g., "004AC7", "#004AC7", "0x004AC7").
    /// Mirrors UIColor's hex parsing rules.
    init(hex: String, alpha: Double = 1.0) {
        self.init(UIColor(hex: hex, alpha: CGFloat(alpha)))
    }
    
    static var surfBlue: Color { Color(UIColor.surfBlue) }
    static var iconBlue: Color { Color(UIColor.iconBlue) }
    static var iconSkyblue: Color { Color(UIColor.iconSkyblue) }
    static var iconGreen: Color { Color(UIColor.iconGreen) }
    static var iconPurple: Color { Color(UIColor.iconPurple) }
    static var iconWaterOrange: Color { Color(UIColor.iconWaterOrange) }
    static var iconStarOrange: Color { Color(UIColor.iconStarOrange) }
    
    static var brightGray: Color { Color(UIColor.brightGray) }
    static var backgroundGray: Color { Color(UIColor.backgroundGray) }
    static var backgroundSkyblue: Color { Color(UIColor.backgroundSkyblue) }
}
#endif
