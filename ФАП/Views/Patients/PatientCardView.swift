import SwiftUI
import SwiftData

// MARK: - Модели подраздела сигнальной информации
struct SignalSectionItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

struct SectionTitleSheetItem: Identifiable {
    let id: String
}

struct PatientCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var patient: PatientRecord
    
    // Все приёмы/случаи из базы
    @Query private var allVisits: [OutpatientVisit]
    
    // СОСТОЯНИЯ ИНТЕРФЕЙСА
    @State private var isHeaderExpanded = false
    @State private var selectedTab: ActiveDetailTab = .signalInfo
    @State private var selectedVisitID: PersistentIdentifier? = nil
    @State private var isEditingPatient = false
    
    // Фильтры для боковой панели
    @State private var searchText = ""
    
    enum ActiveDetailTab {
        case signalInfo
        case visitDetail
    }
    
    // Раскрытый подраздел сигнальной информации
    @State private var expandedSignalSection: String? = "Данные пациента"
    
    // Диалоговые окна
    @State private var activeSheetItem: SectionTitleSheetItem? = nil
    @State private var newRecordText: String = ""

    // СПИСОК ВСЕХ 33 ПОДРАЗДЕЛОВ СИГНАЛЬНОЙ ИНФОРМАЦИИ
    let signalSections: [SignalSectionItem] = [
        SignalSectionItem(title: "Данные пациента", icon: "person.text.rectangle.fill"),
        SignalSectionItem(title: "Информированное добровольное согласие", icon: "doc.badge.checkmark"),
        SignalSectionItem(title: "Информированное согласие/отказ в рамках паллиативной помощи", icon: "cross.case.fill"),
        SignalSectionItem(title: "Факторы риска", icon: "exclamationmark.shield.fill"),
        SignalSectionItem(title: "Льготы", icon: "star.fill"),
        SignalSectionItem(title: "Группа крови и резус фактор", icon: "drop.fill"),
        SignalSectionItem(title: "Суммарный сердечно-сосудистый риск", icon: "heart.fill"),
        SignalSectionItem(title: "Анамнез жизни", icon: "book.closed.fill"),
        SignalSectionItem(title: "Аллергологический анамнез", icon: "allergens"),
        SignalSectionItem(title: "Диспансерный учёт", icon: "clipboard.fill"),
        SignalSectionItem(title: "Список уточненных диагнозов", icon: "list.clipboard.fill"),
        SignalSectionItem(title: "Антропометрические данные", icon: "ruler.fill"),
        SignalSectionItem(title: "Окружность головы", icon: "circle.circle"),
        SignalSectionItem(title: "Окружность груди", icon: "oval.portrait.fill"),
        SignalSectionItem(title: "Способ вскармливания", icon: "takeoutbag.and.cup.and.straw.fill"),
        SignalSectionItem(title: "Свидетельства", icon: "doc.plaintext.fill"),
        SignalSectionItem(title: "Список оперативных вмешательств", icon: "cross.fill"),
        SignalSectionItem(title: "Флюорография", icon: "lungs.fill"),
        SignalSectionItem(title: "Лучевая нагрузка", icon: "waveform.path.ecg"),
        SignalSectionItem(title: "Список отменённых направлений", icon: "arrow.uturn.backward.circle.fill"),
        SignalSectionItem(title: "Диспансеризация и мед. осмотры", icon: "heart.text.square.fill"),
        SignalSectionItem(title: "Реакция Манту", icon: "syringe.fill"),
        SignalSectionItem(title: "Исполненные прививки", icon: "checkmark.seal.fill"),
        SignalSectionItem(title: "Планируемые прививки", icon: "calendar.badge.plus"),
        SignalSectionItem(title: "Профилактические прививки", icon: "shield.checkerboard"),
        SignalSectionItem(title: "Список опросов", icon: "questionmark.square.dashed"),
        SignalSectionItem(title: "Список контрольных карт по карантину", icon: "figure.walk.arrival"),
        SignalSectionItem(title: "Экспертный анамнез", icon: "briefcase.fill"),
        SignalSectionItem(title: "Медико-социальная экспертиза", icon: "building.columns.fill"),
        SignalSectionItem(title: "Реабилитация", icon: "figure.walk"),
        SignalSectionItem(title: "Имплантированные изделия", icon: "cpu.fill"),
        SignalSectionItem(title: "Индивидуальная программа реабилитации и абилитации (ИПРА)", icon: "doc.richtext.fill"),
        SignalSectionItem(title: "История оценки по триажу", icon: "chart.bar.fill")
    ]
    
    // Фильтрация приёмов для левой колонки
    private var patientVisits: [OutpatientVisit] {
        allVisits.filter { visit in
            let belongsToPatient = visit.patient?.id == patient.id ||
                                   visit.patientName.localizedCaseInsensitiveContains(patient.fullName)
            if !belongsToPatient { return false }
            
            if searchText.isEmpty { return true }
            return visit.complaintsAndDiagnosis.localizedCaseInsensitiveContains(searchText)
        }
        .sorted(by: { $0.visitDate > $1.visitDate })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            patientHeaderBar
            Divider()
            
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // ЛЕВАЯ КОЛОНКА
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(spacing: 6) {
                            HStack(spacing: 8) {
                                Menu("Группа ▾") { Button("Все") {} }
                                Menu("Период ▾") { Button("Все время") {} }
                                Menu("Фильтр ▾") { Button("Без фильтра") {} }
                                Spacer()
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                                TextField("Быстрый поиск", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .font(.caption)
                                Button(action: {}) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(4)
                            .background(Color.white)
                            .border(Color.gray.opacity(0.3), width: 1)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.08))
                        
                        Divider()
                        
                        Button(action: {
                            selectedTab = .signalInfo
                            selectedVisitID = nil
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Сигнальная информация")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(selectedTab == .signalInfo ? Color.blue.opacity(0.12) : Color.clear)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                        
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if patientVisits.isEmpty {
                                    Text("Случаи лечения отсутствуют")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(20)
                                } else {
                                    ForEach(patientVisits) { visit in
                                        visitListRow(visit)
                                        Divider()
                                    }
                                }
                                
                                Group {
                                    Text("Показать архивные данные")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 10)
                                    
                                    Text("Внешние ЭМД")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 10)
                                }
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(width: 320)
                    .background(Color.gray.opacity(0.04))
                    
                    Divider()
                    
                    // ПРАВАЯ РАБОЧАЯ ОБЛАСТЬ
                    ZStack {
                        Color.white.ignoresSafeArea()
                        
                        switch selectedTab {
                        case .signalInfo:
                            signalInfoContentView
                        case .visitDetail:
                            if let visitID = selectedVisitID, let visit = patientVisits.first(where: { $0.id == visitID }) {
                                visitDetailView(visit)
                            } else {
                                Text("Выберите случай лечения из списка слева")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 980, minHeight: 680)
        .sheet(item: $activeSheetItem) { item in
            addSignalRecordSheet(title: item.id)
        }
        .sheet(isPresented: $isEditingPatient) {
            EditPatientView(patient: patient)
        }
    }
    
    // MARK: - РАЗДЕЛ "СИГНАЛЬНАЯ ИНФОРМАЦИЯ"
    private var signalInfoContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Сигнальная информация")
                    .font(.title2.bold())
                Spacer()
                Button("Печать") { }
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.08))
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(signalSections) { section in
                        signalSectionAccordion(section)
                    }
                }
                .padding(12)
            }
        }
    }
    
    // КАРТОЧКА ПОДРАЗДЕЛA
    private func signalSectionAccordion(_ section: SignalSectionItem) -> some View {
        let isExpanded = expandedSignalSection == section.title
        
        return VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.18)) {
                    expandedSignalSection = isExpanded ? nil : section.title
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    
                    Text(section.title.uppercased())
                        .font(.subheadline.bold())
                        .foregroundColor(Color(red: 0.2, green: 0.25, blue: 0.4))
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.12))
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                    
                    if section.title == "Данные пациента" {
                        HStack(alignment: .top, spacing: 20) {
                            VStack(alignment: .leading, spacing: 6) {
                                patientDataRow(label: "Пол:", value: patient.gender)
                                patientDataRow(label: "Дата рождения:", value: formatDate(patient.birthDate))
                                patientDataRow(label: "Семейное положение:", value: patient.maritalStatus.isEmpty ? "—" : patient.maritalStatus)
                                patientDataRow(label: "Соц. статус:", value: patient.status.isEmpty ? "—" : patient.status)
                                patientDataRow(label: "СНИЛС:", value: patient.snils.isEmpty ? "—" : patient.snils)
                                patientDataRow(label: "Документ:", value: "\(patient.docType) (сер. \(patient.docSeries) № \(patient.docNumber))")
                                patientDataRow(label: "Полис ОМС:", value: "серия: \(patient.policySeries), номер: \(patient.policyNumber) [Статус: \(patient.policyStatus)]")
                                patientDataRow(label: "СМО ОМС:", value: patient.cmoName.isEmpty ? "—" : "\(patient.cmoName) (Адрес: \(patient.cmoAddress), ОГРН: \(patient.cmoOGRN))")
                                patientDataRow(label: "Инвалидность:", value: patient.disabilityGroup.isEmpty ? "Нет" : "\(patient.disabilityGroup), степень: \(patient.disabilityDegree)\(patient.isInvalidFromChildhood ? " (Инвалид с детства)" : "")")
                                patientDataRow(label: "Регистрация:", value: patient.address.isEmpty ? "—" : patient.address)
                                patientDataRow(label: "Телефон:", value: patient.phone.isEmpty ? "—" : patient.phone)
                                patientDataRow(label: "Работа:", value: patient.workPlace.isEmpty ? "—" : patient.workPlace)
                                patientDataRow(label: "Должность:", value: patient.occupation.isEmpty ? "—" : patient.occupation)
                                
                                HStack(alignment: .top, spacing: 0) {
                                    Text("Прикрепление:").font(.subheadline).foregroundColor(.secondary).frame(width: 170, alignment: .leading)
                                    Button("История прикреплений") { }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                
                                HStack(alignment: .top, spacing: 0) {
                                    Text("Дистанционный мониторинг:").font(.subheadline).foregroundColor(.secondary).frame(width: 170, alignment: .leading)
                                    Button("Добавить в программу мониторинга температуры") { }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            VStack {
                                Image(systemName: "person.crop.artframe")
                                    .font(.system(size: 80))
                                    .foregroundColor(.blue.opacity(0.7))
                                Button("Редактировать") {
                                    isEditingPatient = true
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .padding(.top, 4)
                            }
                            .padding(.trailing, 20)
                        }
                        .padding(16)
                    } else {
                        Text("Записи отсутствуют")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(12)
                    }
                }
                .background(Color.white)
            }
        }
        .border(Color.gray.opacity(0.25), width: 1)
    }
    
    private func patientDataRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 170, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
    
    private func addSignalRecordSheet(title: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Добавление записи: «\(title)»").font(.title3.bold())
            TextEditor(text: $newRecordText).frame(height: 120).border(Color.gray.opacity(0.3), width: 1)
            HStack {
                Button("Отмена") { activeSheetItem = nil }.buttonStyle(.bordered)
                Spacer()
                Button("Сохранить") { activeSheetItem = nil }.buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 480, height: 280)
    }
    
    private var patientHeaderBar: some View {
        HStack(spacing: 10) {
            Button(action: {
                withAnimation { isHeaderExpanded.toggle() }
            }) {
                Image(systemName: isHeaderExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            
            Image(systemName: "person.fill").foregroundColor(.blue)
            
            Button(action: {
                withAnimation { isHeaderExpanded.toggle() }
            }) {
                Text(patient.fullName).font(.subheadline.bold()).foregroundColor(.primary)
                Text(" (\(patientAge) лет)").font(.subheadline).foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red).font(.caption)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark").font(.caption.bold()).foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.08))
    }
    
    private func visitListRow(_ visit: OutpatientVisit) -> some View {
        let isSelected = selectedVisitID == visit.id && selectedTab == .visitDetail
        return Button(action: {
            selectedVisitID = visit.id
            selectedTab = .visitDetail
        }) {
            HStack(alignment: .top, spacing: 8) {
                Text(formatShortDate(visit.visitDate)).font(.caption).foregroundColor(.secondary)
                Image(systemName: "cross.case.fill").font(.caption).foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(visit.complaintsAndDiagnosis).font(.caption.bold()).lineLimit(2)
                    Text("ГКП 2").font(.caption2).foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.12) : Color.clear)
        }
        .buttonStyle(.plain)
    }
    
    private func visitDetailView(_ visit: OutpatientVisit) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Случай лечения от \(formatDate(visit.visitDate))").font(.title2.bold())
                Divider()
                Text("Диагноз / Жалобы:").font(.headline)
                Text(visit.complaintsAndDiagnosis).padding().background(Color.gray.opacity(0.05)).cornerRadius(6)
            }
            .padding(20)
        }
    }
    
    private var patientAge: Int {
        guard let bd = patient.birthDate else { return 0 }
        return Calendar.current.dateComponents([.year], from: bd, to: Date()).year ?? 0
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"
        return df.string(from: date)
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "dd.MM.yy"
        return df.string(from: date)
    }
}
