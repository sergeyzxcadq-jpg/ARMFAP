import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataExchangeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var patients: [PatientRecord]
    
    @State private var isShowingImportPicker = false
    @State private var statusMessage = ""
    @State private var isShowingStatusAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Импорт и экспорт прививочной картотеки")
                    .font(.title2.bold())
                
                // Секция экспорта
                VStack(alignment: .leading, spacing: 12) {
                    Text("Экспорт прививочной картотеки").font(.headline)
                    Text("Выгрузка данных всех пациентов и сделанных прививок в формат CSV.")
                        .font(.caption).foregroundColor(.secondary)
                    
                    Button(action: exportVaccinationsCSV) {
                        Label("Экспортировать прививки в CSV", systemImage: "arrow.up.doc.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(patients.isEmpty)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(8)
                
                // Секция импорта
                VStack(alignment: .leading, spacing: 12) {
                    Text("Импорт прививочной картотеки").font(.headline)
                    Text("Загрузка данных картотеки прививок из готового CSV файла.")
                        .font(.caption).foregroundColor(.secondary)
                    
                    Button(action: { isShowingImportPicker = true }) {
                        Label("Выбрать CSV файл для импорта", systemImage: "arrow.down.doc.fill")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(8)
            }
            .padding()
        }
        .fileImporter(
            isPresented: $isShowingImportPicker,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    importVaccinationsFromCSV(url: url)
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                statusMessage = "Ошибка выбора файла: \(error.localizedDescription)"
                isShowingStatusAlert = true
            }
        }
        .alert("Статус операции", isPresented: $isShowingStatusAlert) {
            Button("ОК", role: .cancel) { }
        } message: {
            Text(statusMessage)
        }
    }
    
    // MARK: - Безопасный Экспорт CSV для macOS
    private func exportVaccinationsCSV() {
        let bom = "\u{FEFF}"
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"
        let header = "СНИЛС;ФИО;Дата_рождения;Вакцина;Доза;Дата_выполнения;Производитель"
        var lines = [header]
        
        for patient in patients {
            let birthStr = patient.birthDate != nil ? df.string(from: patient.birthDate!) : ""
            for series in patient.series {
                for dose in series.doses {
                    if let adminDate = dose.dateAdministered {
                        let row = "\(patient.snils);\(patient.fullName);\(birthStr);\(series.vaccine.rawValue);\(dose.doseType.rawValue);\(df.string(from: adminDate));\(dose.manufacturer)"
                        lines.append(row)
                    }
                }
            }
        }
        
        let content = bom + lines.joined(separator: "\n")
        
        DispatchQueue.main.async {
            #if os(macOS)
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.commaSeparatedText, .plainText]
            savePanel.nameFieldStringValue = "Картотека_Прививок.csv"
            savePanel.canCreateDirectories = true
            
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                savePanel.beginSheetModal(for: window) { response in
                    if response == .OK, let url = savePanel.url {
                        try? content.write(to: url, atomically: true, encoding: .utf8)
                        self.statusMessage = "Картотека прививок успешно экспортирована!"
                        self.isShowingStatusAlert = true
                    }
                }
            }
            #endif
        }
    }
    
    // MARK: - Импорт CSV
    private func importVaccinationsFromCSV(url: URL) {
        do {
            let fileData = try Data(contentsOf: url)
            var csvContent = String(data: fileData, encoding: .utf8) ?? ""
            if csvContent.hasPrefix("\u{FEFF}") { csvContent.removeFirst() }
            
            let rows = csvContent.components(separatedBy: .newlines)
            let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"
            var importedCount = 0
            
            for (idx, row) in rows.enumerated() {
                if idx == 0 || row.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
                let cols = row.components(separatedBy: ";")
                if cols.count < 6 { continue }
                
                let snils = cols[0].trimmingCharacters(in: .whitespaces)
                let name = cols[1].trimmingCharacters(in: .whitespaces)
                let birthStr = cols[2].trimmingCharacters(in: .whitespaces)
                let vaccineName = cols[3].trimmingCharacters(in: .whitespaces)
                let doseTypeName = cols[4].trimmingCharacters(in: .whitespaces)
                let dateAdminStr = cols[5].trimmingCharacters(in: .whitespaces)
                let manufacturer = cols.count > 6 ? cols[6].trimmingCharacters(in: .whitespaces) : ""
                
                if name.isEmpty { continue }
                
                // Ищем или создаем пациента
                var patient = patients.first(where: { ($0.snils == snils && !snils.isEmpty) || $0.fullName == name })
                if patient == nil {
                    let newP = PatientRecord(fullName: name, birthDate: df.date(from: birthStr))
                    newP.snils = snils
                    modelContext.insert(newP)
                    patient = newP
                }
                
                guard let targetPatient = patient,
                      let vaccineType = VaccineType(rawValue: vaccineName),
                      let doseType = DoseType(rawValue: doseTypeName),
                      let adminDate = df.date(from: dateAdminStr) else { continue }
                
                // Находим или создаем серию вакцин
                var series = targetPatient.series.first(where: { $0.vaccine == vaccineType })
                if series == nil {
                    let newSeries = VaccineSeries(vaccine: vaccineType)
                    modelContext.insert(newSeries)
                    newSeries.patient = targetPatient
                    series = newSeries
                }
                
                if let targetSeries = series {
                    var dose = targetSeries.doses.first(where: { $0.doseType == doseType })
                    if dose == nil {
                        let newDose = VaccineDose(doseType: doseType)
                        modelContext.insert(newDose)
                        newDose.series = targetSeries
                        dose = newDose
                    }
                    
                    if let targetDose = dose {
                        targetDose.dateAdministered = adminDate
                        targetDose.manufacturer = manufacturer
                        importedCount += 1
                    }
                }
            }
            
            try? modelContext.save()
            statusMessage = "Успешно импортировано записей о прививках: \(importedCount)"
            isShowingStatusAlert = true
        } catch {
            statusMessage = "Ошибка импорта: \(error.localizedDescription)"
            isShowingStatusAlert = true
        }
    }
}
