import SwiftUI
import SwiftData

struct ClinicalExaminationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var patients: [PatientRecord]
    
    @State private var isShowingAddPatient = false
    @State private var selectedPatientToEdit: PatientRecord? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Картотека диспансеризации")
                    .font(.headline)
                Spacer()
                Button(action: { isShowingAddPatient = true }) {
                    Label("Добавить пациента", systemImage: "person.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            List(patients) { patient in
                HStack {
                    Text(patient.fullName).font(.headline)
                    Spacer()
                    Text("Диспансеризация: \(patient.dispStage)").font(.caption)
                    Button("Редактировать") {
                        selectedPatientToEdit = patient
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .sheet(isPresented: $isShowingAddPatient) {
            AddPatientView { newP in
                modelContext.insert(newP)
                try? modelContext.save()
            }
        }
        .sheet(item: $selectedPatientToEdit) { patient in
            EditPatientView(patient: patient)
        }
    }
}
