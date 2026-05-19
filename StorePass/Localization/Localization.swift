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
    case darkModeSwitch
    case exportPasswords
    case settings
    case language
    case appearance
    case general
    case data
    case deviceName
    case device
    case password
    case created
    case lastUpdated
    case information
    case cancel
    case save
    case edit
    case languageSettingsFooter
    case themeSystem
    case themeLight
    case themeDark
    case languageEnglish
    case languageHebrew
    case homeKitImport
    case importButton
    case loadingHomeKitDevices
    case homeKitLoadError
    case homeKitPermissionDenied
    case homeKitPermissionDeniedDescription
    case openSettings
    case retry
    case selectDevicesToImport
    case homeKitImportFooter
    case noHomeKitDevices
    case noHomeKitDevicesDescription
    case groupByAll
    case groupByRoom
    case noRoom
    case grouping
    case gridView
    case listView
    case delete
    case done
    case homes
    case myHomes
    case addNewHome
    case homeName
    case enterHomeName
    case importFromHomeKit
    case fromHomeKit
    case actions
    case homesFooter
    case selectHome
    case noHomeSelected
    case noHomeSelectedMessage
    case goToHomes
    case room
    case selectRoom
    case addNewRoom
    case roomName
    case noHomesYet
    case noHomesYetMessage
    case icon
    case noIcon
    case selectIcon
    case appName
    case searchPasswords
    case notes
    case noNotes
    case attachments
    case addAttachment
    case noAttachments
    case takePhoto
    case chooseFromLibrary
    case accentColor
    case rateApp
    case support
    case deleteDevice
    case homeKitSetupCode
    case passwordValidationError
    case addDeviceOptions
    case addNewDevice
    case importFromSmartHome
    case deleteDeviceConfirmation
    case scanQRCode
    case options
    case selectAll
    case deselectAll
    case security
    case biometricLock
    case biometricLockFaceID
    case biometricLockTouchID
    case biometricLockDescription
    case biometricLockReason
    case unlock
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
