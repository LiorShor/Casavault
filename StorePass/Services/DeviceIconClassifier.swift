//
//  DeviceIconClassifier.swift
//  StorePass
//
//  Created by Lior Shor on 18/05/2026.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable(description: "Category of a smart home device")
private enum DeviceCategory {
    case airConditioner
    case light
    case lock
    case fan
    case television
    case speaker
    case thermostat
    case camera
    case outlet
    case smartSwitch
    case sensor
    case blinds
    case airPurifier
    case humidifier
    case garage
    case doorbell
    case heater
    case other
}

@available(iOS 26.0, *)
private extension DeviceCategory {
    var sfSymbolName: String {
        switch self {
        case .airConditioner: return "air.conditioner.horizontal.fill"
        case .light:          return "lightbulb.fill"
        case .lock:           return "lock.fill"
        case .fan:            return "fan.fill"
        case .television:     return "tv.fill"
        case .speaker:        return "speaker.wave.2.fill"
        case .thermostat:     return "thermometer.medium"
        case .camera:         return "camera.fill"
        case .outlet:         return "poweroutlet.type.h.square.fill"
        case .smartSwitch:    return "switch.2"
        case .sensor:         return "sensor.fill"
        case .blinds:         return "window.ceiling.closed"
        case .airPurifier:    return "air.purifier.fill"
        case .humidifier:     return "humidifier.fill"
        case .garage:         return "door.garage.closed"
        case .doorbell:       return "bell.fill"
        case .heater:         return "heater.vertical.fill"
        case .other:          return "homekit"
        }
    }
}

private func _classifyDeviceIconImpl(deviceName: String) async -> String? {
    guard SystemLanguageModel.default.isAvailable else { return nil }
    let session = LanguageModelSession(
        instructions: """
        Classify smart home device names into a single category.
        Common mappings: AC/מזגן = airConditioner, bulb/נורה/lamp = light,
        lock/מנעול = lock, fan/מאוורר = fan, TV/טלוויזיה = television,
        speaker/רמקול/HomePod = speaker, curtain/וילון/shutter = blinds,
        doorbell/פעמון = doorbell, heater/חימום/radiator = heater,
        switch/מתג = smartSwitch, sensor/חיישן = sensor,
        purifier/מטהר = airPurifier, humidifier/מפזר = humidifier,
        garage/מוסך = garage.
        """
    )
    do {
        let response = try await session.respond(
            to: "Device name: \(deviceName)",
            generating: DeviceCategory.self
        )
        return response.content.sfSymbolName
    } catch {
        return nil
    }
}
#endif

func classifyDeviceIcon(deviceName: String) async -> String? {
    return await _classifyDeviceIconImpl(deviceName: deviceName)
}
