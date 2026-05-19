//
//  Color+Extension.swift
//  StorePass
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

        var color: Color {
            switch self {
            case .blue:   return Color(uiColor: .systemBlue)
            case .cyan:   return Color(uiColor: .systemCyan)
            case .teal:   return Color(uiColor: .systemTeal)
            case .mint:   return Color(uiColor: .systemMint)
            case .green:  return Color(uiColor: .systemGreen)
            case .orange: return Color(uiColor: .systemOrange)
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
