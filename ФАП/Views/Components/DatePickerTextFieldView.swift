import SwiftUI

struct DatePickerTextFieldView: View {
    @Binding var date: Date?
    var placeholder: String = "ДД.ММ.ГГГГ"
    
    var body: some View {
        ZStack {
            if let dateBinding = Binding($date) {
                DatePicker("", selection: dateBinding, displayedComponents: .date)
                    .labelsHidden()
                    .font(.caption.monospacedDigit())
                    .applyPlatformDatePickerStyle()
            } else {
                Button(action: {
                    date = Date()
                }) {
                    HStack {
                        Text(placeholder)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 105, height: 26)
    }
}

extension View {
    @ViewBuilder
    func applyPlatformDatePickerStyle() -> some View {
        #if os(macOS)
        self.datePickerStyle(.field)
        #else
        self.datePickerStyle(.compact)
        #endif
    }
}

