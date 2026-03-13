//
//  CloudSharingView.swift
//  StorePass
//
//  Created by Claude on 13/03/2026.
//

import SwiftUI
import CloudKit
import UIKit

/// A view wrapper for UICloudSharingController with Core Data
struct CloudSharingView: UIViewControllerRepresentable {
    let home: Home
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        let sharingService = CloudKitSharingService()
        sharingService.shareHome(home) { share, container, error in
            if let error = error {
                print("❌ Error creating share: \(error)")
                return
            }
            
            guard let share = share, let container = container else {
                print("❌ No share or container")
                return
            }
            
            // Create the sharing controller with the share
            let controller = UICloudSharingController(share: share, container: container)
            controller.delegate = context.coordinator
            controller.availablePermissions = [.allowPrivate, .allowReadWrite]
            
            // Present it
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(controller, animated: true)
            }
        }
        
        // Return a placeholder - the actual controller is presented above
        return UICloudSharingController(preparationHandler: { _, _ in })
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        var parent: CloudSharingView
        
        init(_ parent: CloudSharingView) {
            self.parent = parent
        }
        
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("❌ Failed to save share: \(error)")
            parent.dismiss()
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            print("📝 Requested item title: \(parent.home.name)")
            return parent.home.name
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("🛑 User stopped sharing")
            Task { @MainActor in
                let sharingService = CloudKitSharingService()
                do {
                    try await sharingService.stopSharing(parent.home)
                    print("✅ Share deleted successfully")
                } catch {
                    print("❌ Error stopping sharing: \(error)")
                }
                parent.dismiss()
            }
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("✅ Share saved successfully")
            parent.dismiss()
        }
    }
}
