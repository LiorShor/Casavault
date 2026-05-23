//
//  RoomIconsService.swift
//  StorePass
//

import Foundation
import Dependencies

struct RoomIconsService {
    var getIcon: (String, UUID?) -> String?
    var setIcon: (String?, String, UUID?) -> Void
    var renameRoom: (String, String, UUID?) -> Void
    var deleteRoom: (String, UUID?) -> Void
    var getDeletedRooms: (UUID?) -> Set<String>
    var markRoomDeleted: (String, UUID?) -> Void
    var markRoomRestored: (String, UUID?) -> Void
    var getCustomRooms: (UUID?) -> Set<String>
    var addCustomRoom: (String, UUID?) -> Void
    var removeCustomRoom: (String, UUID?) -> Void
}

private func roomIconsKey(for homeId: UUID?) -> String {
    "roomIcons_\(homeId?.uuidString ?? "global")"
}

private func deletedRoomsKey(for homeId: UUID?) -> String {
    "deletedRooms_\(homeId?.uuidString ?? "global")"
}

private func customRoomsKey(for homeId: UUID?) -> String {
    "customRooms_\(homeId?.uuidString ?? "global")"
}

private func loadIcons(for homeId: UUID?) -> [String: String] {
    let key = roomIconsKey(for: homeId)
    return (UserDefaults.standard.dictionary(forKey: key) as? [String: String]) ?? [:]
}

private func saveIcons(_ icons: [String: String], for homeId: UUID?) {
    UserDefaults.standard.set(icons, forKey: roomIconsKey(for: homeId))
}

private func loadDeletedRooms(for homeId: UUID?) -> Set<String> {
    Set(UserDefaults.standard.stringArray(forKey: deletedRoomsKey(for: homeId)) ?? [])
}

private func saveDeletedRooms(_ rooms: Set<String>, for homeId: UUID?) {
    UserDefaults.standard.set(Array(rooms), forKey: deletedRoomsKey(for: homeId))
}

private func loadCustomRooms(for homeId: UUID?) -> Set<String> {
    Set(UserDefaults.standard.stringArray(forKey: customRoomsKey(for: homeId)) ?? [])
}

private func saveCustomRooms(_ rooms: Set<String>, for homeId: UUID?) {
    UserDefaults.standard.set(Array(rooms), forKey: customRoomsKey(for: homeId))
}

extension RoomIconsService: DependencyKey {
    static let liveValue = RoomIconsService(
        getIcon: { roomName, homeId in
            loadIcons(for: homeId)[roomName]
        },
        setIcon: { icon, roomName, homeId in
            var icons = loadIcons(for: homeId)
            if let icon {
                icons[roomName] = icon
            } else {
                icons.removeValue(forKey: roomName)
            }
            saveIcons(icons, for: homeId)
        },
        renameRoom: { oldName, newName, homeId in
            var icons = loadIcons(for: homeId)
            if let icon = icons.removeValue(forKey: oldName) {
                icons[newName] = icon
            }
            saveIcons(icons, for: homeId)
        },
        deleteRoom: { roomName, homeId in
            var icons = loadIcons(for: homeId)
            icons.removeValue(forKey: roomName)
            saveIcons(icons, for: homeId)
        },
        getDeletedRooms: { homeId in
            loadDeletedRooms(for: homeId)
        },
        markRoomDeleted: { roomName, homeId in
            var rooms = loadDeletedRooms(for: homeId)
            rooms.insert(roomName)
            saveDeletedRooms(rooms, for: homeId)
        },
        markRoomRestored: { roomName, homeId in
            var rooms = loadDeletedRooms(for: homeId)
            rooms.remove(roomName)
            saveDeletedRooms(rooms, for: homeId)
        },
        getCustomRooms: { homeId in
            loadCustomRooms(for: homeId)
        },
        addCustomRoom: { roomName, homeId in
            var rooms = loadCustomRooms(for: homeId)
            rooms.insert(roomName)
            saveCustomRooms(rooms, for: homeId)
        },
        removeCustomRoom: { roomName, homeId in
            var rooms = loadCustomRooms(for: homeId)
            rooms.remove(roomName)
            saveCustomRooms(rooms, for: homeId)
        }
    )

    static let testValue = liveValue
}

extension DependencyValues {
    var roomIconsService: RoomIconsService {
        get { self[RoomIconsService.self] }
        set { self[RoomIconsService.self] = newValue }
    }
}
