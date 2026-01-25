//
//  Localization.swift
//  StorePass
//
//  Created by Lior Shor on 15/01/2026.
//

import Foundation
import Localization
import SwiftUI

@Localizable
public enum Localization {
    case addPassword
    case passwords
    case passwordDetails
    case setupCode
    case setupCodeInstructions
    case enterDeviceTitle
    case deviceCodePlaceholder
    case deviceNamePlaceholder
    case continueButton
    case closeButton
}

public extension String {
    static func localized(_ key: Localization) -> Self {
        key.localized
    }
}
public extension LocalizedStringKey {
    static func localized(_ key: Localization) -> Self {
        LocalizedStringKey(key.localized)
    }
}
