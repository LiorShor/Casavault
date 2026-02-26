//
//  Color+Extension.swift
//  StorePass
//
//  Created by Lior Shor on 26/02/2026.
//

import SwiftUI

extension Color {
    enum AppColor: String {
        case blue = "AppBlue"
        case cyan = "AppCyan"
        case teal = "AppTeal"
        case mint = "AppMint"
        case green = "AppGreen"
        case orange = "AppOrange"
    }
    
    init(_ resource: AppColor) {
        self.init(resource.rawValue)
    }
    
    init(resource: AppColor) {
        self.init(resource.rawValue)
    }
}
