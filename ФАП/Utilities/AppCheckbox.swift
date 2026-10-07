//
//  AppCheckbox.swift
//  ФАП
//
//  Created by Sergey Kowalew on 14.08.2026.
//


import SwiftUI

/// Компонент-чекбокс, который на iPad и Mac гарантированно отображает квадратную галочку вместо тумблера
struct AppCheckbox: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            Image(systemName: isOn ? "checkmark.square.fill" : "square")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isOn ? .blue : .gray.opacity(0.5))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
