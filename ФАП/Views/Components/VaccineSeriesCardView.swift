import SwiftUI
import SwiftData

struct VaccineSeriesCardView: View {
    @Bindable var series: VaccineSeries
    
    private var sortedDoses: [VaccineDose] {
        series.doses.sorted(by: { a, b in
            a.doseType.rawValue < b.doseType.rawValue
        })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(series.vaccine.rawValue)
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            Divider()
            
            ForEach(sortedDoses, id: \.id) { dose in
                VaccineDoseRowView(dose: dose)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .border(Color.gray.opacity(0.2), width: 1)
    }
}
