//
//  Color+Extension.swift
//  CasaVault
//
//  Created by Lior Shor on 26/02/2026.
//

import SwiftUI
import UIKit

extension Color {
    enum AppColor: String, CaseIterable {
        case blue = "AppBlue"
        case cyan = "AppCyan"
        case teal = "AppTeal"
        case mint = "AppMint"
        case green = "AppGreen"
        case orange = "AppOrange"
        case monochrome = "AppMonochrome"

        var color: Color {
            switch self {
            case .blue:       return Color(uiColor: .systemBlue)
            case .cyan:       return Color(uiColor: .systemCyan)
            case .teal:       return Color(uiColor: .systemTeal)
            case .mint:       return Color(uiColor: .systemMint)
            case .green:      return Color(uiColor: .systemGreen)
            case .orange:     return Color(uiColor: .systemOrange)
            case .monochrome: return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .white : .black })
            }
        }

        // Contrasting color for overlay icons (e.g. checkmark) on top of the color circle
        var checkmarkColor: Color {
            switch self {
            case .monochrome: return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .black : .white })
            default: return .white
            }
        }
    }

    init(_ resource: AppColor) {
        self = resource.color
    }

    init(resource: AppColor) {
        self = resource.color
    }

    static func appAccentColor(named name: String) -> Color {
        AppColor(rawValue: name)?.color ?? Color(uiColor: .systemBlue)
    }
}
