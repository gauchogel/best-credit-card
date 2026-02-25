//
//  CardColorExtensions.swift
//  Best Credit Card
//

import SwiftUI

extension CardColor {
    var gradient: LinearGradient {
        LinearGradient(
            colors: [startColor, endColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var startColor: Color {
        switch self {
        case .ocean:    return Color(red: 0/255,   green: 98/255,  blue: 209/255)
        case .midnight: return Color(red: 26/255,  green: 26/255,  blue: 110/255)
        case .gold:     return Color(red: 184/255, green: 134/255, blue: 11/255)
        case .onyx:     return Color(red: 28/255,  green: 28/255,  blue: 30/255)
        case .rose:     return Color(red: 194/255, green: 24/255,  blue: 91/255)
        case .forest:   return Color(red: 27/255,  green: 94/255,  blue: 32/255)
        case .slate:    return Color(red: 69/255,  green: 90/255,  blue: 100/255)
        case .crimson:  return Color(red: 139/255, green: 0/255,   blue: 0/255)
        }
    }

    var endColor: Color {
        switch self {
        case .ocean:    return Color(red: 0/255,   green: 198/255, blue: 255/255)
        case .midnight: return Color(red: 61/255,  green: 61/255,  blue: 191/255)
        case .gold:     return Color(red: 255/255, green: 215/255, blue: 0/255)
        case .onyx:     return Color(red: 74/255,  green: 74/255,  blue: 74/255)
        case .rose:     return Color(red: 240/255, green: 98/255,  blue: 146/255)
        case .forest:   return Color(red: 76/255,  green: 175/255, blue: 80/255)
        case .slate:    return Color(red: 120/255, green: 144/255, blue: 156/255)
        case .crimson:  return Color(red: 211/255, green: 47/255,  blue: 47/255)
        }
    }
}
