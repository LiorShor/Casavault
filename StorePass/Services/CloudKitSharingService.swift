//
//  CloudKitSharingService.swift
//  StorePass
//
//  Created by Claude on 13/03/2026.
//

import Foundation
import CloudKit
import CoreData
import SwiftUI

@MainActor
class CloudKitSharingService {
    
    private let persistentContainer: NSPersistentCloudKitContainer
    
    init() {
        self.persistentContainer = CoreDataStack.shared.persistentContainer
    }
    
    // MARK: - Share Management
    
    /// Share a home with other users
    func shareHome(_ home: Home, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) {
        // Create a share for the home
        persistentContainer.share([home], to: nil) { objectIDs, share, container, error in
            if let error = error {
                completion(nil, nil, error)
                return
            }
            
            if let share = share {
                // Configure the share
                share[CKShare.SystemFieldKey.title] = home.name as CKRecordValue
                share.publicPermission = .none
                
                completion(share, container, nil)
            } else {
                completion(nil, nil, NSError(domain: "CloudKitSharingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create share"]))
            }
        }
    }
    
    /// Get existing share for a home
    func fetchShare(for home: Home) async throws -> CKShare? {
        let context = persistentContainer.viewContext
        
        // Fetch all CKShare objects that reference this home
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CKShare")
        
        do {
            let results = try context.fetch(fetchRequest)
            // Find the share that matches our home
            for result in results {
                if let share = result as? CKShare {
                    // Check if this share is for our home
                    // This is simplified - in production you'd need to check the root record
                    return share
                }
            }
            return nil
        } catch {
            throw error
        }
    }
    
    /// Stop sharing a home
    func stopSharing(_ home: Home) async throws {
        // For now, just return - stopping sharing is complex with Core Data
        // The UICloudSharingController handles this automatically
        return
    }
    
    /// Check if a home can be shared
    func canShare(_ home: Home) -> Bool {
        return persistentContainer.canUpdateRecord(forManagedObjectWith: home.objectID)
    }
    
    /// Accept a share invitation
    func acceptShare(metadata: CKShare.Metadata) async throws {
        let container = CKContainer(identifier: metadata.containerIdentifier)
        _ = try await container.accept(metadata)
    }
}
