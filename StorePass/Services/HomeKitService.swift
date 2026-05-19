//
//  HomeKitService.swift
//  StorePass
//
//  Created by Lior Shor on 06/02/2026.
//

import Foundation
import HomeKit
import Dependencies

enum HomeKitError: Error, LocalizedError, Equatable {
    case permissionDenied

    var errorDescription: String? { "HomeKit access denied" }
}

/// Represents a HomeKit accessory that can be imported
struct HomeKitDevice: Equatable, Identifiable {
    let id: UUID
    let name: String
    let roomName: String?
    let categoryType: String
    let uniqueIdentifier: UUID

    init(id: UUID = UUID(), name: String, roomName: String?, categoryType: String, uniqueIdentifier: UUID) {
        self.id = id
        self.name = name
        self.roomName = roomName
        self.categoryType = categoryType
        self.uniqueIdentifier = uniqueIdentifier
    }

    init(from accessory: HMAccessory) {
        self.init(
            name: accessory.name,
            roomName: accessory.room?.name,
            categoryType: accessory.category.localizedDescription,
            uniqueIdentifier: accessory.uniqueIdentifier
        )
    }
}

/// Represents a HomeKit home that can be imported
struct HomeKitHome: Equatable, Identifiable {
    let id: UUID
    let name: String
    let uniqueIdentifier: UUID

    init(from home: HMHome) {
        self.id = UUID()
        self.name = home.name
        self.uniqueIdentifier = home.uniqueIdentifier
    }
}

/// Service for interacting with HomeKit
actor HomeKitService {
    private let homeManager = HMHomeManager()
    private var isReady = false

    // MARK: - Private

    /// Polls until HomeKit authorization is determined (up to 30 seconds).
    private func waitForReady() async throws {
        guard !isReady else { return }

        for _ in 0..<300 {
            let status = homeManager.authorizationStatus
            if status.contains(.determined) {
                guard status.contains(.authorized) else {
                    throw HomeKitError.permissionDenied
                }
                isReady = true
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        let status = homeManager.authorizationStatus
        if status.contains(.determined) && !status.contains(.authorized) {
            throw HomeKitError.permissionDenied
        }
        isReady = true
    }

    /// After authorization, homeManager.homes loads asynchronously.
    /// This polls until the home with the given UUID appears (up to 10 seconds).
    private func waitForHome(withId homeId: UUID) async -> HMHome? {
        for _ in 0..<50 {
            if let home = homeManager.homes.first(where: { $0.uniqueIdentifier == homeId }) {
                return home
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        return nil
    }

    /// Polls until at least one home is loaded (up to 10 seconds).
    private func waitForAnyHome() async {
        for _ in 0..<50 {
            if !homeManager.homes.isEmpty { return }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    // MARK: - Public

    func requestAuthorization() async throws {
        try await waitForReady()
    }

    func fetchDevices() async throws -> [HomeKitDevice] {
        try await waitForReady()
        await waitForAnyHome()
        return homeManager.homes.flatMap { home in
            home.accessories.map { HomeKitDevice(from: $0) }
        }
    }

    func fetchHomes() async throws -> [HomeKitHome] {
        try await waitForReady()
        await waitForAnyHome()
        return homeManager.homes.map { HomeKitHome(from: $0) }
    }

    func fetchDevices(forHomeId homeId: UUID) async throws -> [HomeKitDevice] {
        try await waitForReady()

        guard let home = await waitForHome(withId: homeId) else {
            let available = homeManager.homes.map { "\($0.name) (\($0.uniqueIdentifier))" }
            print("⚠️ [HomeKitService] home \(homeId) not found. Available: \(available)")
            return []
        }

        return home.accessories.map { HomeKitDevice(from: $0) }
    }

    func isHomeKitAvailable() -> Bool { true }
}

// MARK: - Dependency

struct HomeKitServiceKey: DependencyKey {
    static let liveValue = HomeKitService()
    static let testValue = HomeKitService()
}

extension DependencyValues {
    var homeKitService: HomeKitService {
        get { self[HomeKitServiceKey.self] }
        set { self[HomeKitServiceKey.self] = newValue }
    }
}
