import SwiftUI
import SwiftData

struct VaccinationPassportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var record: PatientRecord
    
    @State private var showingEditForm = false
    @State private var showingDeleteAlert = false
    
    private let adaptiveColumns = [
        GridItem(.adaptive(minimum: 360, maximum: 480), spacing: 16)
    ]
    
    private var sortedSeries: [VaccineSeries] {
        record.series.sorted { $0.vaccine.rawValue < $1.vaccine.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ЭЛЕКТРОННАЯ МЕДИЦИНСКАЯ КАРТА")
                                .font(.caption2.weight(.heavy))
                                .foregroundColor(.blue)
                            Text(record.fullName.isEmpty ? "Новый пациент" : record.fullName)
                                .font(.title2.bold())
                        }
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: { showingEditForm = true }) {
                                Label("Редактировать", systemImage: "pencil.line")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.bordered)
                            
                            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                                Label("Удалить", systemImage: "trash")
                                    .font(.caption.bold())
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Divider()
                    
                    patientHeaderDetails
                }
                .padding(14)
                .background(.background)
                .cornerRadius(10)
                .border(Color.gray.opacity(0.2), width: 1)
                
                Text("Национальный календарь профилактических прививок (Приказ Минздрава № 1122н)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                LazyVGrid(columns: adaptiveColumns, spacing: 16) {
                    ForEach(sortedSeries) { series in
                        VaccineSeriesCardView(series: series)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Паспорт иммунизации")
        .background(Color.gray.opacity(0.04))
        .sheet(isPresented: $showingEditForm) {
            EditPatientView(patient: record)
        }
        .alert("Удаление медицинской карты", isPresented: $showingDeleteAlert) {
            Button("Удалить навсегда", role: .destructive) {
                deletePatientSafely()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Вы уверены, что хотите полностью стереть карту пациента \(record.fullName)?")
        }
    }
    
    // Безопасное пошаговое удаление записи из SwiftData
    private func deletePatientSafely() {
        dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 1. Удаляем все связанные дозы и серии
            for s in record.series {
                for d in s.doses {
                    modelContext.delete(d)
                }
                modelContext.delete(s)
            }
            // 2. Удаляем карту пациента
            modelContext.delete(record)
            
            // 3. Сохраняем изменения в базе
            try? modelContext.save()
        }
    }
    
    @ViewBuilder
    private var patientHeaderDetails: some View {
        HStack(spacing: 24) {
            HStack(spacing: 6) {
                Image(systemName: "calendar").foregroundColor(.secondary)
                Text("Д/Р:").foregroundColor(.secondary)
                Text(record.birthDate?.formatted(date: .numeric, time: .omitted) ?? "—").bold()
            }
            HStack(spacing: 6) {
                Image(systemName: "person.fill").foregroundColor(.secondary)
                Text("Пол:").foregroundColor(.secondary)
                Text(record.gender).bold()
            }
            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill").foregroundColor(.secondary)
                Text("СНИЛС:").foregroundColor(.secondary)
                Text(record.snils.isEmpty ? "—" : record.snils).bold()
            }
            HStack(spacing: 6) {
                Image(systemName: "briefcase.fill").foregroundColor(.secondary)
                Text("Статус:").foregroundColor(.secondary)
                Text(record.status.isEmpty ? "Не указан" : record.status).bold()
            }
        }
        .font(.subheadline)
    }
}
