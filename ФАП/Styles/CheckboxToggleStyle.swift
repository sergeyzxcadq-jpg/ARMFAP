import SwiftUI

// Кастомный стиль чекбокса для iOS, iPadOS и macOS
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(configuration.isOn ? .blue : .gray.opacity(0.6))
                
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var customCheckbox: CheckboxToggleStyle {
        CheckboxToggleStyle()
    }
}
