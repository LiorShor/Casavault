//
//  RoomIconClassifier.swift
//  StorePass
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable(description: "Category of a room in a home")
private enum RoomCategory {
    case bedroom
    case kitchen
    case bathroom
    case livingRoom
    case diningRoom
    case garage
    case office
    case gym
    case garden
    case laundry
    case hallway
    case nursery
    case guestRoom
    case storage
    case mediaRoom
    case balcony
    case other
}

@available(iOS 26.0, *)
private extension RoomCategory {
    var sfSymbolName: String {
        switch self {
        case .bedroom:    return "bed.double.fill"
        case .kitchen:    return "fork.knife"
        case .bathroom:   return "shower.fill"
        case .livingRoom: return "sofa.fill"
        case .diningRoom: return "chair.fill"
        case .garage:     return "car.fill"
        case .office:     return "desktopcomputer"
        case .gym:        return "figure.run"
        case .garden:     return "leaf.fill"
        case .laundry:    return "washer.fill"
        case .hallway:    return "door.left.hand.open"
        case .nursery:    return "figure.child"
        case .guestRoom:  return "person.fill"
        case .storage:    return "archivebox.fill"
        case .mediaRoom:  return "tv.fill"
        case .balcony:    return "sun.max.fill"
        case .other:      return "house.fill"
        }
    }
}

private func _classifyRoomIconImpl(roomName: String) async -> String? {
    guard SystemLanguageModel.default.isAvailable else { return nil }
    let session = LanguageModelSession(
        instructions: """
        Classify room names in a home into a single category.
        Common mappings: bedroom/חדר שינה/master bedroom = bedroom, kitchen/מטבח = kitchen,
        bathroom/אמבטיה/toilet/שירותים = bathroom, living room/סלון/lounge = livingRoom,
        dining room/פינת אוכל = diningRoom, garage/מוסך/parking = garage,
        office/study/משרד/חדר עבודה = office, gym/חדר כושר/fitness = gym,
        garden/yard/גינה/חצר/outdoor = garden, laundry/כביסה/utility = laundry,
        hallway/entrance/מסדרון/כניסה/corridor = hallway,
        nursery/kids room/חדר ילדים/children = nursery,
        guest room/חדר אורחים = guestRoom, storage/מחסן/pantry = storage,
        media room/TV room/חדר טלוויזיה = mediaRoom, balcony/מרפסת/patio = balcony.
        """
    )
    do {
        let response = try await session.respond(
            to: "Room name: \(roomName)",
            generating: RoomCategory.self
        )
        return response.content.sfSymbolName
    } catch {
        return nil
    }
}
#endif

let allRoomIcons: [String] = [
    "bed.double.fill",
    "fork.knife",
    "shower.fill",
    "sofa.fill",
    "chair.fill",
    "car.fill",
    "desktopcomputer",
    "figure.run",
    "leaf.fill",
    "washer.fill",
    "door.left.hand.open",
    "figure.child",
    "person.fill",
    "archivebox.fill",
    "tv.fill",
    "sun.max.fill",
    "house.fill"
]

func classifyRoomIcon(roomName: String) async -> String? {
    await _classifyRoomIconImpl(roomName: roomName)
}
