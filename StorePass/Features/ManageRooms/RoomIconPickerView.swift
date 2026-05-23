//
//  RoomIconPickerView.swift
//  StorePass
//

import SwiftUI

struct RoomIconPickerView: View {
    let selectedIcon: String?
    let onIconSelected: (String?) -> Void

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(.localized(.selectIcon))
                .font(.headline)
                .padding(.horizontal, 24)

            LazyVGrid(columns: columns, spacing: 10) {
                RoomIconCell(systemImage: nil, isSelected: selectedIcon == nil) {
                    onIconSelected(nil)
                }
                ForEach(allRoomIcons, id: \.self) { icon in
                    RoomIconCell(systemImage: icon, isSelected: selectedIcon == icon) {
                        onIconSelected(icon)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct RoomIconCell: View {
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    @AppStorage("accentColorName") private var accentColorName = Color.AppColor.blue.rawValue

    private var selectedForegroundColor: Color {
        Color.AppColor(rawValue: accentColorName)?.checkmarkColor ?? .white
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                    .frame(width: 52, height: 52)
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(isSelected ? selectedForegroundColor : .primary)
                } else {
                    Image(systemName: "nosign")
                        .font(.title2)
                        .foregroundStyle(isSelected ? selectedForegroundColor : .secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
