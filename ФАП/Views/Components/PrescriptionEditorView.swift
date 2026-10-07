import SwiftUI
import SwiftData

struct PrescriptionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AdminMedicationItem.drugName) private var catalogMedications: [AdminMedicationItem]
    
    var onAdd: (PrescriptionItem) -> Void
    
    @State private var searchText = ""
    @State private var selectedDrugName = ""
    @State private var dosage = "500 мг"
    @State private var administration = "Внутрь"
    @State private var frequency = "3 раза в день"
    @State private var duration = "7 дней"
    
    // Дефолтный список на случай, если справочник администратора пуст
    private var availableMedications: [AdminMedicationItem] {
        if catalogMedications.isEmpty {
            return [
                AdminMedicationItem(drugName: "Амоксициллин", dosage: "500 мг", administration: "Внутрь", frequency: "3 раза в день", duration: "7 дней"),
                AdminMedicationItem(drugName: "Парацетамол", dosage: "500 мг", administration: "Внутрь", frequency: "При температуре", duration: "3 дня"),
                AdminMedicationItem(drugName: "Ибупрофен", dosage: "400 мг", administration: "Внутрь", frequency: "После еды", duration: "5 дней")
            ]
        }
        return catalogMedications
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Шапка окна
            HStack {
                Text("Выбор препарата из единого справочника")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(red: 0.1, green: 0.45, blue: 0.8))
            
            VStack(alignment: .leading, spacing: 14) {
                // Поиск по единому справочнику
                VStack(alignment: .leading, spacing: 4) {
                    Text("Поиск по справочнику медикаментов:").font(.caption.bold())
                    TextField("Введите название препарата...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Список вариантов из базы данных
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(availableMedications.filter { searchText.isEmpty || $0.drugName.localizedCaseInsensitiveContains(searchText) }, id: \.id) { med in
                            Button(action: {
                                selectedDrugName = med.drugName
                                dosage = med.dosage
                                administration = med.administration
                                frequency = med.frequency
                                duration = med.duration
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(med.drugName).bold()
                                        Text("Дозировка: \(med.dosage) | Способ: \(med.administration)").font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(med.frequency).foregroundColor(.blue).font(.caption)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedDrugName == med.drugName ? Color.blue.opacity(0.15) : Color.gray.opacity(0.04))
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 160)
                .border(Color.gray.opacity(0.3), width: 1)
                
                Divider()
                
                // Детали выбранного назначения
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Препарат:").font(.caption).frame(width: 100, alignment: .leading)
                        TextField("Название", text: $selectedDrugName).textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Дозировка:").font(.caption).frame(width: 100, alignment: .leading)
                        TextField("Например: 500 мг", text: $dosage).textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Способ приёма:").font(.caption).frame(width: 100, alignment: .leading)
                        TextField("Например: внутрь", text: $administration).textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Кратность:").font(.caption).frame(width: 100, alignment: .leading)
                        TextField("Например: 3 раза в день", text: $frequency).textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Курс:").font(.caption).frame(width: 100, alignment: .leading)
                        TextField("Например: 7 дней", text: $duration).textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding(16)
            
            Divider()
            
            // Нижняя панель
            HStack {
                Button("Отмена") { dismiss() }.buttonStyle(.bordered)
                Spacer()
                Button("Добавить в назначения") {
                    // ИСПРАВЛЕНИЕ: Передаем только чистое название и заполняем frequency напрямую в модель
                    let item = PrescriptionItem(
                        drugName: selectedDrugName,
                        dosage: dosage,
                        administration: administration,
                        duration: duration
                    )
                    item.frequency = frequency // Записываем кратность в модель
                    onAdd(item)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedDrugName.isEmpty)
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
        }
        .frame(width: 520, height: 520)
    }
}
