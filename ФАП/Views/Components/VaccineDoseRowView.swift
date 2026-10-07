import SwiftUI

struct VaccineDoseRowView: View {
    @Bindable var dose: VaccineDose
    var previousDoseDate: Date? = nil
    
    private var nextDoseCalculated: String {
        guard let prevDate = previousDoseDate, dose.date == nil else { return "" }
        let calendar = Calendar.current
        
        guard let series = dose.series else { return "" }
        let vaccine = series.vaccine
        
        var targetDate: Date? = nil
        
        switch vaccine {
        case .hepatitisB:
            if dose.type == .v2 { targetDate = calendar.date(byAdding: .month, value: 1, to: prevDate) }
            else if dose.type == .v3 { targetDate = calendar.date(byAdding: .month, value: 5, to: prevDate) }
        case .pertussisDiphtheriaTetanus, .polio:
            if dose.type == .v2 || dose.type == .v3 { targetDate = calendar.date(byAdding: .day, value: 45, to: prevDate) }
            else if dose.type == .rv1 { targetDate = calendar.date(byAdding: .month, value: 12, to: prevDate) }
            else if dose.type == .rv2 { targetDate = calendar.date(byAdding: .month, value: 2, to: prevDate) }
        case .pneumococcal:
            if dose.type == .v2 { targetDate = calendar.date(byAdding: .day, value: 75, to: prevDate) }
            else if dose.type == .rv { targetDate = calendar.date(byAdding: .month, value: 10, to: prevDate) }
        case .influenza:
            targetDate = calendar.date(byAdding: .year, value: 1, to: prevDate)
        default:
            targetDate = calendar.date(byAdding: .month, value: 3, to: prevDate)
        }
        
        if let calculatedDate = targetDate {
            return calculatedDate.formatted(.dateTime.month(.twoDigits).year())
        }
        return ""
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(dose.type.rawValue)
                .font(.caption.bold())
                .foregroundColor(.primary)
                .frame(width: 32, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                DatePickerTextFieldView(date: $dose.date)
                
                if !nextDoseCalculated.isEmpty {
                    Text("План: \(nextDoseCalculated)")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.leading, 1)
                        .lineLimit(1)
                }
            }
            .frame(width: 105)
            
            TextField("Препарат", text: $dose.drugName)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .frame(maxWidth: 240)
            
            Spacer(minLength: 8)
            
            Button(action: { dose.isCompleted.toggle() }) {
                Image(systemName: dose.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundColor(dose.isCompleted ? .blue : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}
