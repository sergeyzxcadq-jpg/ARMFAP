import SwiftUI
import SwiftData

struct PatientListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PatientRecord.fullName) private var patients: [PatientRecord]
    
    @State private var searchText = ""
    @State private var isShowingAddPatient = false
    
    private var filteredPatients: [PatientRecord] {
        if searchText.isEmpty {
            return patients
        }
        return patients.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.snils.contains(searchText) ||
            $0.cardNumber.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Панель поиска и действий
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Поиск по ФИО, СНИЛС или № карты...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(8)
                    
                    Button(action: { isShowingAddPatient = true }) {
                        Label("Новый пациент", systemImage: "person.badge.plus")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                Divider()
                
                // Список пациентов
                if filteredPatients.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Пациенты не найдены")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredPatients) { patient in
                            NavigationLink(destination: VaccinationPassportView(record: patient)) {
                                HStack(spacing: 16) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(patient.fullName.isEmpty ? "Без имени" : patient.fullName)
                                            .font(.headline)
                                        
                                        HStack(spacing: 12) {
                                            if !patient.cardNumber.isEmpty {
                                                Text("№ карты: \(patient.cardNumber)")
                                            }
                                            if let birth = patient.birthDate {
                                                Text("Д/Р: \(formatDate(birth))")
                                            }
                                            if !patient.snils.isEmpty {
                                                Text("СНИЛС: \(patient.snils)")
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deletePatients)
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("Картотека пациентов")
            .sheet(isPresented: $isShowingAddPatient) {
                // Подключено новое двухколоночное окно добавления с автоматическим созданием календаря прививок
                AddPatientView { newP in
                    modelContext.insert(newP)
                    setupDefaultCalendar(for: newP)
                    try? modelContext.save()
                }
            }
        }
    }
    
    // Автоматическая инициализация прививочного календаря
    private func setupDefaultCalendar(for patient: PatientRecord) {
        for type in VaccineType.allCases {
            let series = VaccineSeries(vaccine: type)
            modelContext.insert(series)
            series.patient = patient
            
            var doses: [VaccineDose] = []
            switch type {
            case .tuberculosis:
                doses = [VaccineDose(type: .v1), VaccineDose(type: .rv)]
            case .hepatitisB:
                doses = (1...4).map { VaccineDose(type: DoseType.v_num($0)) }
            case .pneumococcal:
                doses = [VaccineDose(type: .v1), VaccineDose(type: .v2), VaccineDose(type: .rv)]
            case .pertussisDiphtheriaTetanus:
                doses = [VaccineDose(type: .v1), VaccineDose(type: .v2), VaccineDose(type: .v3), VaccineDose(type: .rv1), VaccineDose(type: .rv2), VaccineDose(type: .rv3)]
            case .haemophilusB, .hemophilus:
                doses = [VaccineDose(type: .v1), VaccineDose(type: .v2), VaccineDose(type: .v3), VaccineDose(type: .rv1)]
            case .measlesRubellaMumps, .measlesMumps, .rubella:
                doses = [VaccineDose(type: .v1), VaccineDose(type: .v2)]
            case .polio, .poliomyelitis:
                doses = [VaccineDose(type: .v1, subtype: "ИПВ"), VaccineDose(type: .v2, subtype: "ИПВ"), VaccineDose(type: .v3, subtype: "ИПВ"), VaccineDose(type: .rv1, subtype: "ИПВ/ОПВ"), VaccineDose(type: .rv2, subtype: "ИПВ/ОПВ"), VaccineDose(type: .rv3, subtype: "ИПВ/ОПВ")]
            case .tularemia:
                doses = [VaccineDose(type: .v), VaccineDose(type: .rv)]
            case .influenza:
                doses = [VaccineDose(type: .v1)]
            case .hepatitisA, .chickenpox:
                doses = [VaccineDose(type: .v1), VaccineDose(type: .v2)]
            default:
                doses = [VaccineDose(type: .v1), VaccineDose(type: .rv1)]
            }
            
            for dose in doses {
                modelContext.insert(dose)
                dose.series = series
            }
        }
    }
    
    private func deletePatients(at offsets: IndexSet) {
        for index in offsets {
            let patient = filteredPatients[index]
            modelContext.delete(patient)
        }
        try? modelContext.save()
    }
    
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: date)
    }
}
