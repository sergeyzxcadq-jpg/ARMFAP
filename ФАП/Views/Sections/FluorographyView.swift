import SwiftUI
import SwiftData

struct FluorographyView: View {
    @Query private var patients: [PatientRecord]
    var body: some View {
        List(patients) { patient in
            HStack {
                Text(patient.fullName).font(.headline)
                Spacer()
                Text("ФЛГ: \(patient.flgResult)").font(.caption.bold())
            }
        }
    }
}
