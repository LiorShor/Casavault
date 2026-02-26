//
//  HomeKitService.swift
//  StorePass
//
//  Created by Lior Shor on 06/02/2026.
//

import Foundation
import HomeKit
import Dependencies

/// Represents a HomeKit accessory that can be imported
struct HomeKitDevice: Equatable, Identifiable {
    let id: UUID
    let name: String
    let roomName: String?
    let categoryType: String
    let uniqueIdentifier: UUID
    
    init(from accessory: HMAccessory) {
        self.id = UUID()
        self.name = accessory.name
        self.roomName = accessory.room?.name
        self.categoryType = accessory.category.localizedDescription
        self.uniqueIdentifier = accessory.uniqueIdentifier
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
    
    /// Wait for HomeKit to be ready
    private func waitForReady() async {
        guard !isReady else { return }
        
        // Wait for home manager to load homes
        while homeManager.homes.isEmpty {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        isReady = true
    }
    
    /// Request HomeKit authorization
    func requestAuthorization() async throws {
        // HomeKit authorization is automatic when capability is enabled
        // Just wait for the home manager to be ready
        await waitForReady()
    }
    
    /// Fetch all HomeKit accessories from all homes
    func fetchDevices() async throws -> [HomeKitDevice] {
        await waitForReady()
        
        var devices: [HomeKitDevice] = []
        
        for home in homeManager.homes {
            for accessory in home.accessories {
                let device = HomeKitDevice(from: accessory)
                devices.append(device)
            }
        }
        
        return devices
    }
    
    /// Fetch all HomeKit homes
    func fetchHomes() async throws -> [HomeKitHome] {
        await waitForReady()
        
        var homes: [HomeKitHome] = []
        
        for home in homeManager.homes {
            let homeKitHome = HomeKitHome(from: home)
            homes.append(homeKitHome)
        }
        
        return homes
    }
    
    /// Fetch all HomeKit accessories from a specific home
    func fetchDevices(forHomeId homeId: UUID) async throws -> [HomeKitDevice] {
        await waitForReady()
        
        var devices: [HomeKitDevice] = []
        
        // Find the home with the matching uniqueIdentifier
        guard let home = homeManager.homes.first(where: { $0.uniqueIdentifier == homeId }) else {
            return []
        }
        
        for accessory in home.accessories {
            let device = HomeKitDevice(from: accessory)
            devices.append(device)
        }
        
        return devices
    }
    
    /// Check if HomeKit is available on this device
    func isHomeKitAvailable() -> Bool {
        return true // HomeKit is available on all iOS devices
    }
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
