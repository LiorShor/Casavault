//
//  ViewPreferences.swift
//  CasaVault
//
//  Created by Lior Shor on 06/02/2026.
//

import Foundation

/// View mode for displaying passwords
enum PasswordViewMode: String, CaseIterable, Equatable {
    case list
    case grid
    
    var iconName: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}

/// Grouping mode for organizing passwords
enum PasswordGroupingMode: String, CaseIterable, Equatable {
    case all
    case byRoom
    
    var displayName: String {
        switch self {
        case .all: return String.localized(.groupByAll)
        case .byRoom: return String.localized(.groupByRoom)
        }
    }
}
