import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PDFKit
#if os(macOS)
import AppKit
#endif

// MARK: - МОДЕЛЬ ДАННЫХ ВЫЗОВА СМП (SWIFTDATA)
@Model
class SMPVisitModel: Identifiable {
    var id: UUID
    var callDate: Date
    var patientName: String
    var age: String
    var gender: String
    var address: String
    var reasonAndDiagnosis: String
    var callResult: String
    var brigade: String

    init(id: UUID = UUID(), callDate: Date, patientName: String, age: String, gender: String, address: String, reasonAndDiagnosis: String, callResult: String, brigade: String) {
        self.id = id
        self.callDate = callDate
        self.patientName = patientName
        self.age = age
        self.gender = gender
        self.address = address
        self.reasonAndDiagnosis = reasonAndDiagnosis
        self.callResult = callResult
        self.brigade = brigade
    }
}

// MARK: - НАДЕЖНЫЙ ЗАГРУЗЧИК И БАЗА МКБ-10
struct ICDCodeItem: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let title: String
    
    var displayText: String {
        "\(code) — \(title)"
    }
}

class ICD10Loader {
    static let shared = ICD10Loader()
    private(set) var items: [ICDCodeItem] = []
    
    init() { loadData() }
    
    private func loadData() {
        if let fileURL = Bundle.main.url(forResource: "icd10", withExtension: "csv"),
           let content = try? String(contentsOf: fileURL, encoding: .utf8) {
            let rows = content.components(separatedBy: .newlines)
            var loadedItems: [ICDCodeItem] = []
            for row in rows {
                let trimmed = row.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }
                let cols = trimmed.components(separatedBy: ";")
                if cols.count >= 2 {
                    loadedItems.append(ICDCodeItem(code: cols[0].trimmingCharacters(in: .whitespaces),
                                                   title: cols[1].trimmingCharacters(in: .whitespaces)))
                }
            }
            if !loadedItems.isEmpty {
                self.items = loadedItems
                return
            }
        }
        self.items = [
            ICDCodeItem(code: "A00.0", title: "Холера, вызванная холерным вибрионом 01, биовар cholerae"),
            ICDCodeItem(code: "J00", title: "Острый назофарингит [насморк]"),
            ICDCodeItem(code: "J01.0", title: "Острый верхнечелюстной синусит"),
            ICDCodeItem(code: "E11.9", title: "Инсулиннезависимый сахарный диабет без осложнений"),
            ICDCodeItem(code: "Z00.0", title: "Общий медицинский осмотр взрослых")
        ]
    }
}

struct OutpatientView: View {
    var activeSubTab: OutpatientSubTab = .journal
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OutpatientVisit.visitDate, order: .forward) private var allVisits: [OutpatientVisit]
    @Query(sort: \PatientRecord.fullName) private var allPatients: [PatientRecord]
    @Query(sort: \SMPVisitModel.callDate, order: .reverse) private var smpVisits: [SMPVisitModel]
    
    @State private var creationStep: CreationStep? = nil
    @State private var selectedPatientForNewVisit: PatientRecord? = nil
    @State private var createdVisitForDetail: OutpatientVisit? = nil
    @State private var selectedVisitForEdit: OutpatientVisit? = nil
    @State private var colWidths: [CGFloat] = [60, 120, 220, 50, 110, 220, 220, 220, 120]
    
    // Состояния фильтров и сортировки
    @State private var filterGender = "Все"
    @State private var filterAttachment = "Все"
    @State private var showOnlyAlive = true
    @State private var sortOption: PatientSortOption = .fullNameAsc
    
    enum PatientSortOption: String, CaseIterable, Identifiable {
        case fullNameAsc = "По ФИО (А-Я)"
        case fullNameDesc = "По ФИО (Я-А)"
        case birthDateAsc = "По дате рождения (сначала старше)"
        case birthDateDesc = "По дате рождения (сначала младше)"
        var id: String { rawValue }
    }
    
    enum CreationStep: Identifiable {
        case searchPatient, fillVisitForm, viewCreatedVisit
        var id: Int { hashValue }
    }
    
    @State private var selectedVisitIDs: Set<UUID> = []
    @State private var isShowingDeleteVisitsConfirm = false
    @State private var searchText = ""
    @State private var selectedPatientIDs: Set<UUID> = []
    @State private var isShowingAddPatientSheet = false
    @State private var patientToEdit: PatientRecord? = nil
    @State private var isShowingDeleteConfirm = false
    @State private var patientForCard: PatientRecord? = nil
    @State private var isShowingImportPicker = false
    @State private var importMode: ImportMode = .visits
    @State private var statusMessage: String = ""
    @State private var isShowingStatusAlert = false
    
    // Состояние для журнала СМП
    @State private var isShowingSMPModal = false
    @State private var selectedSMPVisitIDs: Set<UUID> = []
    @State private var isShowingDeleteSMPConfirm = false
    
    enum ImportMode { case visits, population }
    
    private var filteredPatients: [PatientRecord] {
        let filtered = allPatients.filter { patient in
            let fullNameNormalized = patient.fullName.replacingOccurrences(of: "ё", with: "е").replacingOccurrences(of: "Ё", with: "Е")
            
            let matchesSearch = searchText.isEmpty ||
                fullNameNormalized.localizedCaseInsensitiveContains(searchText) ||
                patient.snils.contains(searchText) ||
                patient.cardNumber.localizedCaseInsensitiveContains(searchText) ||
                patient.phone.contains(searchText)
            
            let matchesGender = filterGender == "Все" || patient.gender.lowercased().contains(filterGender.lowercased())
            let matchesAttach = filterAttachment == "Все" || patient.attachmentType == filterAttachment
            let matchesAlive = !showOnlyAlive || patient.deathDate == nil
            
            return matchesSearch && matchesGender && matchesAttach && matchesAlive
        }
        
        return filtered.sorted { p1, p2 in
            let name1 = p1.fullName.replacingOccurrences(of: "ё", with: "е").replacingOccurrences(of: "Ё", with: "Е")
            let name2 = p2.fullName.replacingOccurrences(of: "ё", with: "е").replacingOccurrences(of: "Ё", with: "Е")
            
            switch sortOption {
            case .fullNameAsc:
                return name1 < name2
            case .fullNameDesc:
                return name1 > name2
            case .birthDateAsc:
                let date1 = p1.birthDate ?? Date.distantPast
                let date2 = p2.birthDate ?? Date.distantPast
                return date1 < date2
            case .birthDateDesc:
                let date1 = p1.birthDate ?? Date.distantPast
                let date2 = p2.birthDate ?? Date.distantPast
                return date1 > date2
            }
        }
    }
    
    private var chronologicalVisits: [OutpatientVisit] {
        allVisits.sorted(by: { $0.visitDate < $1.visitDate })
    }
    
    private var sortedGroupedVisits: [(date: Date, visits: [OutpatientVisit])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allVisits) { calendar.startOfDay(for: $0.visitDate) }
        return grouped.map { (date: $0.key, visits: $0.value.sorted(by: { $0.visitDate > $1.visitDate })) }
            .sorted(by: { $0.date > $1.date })
    }
    
    private func globalIndex(for visit: OutpatientVisit) -> Int {
        if let index = chronologicalVisits.firstIndex(where: { $0.id == visit.id }) { return index + 1 }
        return 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch activeSubTab {
            case .journal: journalView
            case .smpJournal: smpJournalView
            case .population: populationView
            case .exchange: exchangeView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("1. Амбулаторный прием")
        .sheet(item: $creationStep) { step in
            switch step {
            case .searchPatient:
                PatientSearchWizardSheetView(
                    patients: allPatients,
                    onSelectPatient: { patient in
                        selectedPatientForNewVisit = patient
                        creationStep = .fillVisitForm
                    },
                    onAddNewPatient: { isShowingAddPatientSheet = true }
                )
            case .fillVisitForm:
                AddVisitWizardFormSheetView(patient: selectedPatientForNewVisit) { newVisit in
                    modelContext.insert(newVisit)
                    try? modelContext.save()
                    createdVisitForDetail = newVisit
                    creationStep = .viewCreatedVisit
                }
            case .viewCreatedVisit:
                if let visit = createdVisitForDetail { VisitFullDetailCaseView(visit: visit) }
            }
        }
        .sheet(item: $selectedVisitForEdit) { visit in
            EditVisitSheetView(visit: visit, patients: allPatients) { try? modelContext.save() }
        }
        .sheet(isPresented: $isShowingAddPatientSheet) {
            AddPatientView { newPatient in
                modelContext.insert(newPatient)
                try? modelContext.save()
            }
        }
        .sheet(item: $patientToEdit) { patient in EditPatientView(patient: patient) }
        .sheet(item: $patientForCard) { patient in PatientCardView(patient: patient) }
        .sheet(isPresented: $isShowingSMPModal) {
            AddSMPVisitSheetView(patients: allPatients) { newVisit in
                modelContext.insert(newVisit)
                try? modelContext.save()
            }
        }
        .fileImporter(
            isPresented: $isShowingImportPicker,
            allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText]
        ) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    if importMode == .visits { importVisitsFromCSV(url: url) }
                    else { importPopulationFromCSV(url: url) }
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                statusMessage = "Ошибка выбора файла: \(error.localizedDescription)"
                isShowingStatusAlert = true
            }
        }
        .alert("Статус операции", isPresented: $isShowingStatusAlert) {
            Button("ОК", role: .cancel) { }
        } message: { Text(statusMessage) }
        .alert("Удаление жителей", isPresented: $isShowingDeleteConfirm) {
            Button("Удалить выбранные", role: .destructive) {
                deleteSelectedPatients()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Вы действительно хотите полностью стереть отмеченные карты жителей из базы?")
        }
        .alert("Удаление записей приёма", isPresented: $isShowingDeleteVisitsConfirm) {
            Button("Удалить приёмы", role: .destructive) {
                deleteSelectedVisits()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Вы действительно хотите удалить выбранные записи амбулаторного приёма из журнала?")
        }
        .alert("Удаление вызовов СМП", isPresented: $isShowingDeleteSMPConfirm) {
            Button("Удалить выбранные", role: .destructive) {
                deleteSelectedSMPVisits()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Вы действительно хотите удалить выбранные записи вызовов СМП?")
        }
    }
    
    @State private var journalFilterStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var journalFilterEndDate = Date()
    @State private var useJournalDateFilter = false

    private var filteredJournalVisits: [(date: Date, visits: [OutpatientVisit])] {
        let calendar = Calendar.current
        let groups = sortedGroupedVisits
        if !useJournalDateFilter { return groups }
        return groups.compactMap { group in
            let day = calendar.startOfDay(for: group.date)
            let start = calendar.startOfDay(for: journalFilterStartDate)
            let end = calendar.startOfDay(for: journalFilterEndDate)
            return (day >= start && day <= end) ? group : nil
        }
    }

    private var tableHeaderView: some View {
        HStack(spacing: 0) {
            TableRowCheckbox(isOn: Binding(
                get: { selectedVisitIDs.count == allVisits.count && !allVisits.isEmpty },
                set: { isSelected in
                    if isSelected { selectedVisitIDs = Set(allVisits.map { $0.id }) }
                    else { selectedVisitIDs.removeAll() }
                }
            ))
            .frame(width: 40)
            headerCell("№ п/п", width: 60)
            headerCell("Дата и время", width: 120)
            headerCell("Ф.И.О. пациента", width: 220)
            headerCell("Пол", width: 50)
            headerCell("Дата рождения", width: 110)
            headerCell("Адрес проживания", width: 220)
            headerCell("Диагноз", width: 220)
            headerCell("Назначенное лечение", width: 220)
            headerCell("Примечание", width: 120)
        }
        .background(Color(red: 0.0, green: 0.45, blue: 0.68))
        .foregroundColor(.white)
    }
    
    private var tableSubHeaderView: some View {
        HStack(spacing: 0) {
            subHeaderCell("", width: 40)
            subHeaderCell("1", width: 60)
            subHeaderCell("2", width: 120)
            subHeaderCell("3", width: 220)
            subHeaderCell("4", width: 50)
            subHeaderCell("5", width: 110)
            subHeaderCell("6", width: 220)
            subHeaderCell("7", width: 220)
            subHeaderCell("8", width: 220)
            subHeaderCell("9", width: 120)
        }
        .background(Color.gray.opacity(0.18))
    }

    private var journalView: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Button(action: { selectedPatientForNewVisit = nil; creationStep = .searchPatient }) {
                        Label("Добавить приём", systemImage: "plus.circle.fill").font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { exportJournalToExcel() }) {
                        Label("Экспорт в Excel", systemImage: "doc.text.fill").font(.subheadline)
                    }
                    Button(action: { importMode = .visits; isShowingImportPicker = true }) {
                        Label("Импорт из CSV", systemImage: "arrow.down.doc.fill").font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .buttonStyle(.bordered).disabled(allVisits.isEmpty)
                    
                    if !selectedVisitIDs.isEmpty {
                        Button(role: .destructive, action: { isShowingDeleteVisitsConfirm = true }) {
                            Label("Удалить (\(selectedVisitIDs.count))", systemImage: "trash.fill").font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Toggle("Фильтр по периоду:", isOn: $useJournalDateFilter).font(.subheadline)
                    if useJournalDateFilter {
                        HStack(spacing: 8) {
                            Text("с").font(.caption).foregroundColor(.secondary)
                            DatePicker("", selection: $journalFilterStartDate, displayedComponents: .date).labelsHidden()
                            Text("по").font(.caption).foregroundColor(.secondary)
                            DatePicker("", selection: $journalFilterEndDate, displayedComponents: .date).labelsHidden()
                        }
                    }
                    Spacer()
                }
            }
            .padding(12).background(Color.gray.opacity(0.05))
            
            Divider()
            
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    tableHeaderView
                    tableSubHeaderView
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        let groups = filteredJournalVisits
                        if groups.isEmpty {
                            Text("Записи амбулаторного приёма не найдены")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(20)
                                .frame(width: 1350, alignment: .topLeading)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(groups, id: \.date) { group in
                                    HStack {
                                        Image(systemName: "calendar.badge.clock").foregroundColor(.blue)
                                        Text(formatGroupDate(group.date)).font(.subheadline.bold()).foregroundColor(.primary)
                                        Spacer()
                                        Text("Всего приёмов: \(group.visits.count)").font(.caption).foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 12).padding(.vertical, 8).frame(width: 1350, alignment: .leading).background(Color.blue.opacity(0.08))
                                    
                                    ForEach(Array(group.visits.enumerated()), id: \.element.id) { index, visit in
                                        HStack(spacing: 0) {
                                            TableRowCheckbox(isOn: Binding(
                                                get: { selectedVisitIDs.contains(visit.id) },
                                                set: { isSelected in
                                                    if isSelected { selectedVisitIDs.insert(visit.id) }
                                                    else { selectedVisitIDs.remove(visit.id) }
                                                }
                                            ))
                                            .frame(width: 40)
                                            
                                            VisitRowView(
                                                visit: visit,
                                                rowNumber: globalIndex(for: visit),
                                                colWidths: colWidths,
                                                isEven: index % 2 == 0,
                                                onEdit: { createdVisitForDetail = visit; creationStep = .viewCreatedVisit },
                                                onDelete: { deleteVisit(visit) }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 12)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // ЖУРНАЛ ВЫЗОВОВ СМП
    private var smpJournalView: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Button(action: { isShowingSMPModal = true }) {
                        Label("Добавить вызов СМП", systemImage: "plus.circle.fill").font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if !selectedSMPVisitIDs.isEmpty {
                        Button(role: .destructive, action: { isShowingDeleteSMPConfirm = true }) {
                            Label("Удалить выбранные (\(selectedSMPVisitIDs.count))", systemImage: "trash.fill").font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                }
            }
            .padding(12).background(Color.gray.opacity(0.05))
            
            Divider()
            
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        TableRowCheckbox(isOn: Binding(
                            get: { !smpVisits.isEmpty && selectedSMPVisitIDs.count == smpVisits.count },
                            set: { isSelected in
                                if isSelected { selectedSMPVisitIDs = Set(smpVisits.map { $0.id }) }
                                else { selectedSMPVisitIDs.removeAll() }
                            }
                        ))
                        .frame(width: 40)
                        
                        headerCell("№ п/п", width: 60)
                        headerCell("Дата и время вызова", width: 130)
                        headerCell("Ф.И.О. пациента", width: 220)
                        headerCell("Возраст", width: 70)
                        headerCell("Адрес вызова", width: 220)
                        headerCell("Повод к вызову / Диагноз", width: 240)
                        headerCell("Результат вызова", width: 160)
                        headerCell("Фельдшер СМП / Бригада", width: 180)
                    }
                    .background(Color(red: 0.0, green: 0.45, blue: 0.68))
                    .foregroundColor(.white)
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        if smpVisits.isEmpty {
                            Text("Записи в журнале вызовов СМП отсутствуют")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(20)
                                .frame(width: 1320, alignment: .topLeading)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(smpVisits.enumerated()), id: \.element.id) { index, visit in
                                    HStack(spacing: 0) {
                                        TableRowCheckbox(isOn: Binding(
                                            get: { selectedSMPVisitIDs.contains(visit.id) },
                                            set: { isSelected in
                                                if isSelected { selectedSMPVisitIDs.insert(visit.id) }
                                                else { selectedSMPVisitIDs.remove(visit.id) }
                                            }
                                        ))
                                        .frame(width: 40)
                                        
                                        dataCell("\(index + 1)", width: 60, align: .center)
                                        dataCell(formatDateTime(visit.callDate), width: 130, align: .center)
                                        dataCell(visit.patientName, width: 220, align: .leading)
                                        dataCell(visit.age, width: 70, align: .center)
                                        dataCell(visit.address, width: 220, align: .leading)
                                        dataCell(visit.reasonAndDiagnosis, width: 240, align: .leading)
                                        dataCell(visit.callResult, width: 160, align: .leading)
                                        dataCell(visit.brigade, width: 180, align: .leading)
                                    }
                                    .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.03))
                                    .contextMenu {
                                        Button(role: .destructive, action: { deleteSingleSMPVisit(visit) }) {
                                            Label("Удалить вызов", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 12)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var populationView: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Button(action: { isShowingAddPatientSheet = true }) {
                        Label("Добавить жителя", systemImage: "person.badge.plus").font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { importMode = .population; isShowingImportPicker = true }) {
                        Label("Импорт CSV", systemImage: "arrow.down.doc.fill").font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { exportPopulationCSV() }) {
                        Label("Экспорт CSV", systemImage: "arrow.up.doc.fill").font(.subheadline)
                    }
                    .buttonStyle(.bordered).disabled(filteredPatients.isEmpty)
                    
                    if !selectedPatientIDs.isEmpty {
                        Button(role: .destructive, action: { isShowingDeleteConfirm = true }) {
                            Label("Удалить выбранные (\(selectedPatientIDs.count))", systemImage: "trash.fill").font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("Поиск по ФИО, СНИЛС, карте...", text: $searchText).textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6).background(Color.white).cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .frame(width: 260)
                }
                
                // Панель сортировки
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Text("Сортировка:").font(.caption).foregroundColor(.secondary)
                            Picker("", selection: $sortOption) {
                                ForEach(PatientSortOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.menu).labelsHidden().frame(width: 240)
                        }
                        
                        HStack(spacing: 6) {
                            Text("Пол:").font(.caption).foregroundColor(.secondary)
                            Picker("", selection: $filterGender) {
                                Text("Все").tag("Все")
                                Text("Мужской").tag("Мужской")
                                Text("Женский").tag("Женский")
                            }
                            .pickerStyle(.menu).labelsHidden().frame(width: 100)
                        }
                        
                        Toggle("Только живые", isOn: $showOnlyAlive).font(.caption)
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Text("Прикрепление:").font(.caption).foregroundColor(.secondary)
                            Picker("", selection: $filterAttachment) {
                                Text("Все").tag("Все")
                                Text("По месту жительства").tag("По месту жительства")
                                Text("По заявлению").tag("По заявлению")
                            }
                            .pickerStyle(.menu).labelsHidden().frame(width: 180)
                        }
                        Spacer()
                        Text("Найдено жителей: \(filteredPatients.count)").font(.caption.bold()).foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
            .padding(12).background(Color.gray.opacity(0.05))
            
            Divider()
            
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        TableRowCheckbox(isOn: Binding(
                            get: { selectedPatientIDs.count == filteredPatients.count && !filteredPatients.isEmpty },
                            set: { isSelected in
                                if isSelected { selectedPatientIDs = Set(filteredPatients.map { $0.id }) }
                                else { selectedPatientIDs.removeAll() }
                            }
                        ))
                        .frame(width: 40)
                        headerCell("№ амб. карты", width: 110)
                        headerCell("ФИО", width: 220)
                        headerCell("Пол", width: 60)
                        headerCell("Дата рождения", width: 110)
                        headerCell("СНИЛС", width: 130)
                        headerCell("Дата смерти", width: 100)
                        headerCell("Тип прикрепления", width: 160)
                        headerCell("Адрес проживания", width: 220)
                        headerCell("Телефон", width: 120)
                    }
                    .background(Color(red: 0.0, green: 0.45, blue: 0.68))
                    .foregroundColor(.white)
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        if filteredPatients.isEmpty {
                            Text("Прикреплённое население по заданным критериям не найдено")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(20)
                                .frame(width: 1290, alignment: .topLeading)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(filteredPatients.enumerated()), id: \.element.id) { index, patient in
                                    HStack(spacing: 0) {
                                        TableRowCheckbox(isOn: Binding(
                                            get: { selectedPatientIDs.contains(patient.id) },
                                            set: { isSelected in
                                                if isSelected { selectedPatientIDs.insert(patient.id) }
                                                else { selectedPatientIDs.remove(patient.id) }
                                            }
                                        ))
                                        .frame(width: 40)
                                        
                                        dataCell(patient.cardNumber.isEmpty ? "—" : patient.cardNumber, width: 110, align: .center)
                                        dataCell(patient.fullName, width: 220, align: .leading)
                                        dataCell(patient.gender.isEmpty ? "—" : patient.gender, width: 60, align: .center)
                                        dataCell(formatDate(patient.birthDate), width: 110, align: .center)
                                        dataCell(patient.snils.isEmpty ? "—" : patient.snils, width: 130, align: .center)
                                        dataCell(patient.deathDate != nil ? formatDate(patient.deathDate) : "—", width: 100, align: .center)
                                        dataCell(patient.attachmentType.isEmpty ? "По месту жительства" : patient.attachmentType, width: 160, align: .leading)
                                        dataCell(patient.address.isEmpty ? "—" : patient.address, width: 220, align: .leading)
                                        dataCell(patient.phone.isEmpty ? "—" : patient.phone, width: 120, align: .center)
                                    }
                                    .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.03))
                                    .contentShape(Rectangle())
                                    .onTapGesture(count: 2) { patientForCard = patient }
                                    .contextMenu {
                                        Button(action: { patientForCard = patient }) { Label("Открыть медицинскую карту (ЭМК)", systemImage: "person.text.rectangle.fill") }
                                        Button(action: { patientToEdit = patient }) { Label("Редактировать анкетные данные", systemImage: "pencil") }
                                        Button(role: .destructive, action: { deleteSinglePatient(patient) }) { Label("Удалить жителя", systemImage: "trash") }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 12)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var exchangeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Обмен данными амбулаторного приёма").font(.title2.bold())
                VStack(alignment: .leading, spacing: 12) {
                    Text("Экспорт журнала").font(.headline)
                    Text("Сохранить все амбулаторные приёмы в CSV файл для Excel.").font(.caption).foregroundColor(.secondary)
                    Button(action: { exportVisitsCSV() }) { Label("Экспортировать в CSV", systemImage: "arrow.up.doc.fill") }
                        .buttonStyle(.borderedProminent).disabled(allVisits.isEmpty)
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.gray.opacity(0.08)).cornerRadius(8)
            }
            .padding()
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Методы удаления
    private func deleteSelectedPatients() {
        let targets = allPatients.filter { selectedPatientIDs.contains($0.id) }
        for patient in targets { modelContext.delete(patient) }
        selectedPatientIDs.removeAll()
        try? modelContext.save()
    }
    
    private func deleteSinglePatient(_ patient: PatientRecord) {
        selectedPatientIDs.remove(patient.id)
        modelContext.delete(patient)
        try? modelContext.save()
    }

    private func deleteSelectedVisits() {
        let targets = allVisits.filter { selectedVisitIDs.contains($0.id) }
        for visit in targets { modelContext.delete(visit) }
        selectedVisitIDs.removeAll()
        try? modelContext.save()
    }
    
    private func deleteVisit(_ visit: OutpatientVisit) {
        selectedVisitIDs.remove(visit.id)
        modelContext.delete(visit)
        try? modelContext.save()
    }
    
    private func deleteSelectedSMPVisits() {
        let targets = smpVisits.filter { selectedSMPVisitIDs.contains($0.id) }
        for visit in targets {
            modelContext.delete(visit)
        }
        selectedSMPVisitIDs.removeAll()
        try? modelContext.save()
    }

    private func deleteSingleSMPVisit(_ visit: SMPVisitModel) {
        selectedSMPVisitIDs.remove(visit.id)
        modelContext.delete(visit)
        try? modelContext.save()
    }
    
    private func exportPopulationCSV() {
        let bom = "\u{FEFF}"
        let bdf = DateFormatter(); bdf.dateFormat = "dd.MM.yyyy"
        let header = "№_амб_карты;ФИО;Пол;Дата_рождения;СНИЛС;Дата_смерти;Тип_прикрепления;Адрес;Телефон"
        var lines = [header]
        for p in filteredPatients {
            let bd = p.birthDate != nil ? bdf.string(from: p.birthDate!) : ""
            let dd = p.deathDate != nil ? bdf.string(from: p.deathDate!) : ""
            lines.append("\(p.cardNumber);\(p.fullName);\(p.gender);\(bd);\(p.snils);\(dd);\(p.attachmentType);\(p.address);\(p.phone)")
        }
        saveContentToCSV(content: bom + lines.joined(separator: "\n"), fileName: "Прикрепленное_Население.csv")
    }
    
    private func exportVisitsCSV() {
        let bom = "\u{FEFF}"
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy HH:mm"
        let bdf = DateFormatter(); bdf.dateFormat = "dd.MM.yyyy"
        let header = "Дата_и_время;ФИО;Пол;Дата_рождения;Адрес;Диагноз_Жалобы"
        var lines = [header]
        for v in chronologicalVisits {
            lines.append("\(df.string(from: v.visitDate));\(v.patientName);\(v.patientGender);\(v.patientBirthDate != nil ? bdf.string(from: v.patientBirthDate!) : "");\(v.patientAddress);\(v.complaintsAndDiagnosis.replacingOccurrences(of: ";", with: ","))")
        }
        saveContentToCSV(content: bom + lines.joined(separator: "\n"), fileName: "Журнал_Амбулаторного_Приема.csv")
    }
    
    private func saveContentToCSV(content: String, fileName: String) {
        DispatchQueue.main.async {
            #if os(macOS)
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType.commaSeparatedText, UTType.plainText]
            savePanel.nameFieldStringValue = fileName
            savePanel.canCreateDirectories = true
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                savePanel.beginSheetModal(for: window) { response in
                    if response == .OK, let url = savePanel.url {
                        try? content.write(to: url, atomically: true, encoding: .utf8)
                        self.statusMessage = "Файл успешно сохранён!"
                        self.isShowingStatusAlert = true
                    }
                }
            }
            #endif
        }
    }

    private func importPopulationFromCSV(url: URL) { }
    private func importVisitsFromCSV(url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines)
            
            var importedCount = 0
            let df = DateFormatter()
            df.dateFormat = "dd.MM.yyyy HH:mm"
            
            let bdf = DateFormatter()
            bdf.dateFormat = "dd.MM.yyyy"
            
            // Пропускаем заголовок (индекс 0)
            for i in 1..<rows.count {
                let row = rows[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if row.isEmpty { continue }
                
                let cols = row.components(separatedBy: ";")
                // Шаблон содержит 9 колонок:
                // 0: № п/п
                // 1: Дата и время
                // 2: Ф.И.О. пациента
                // 3: Пол
                // 4: Дата рождения
                // 5: Адрес проживания
                // 6: Диагноз
                // 7: Назначенное лечение
                // 8: Примечание
                guard cols.count >= 8 else { continue }
                
                let visitDate = df.date(from: cols[1]) ?? Date()
                let patientName = cols[2] == "—" ? "" : cols[2]
                let patientGender = cols[3].isEmpty ? "Мужской" : cols[3]
                let patientBirthDate = bdf.date(from: cols[4])
                let patientAddress = cols[5]
                let diagnosis = cols[6]
                
                // Если у пациента есть заполненная ФИО, попробуем найти его в базе по имени,
                // чтобы связать карточку, либо создадим приём со свободными данными.
                let matchedPatient = allPatients.first { $0.fullName.localizedCaseInsensitiveCompare(patientName) == .orderedSame }
                
                let newVisit = OutpatientVisit(
                    visitDate: visitDate,
                    complaintsAndDiagnosis: diagnosis,
                    patient: matchedPatient,
                    patientName: patientName.isEmpty ? (matchedPatient?.fullName ?? "—") : patientName,
                    patientGender: patientGender,
                    patientBirthDate: patientBirthDate ?? matchedPatient?.birthDate,
                    patientAddress: patientAddress.isEmpty ? (matchedPatient?.address ?? "") : patientAddress,
                    department: "",
                    visitType: "",
                    location: "",
                    visitKind: "",
                    visitGoal: "",
                    medHelpType: ""
                )
                
                modelContext.insert(newVisit)
                importedCount += 1
            }
            
            try modelContext.save()
            statusMessage = "Успешно импортировано записей приёма: \(importedCount)"
            isShowingStatusAlert = true
        } catch {
            statusMessage = "Ошибка импорта файла: \(error.localizedDescription)"
            isShowingStatusAlert = true
        }
    }


    private func exportJournalToExcel() {
        let bom = "\u{FEFF}" // BOM для корректного отображения кириллицы в Excel
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy HH:mm"
        
        let bdf = DateFormatter()
        bdf.dateFormat = "dd.MM.yyyy"
        
        // Точный шаблон заголовков из вашего примера
        let header = "№ п/п;Дата и время;Ф.И.О. пациента;Пол;Дата рождения;Адрес проживания;Диагноз;Назначенное лечение;Примечание"
        var lines = [header]
        
        for (index, v) in chronologicalVisits.enumerated() {
            let visitDateStr = df.string(from: v.visitDate)
            let name = v.patientName.isEmpty ? "—" : v.patientName
            let gender = v.patientGender.isEmpty ? "Мужской" : v.patientGender
            let birthDateStr = v.patientBirthDate != nil ? bdf.string(from: v.patientBirthDate!) : ""
            let address = v.patientAddress.isEmpty ? "" : v.patientAddress.replacingOccurrences(of: ";", with: ",")
            let diagnosis = v.complaintsAndDiagnosis.isEmpty ? "" : v.complaintsAndDiagnosis.replacingOccurrences(of: ";", with: ",")
            
            // Сбор назначений лекарственных препаратов
            let treatmentsText = v.prescriptions.isEmpty ? "" : v.prescriptions.map { item in
                let cleanName = item.drugName.components(separatedBy: " (").first ?? item.drugName
                return "\(cleanName) \(item.dosage), \(item.frequency) № \(item.duration)"
            }.joined(separator: ", ")
            
            let rowLine = "\(index + 1);\(visitDateStr);\(name);\(gender);\(birthDateStr);\(address);\(diagnosis);\(treatmentsText);"
            lines.append(rowLine)
        }
        
        let csvString = bom + lines.joined(separator: "\n")
        saveContentToCSV(content: csvString, fileName: "Журнал_Амбулаторного_Приема.csv")
    }

    private func headerCell(_ text: String, width: CGFloat) -> some View {
        Text(text).font(.subheadline.bold()).multilineTextAlignment(.center).frame(width: width, height: 42).border(Color.white.opacity(0.3), width: 0.5)
    }
    private func subHeaderCell(_ text: String, width: CGFloat) -> some View {
        Text(text).font(.caption.bold()).foregroundColor(.primary).frame(width: width, height: 26).border(Color.gray.opacity(0.3), width: 0.5)
    }
    private func dataCell(_ text: String, width: CGFloat, align: Alignment) -> some View {
        Text(text).font(.caption).padding(.horizontal, 6).frame(width: width, height: 36, alignment: align).border(Color.gray.opacity(0.25), width: 0.5).lineLimit(2)
    }
    private func formatGroupDate(_ date: Date) -> String {
        let df = DateFormatter(); df.locale = Locale(identifier: "ru_RU"); df.dateFormat = "d MMMM yyyy 'г.'"
        return df.string(from: date)
    }
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"; return df.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy HH:mm"; return df.string(from: date)
    }
}

// MARK: - СТРОКА ТАБЛИЦЫ ПРИЁМА
struct VisitRowView: View {
    var visit: OutpatientVisit
    var rowNumber: Int
    var colWidths: [CGFloat]
    var isEven: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    private var genderLetter: String {
        let raw = visit.patientGender.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if raw == "женский" || raw == "ж" || raw.contains("жен") { return "Ж" }
        return "М"
    }
    
    private var treatmentsText: String {
        if visit.prescriptions.isEmpty { return "—" }
        return visit.prescriptions.enumerated().map { index, item in
            let cleanName = item.drugName.components(separatedBy: " (").first ?? item.drugName
            return "\(index + 1). \(cleanName) \(item.dosage), \(item.frequency) № \(item.duration)"
        }.joined(separator: "; ")
    }
    
    var body: some View {
        let cell1 = makeCell(text: "\(rowNumber)", width: colWidths[0], align: .center)
        let cell2 = makeCell(text: formatTime(visit.visitDate), width: colWidths[1], align: .center)
        let cell3 = makeCell(text: visit.patientName.isEmpty ? "—" : visit.patientName, width: colWidths[2], align: .leading)
        let cell4 = makeCell(text: genderLetter, width: colWidths[3], align: .center)
        let cell5 = makeCell(text: formatDate(visit.patientBirthDate), width: colWidths[4], align: .center)
        let cell6 = makeCell(text: visit.patientAddress.isEmpty ? "—" : visit.patientAddress, width: colWidths[5], align: .leading)
        let cell7 = makeCell(text: visit.complaintsAndDiagnosis.isEmpty ? "—" : visit.complaintsAndDiagnosis, width: colWidths[6], align: .leading)
        let cell8 = makeCell(text: treatmentsText, width: colWidths[7], align: .leading)
        let cell9 = makeCell(text: "", width: colWidths[8], align: .center)
        
        return HStack(spacing: 5) {
            cell1; cell2; cell3; cell4; cell5; cell6; cell7; cell8; cell9
        }
        .padding(.vertical, 4)
        .background(isEven ? Color.white : Color.gray.opacity(0.04))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onEdit() }
        .contextMenu {
            Button(action: { onEdit() }) { Label("Просмотреть случай", systemImage: "eye") }
            Button(role: .destructive, action: { onDelete() }) { Label("Удалить из журнала", systemImage: "trash") }
        }
    }
    
    private func makeCell(text: String, width: CGFloat, align: Alignment) -> some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(width: width, alignment: align)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"; return df.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "HH:mm"; return df.string(from: date)
    }
}

// MARK: - ФОРМА ДОБАВЛЕНИЯ ВЫЗОВА СМП (С ВЫБОРОМ ДИАГНОЗА ИЗ МКБ-10)
struct AddSMPVisitSheetView: View {
    @Environment(\.dismiss) private var dismiss
    var patients: [PatientRecord]
    var onCreateVisit: (SMPVisitModel) -> Void
    
    @State private var callDate = Date()
    @State private var callTime = Date()
    
    @State private var selectedPatient: PatientRecord? = nil
    @State private var patientFullName = ""
    @State private var patientAge = ""
    @State private var patientGender = "Мужской"
    @State private var address = ""
    
    // Состояния для поиска и выбора диагноза по МКБ-10
    @State private var isICDPickerOpen = false
    @State private var searchICDQuery = ""
    @State private var chosenDiagnosis = "J01.0 Острый верхнечелюстной синусит"
    
    @State private var callResult = "Доставлен в стационар"
    @State private var brigadeNumber = "Бригада № 1 (Фельдшерская)"
    
    @State private var isPatientPickerOpen = false
    @State private var searchPatientQuery = ""
    
    let resultOptions = [
        "Доставлен в стационар",
        "Оказана помощь на месте",
        "Актив передан в поликлинику",
        "Отказ от медицинской помощи",
        "Констатация смерти"
    ]
    
    private var filteredPatientsList: [PatientRecord] {
        if searchPatientQuery.isEmpty { return patients }
        return patients.filter { $0.fullName.localizedCaseInsensitiveContains(searchPatientQuery) || $0.cardNumber.localizedCaseInsensitiveContains(searchPatientQuery) }
    }
    
    var filteredICDList: [ICDCodeItem] {
        let all = ICD10Loader.shared.items
        if searchICDQuery.isEmpty { return all }
        return all.filter { $0.code.localizedCaseInsensitiveContains(searchICDQuery) || $0.title.localizedCaseInsensitiveContains(searchICDQuery) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Новый вызов СМП")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.12, green: 0.53, blue: 0.95))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 14)
                }
                .buttonStyle(.plain)
            }
            .background(Color(red: 0.94, green: 0.94, blue: 0.94))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 20) {
                        Text("Дата и время вызова:").font(.system(size: 13)).foregroundColor(.secondary).frame(width: 150, alignment: .leading)
                        DatePicker("", selection: $callDate, displayedComponents: [.date]).labelsHidden()
                        DatePicker("", selection: $callTime, displayedComponents: [.hourAndMinute]).labelsHidden()
                        Spacer()
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 20) {
                            Text("Пациент из базы:").font(.system(size: 13, weight: .semibold)).frame(width: 150, alignment: .leading)
                            HStack {
                                Text(selectedPatient?.fullName ?? "Выберите пациента из базы...").font(.system(size: 13)).lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundColor(.gray)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6).background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .contentShape(Rectangle())
                            .onTapGesture { isPatientPickerOpen.toggle() }
                        }
                        
                        if isPatientPickerOpen {
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Поиск по ФИО или номеру карты...", text: $searchPatientQuery).textFieldStyle(.roundedBorder)
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 1) {
                                        ForEach(filteredPatientsList, id: \.id) { patient in
                                            Button(action: {
                                                selectedPatient = patient
                                                patientFullName = patient.fullName
                                                patientGender = patient.gender.isEmpty ? "Мужской" : patient.gender
                                                address = patient.address
                                                
                                                if let bDate = patient.birthDate {
                                                    let ageVal = Calendar.current.dateComponents([.year], from: bDate, to: Date()).year ?? 0
                                                    patientAge = "\(ageVal)"
                                                } else {
                                                    patientAge = "—"
                                                }
                                                
                                                isPatientPickerOpen = false
                                            }) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(patient.fullName).font(.system(size: 12, weight: .bold)).foregroundColor(.primary)
                                                    Text("Карта: \(patient.cardNumber) | Адрес: \(patient.address)").font(.system(size: 10)).foregroundColor(.secondary)
                                                }
                                                .padding(6)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .buttonStyle(.plain)
                                            Divider()
                                        }
                                    }
                                }
                                .frame(height: 140).background(Color.white).overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            }
                            .padding(.leading, 170)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 20) {
                            Text("Ф.И.О. пациента:").font(.system(size: 13)).foregroundColor(.secondary).frame(width: 150, alignment: .leading)
                            TextField("Фамилия Имя Отчество", text: $patientFullName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(spacing: 20) {
                            Text("Возраст / Пол:").font(.system(size: 13)).foregroundColor(.secondary).frame(width: 150, alignment: .leading)
                            TextField("Лет", text: $patientAge)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 70)
                            
                            Picker("", selection: $patientGender) {
                                Text("Мужской").tag("Мужской")
                                Text("Женский").tag("Женский")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                            Spacer()
                        }
                        
                        HStack(spacing: 20) {
                            Text("Адрес вызова:").font(.system(size: 13)).foregroundColor(.secondary).frame(width: 150, alignment: .leading)
                            TextField("Населенный пункт, улица, дом, квартира", text: $address)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    Divider()
                    
                    // Повод / Диагноз с выбором из МКБ-10
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 20) {
                            Text("Повод / Диагноз:").font(.system(size: 13, weight: .semibold)).frame(width: 150, alignment: .leading)
                            HStack {
                                Text(chosenDiagnosis).font(.system(size: 13)).lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundColor(.gray)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6).background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .contentShape(Rectangle())
                            .onTapGesture { isICDPickerOpen.toggle() }
                        }
                        
                        if isICDPickerOpen {
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Быстрый поиск кода или наименования МКБ...", text: $searchICDQuery).textFieldStyle(.roundedBorder)
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 1) {
                                        ForEach(filteredICDList, id: \.code) { item in
                                            Button(action: { chosenDiagnosis = item.displayText; isICDPickerOpen = false }) {
                                                Text(item.displayText).font(.system(size: 12)).foregroundColor(.primary).padding(6).frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .buttonStyle(.plain)
                                            Divider()
                                        }
                                    }
                                }
                                .frame(height: 140).background(Color.white).overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            }
                            .padding(.leading, 170)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 20) {
                            Text("Результат вызова:").font(.system(size: 13)).foregroundColor(.secondary).frame(width: 150, alignment: .leading)
                            Picker("", selection: $callResult) {
                                ForEach(resultOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack(spacing: 20) {
                            Text("Бригада СМП:").font(.system(size: 13)).foregroundColor(.secondary).frame(width: 150, alignment: .leading)
                            TextField("Номер бригады и состав", text: $brigadeNumber)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(red: 0.97, green: 0.97, blue: 0.97))
            
            Divider()
            
            HStack {
                Button("Отмена") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Сохранить вызов") {
                    let calendar = Calendar.current
                    let dComp = calendar.dateComponents([.year, .month, .day], from: callDate)
                    let tComp = calendar.dateComponents([.hour, .minute], from: callTime)
                    var combined = DateComponents()
                    combined.year = dComp.year; combined.month = dComp.month; combined.day = dComp.day
                    combined.hour = tComp.hour; combined.minute = tComp.minute
                    let finalDate = calendar.date(from: combined) ?? callDate
                    
                    let newVisit = SMPVisitModel(
                        callDate: finalDate,
                        patientName: patientFullName,
                        age: patientAge,
                        gender: patientGender,
                        address: address,
                        reasonAndDiagnosis: chosenDiagnosis,
                        callResult: callResult,
                        brigade: brigadeNumber
                    )
                    onCreateVisit(newVisit)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(patientFullName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 0.94, green: 0.94, blue: 0.94))
        }
        .frame(width: 680, height: 560)
    }
}

// MARK: - ШАГ 1: ОКНО ПОИСКА ПАЦИЕНТА
struct PatientSearchWizardSheetView: View {
    @Environment(\.dismiss) private var dismiss
    var patients: [PatientRecord]
    var onSelectPatient: (PatientRecord) -> Void
    var onAddNewPatient: () -> Void
    
    @State private var lastName = ""
    @State private var firstName = ""
    @State private var patronymic = ""
    @State private var showDeceased = false
    @State private var snils = ""
    @State private var polisSeries = ""
    @State private var polisNumber = ""
    @State private var isExtraParamsExpanded = false
    
    @State private var useBirthDateFilter = false
    @State private var searchBirthDate = Date()
    
    @State private var hasSearched = false
    @State private var performedSearch: [PatientRecord] = []
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Человек: Поиск").font(.subheadline.bold()).foregroundColor(.white)
                Spacer()
                Button(action: {}) { Image(systemName: "arrow.clockwise").foregroundColor(.white) }.buttonStyle(.plain)
                Button(action: {}) { Image(systemName: "questionmark.circle").foregroundColor(.white) }.buttonStyle(.plain)
                Button(action: { dismiss() }) { Image(systemName: "xmark").foregroundColor(.white) }.buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(red: 0.1, green: 0.45, blue: 0.8))
            
            VStack(alignment: .leading, spacing: 12) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                    GridRow {
                        Text("Фамилия:").font(.caption)
                        TextField("", text: $lastName).textFieldStyle(.roundedBorder)
                        
                        HStack(spacing: 4) {
                            Toggle("", isOn: $useBirthDateFilter).labelsHidden().scaleEffect(0.8)
                            Text("Дата рожд.:").font(.caption)
                        }
                        DatePicker("", selection: $searchBirthDate, displayedComponents: .date)
                            .labelsHidden()
                            .disabled(!useBirthDateFilter)
                        
                        Text("Серия полиса:").font(.caption)
                        TextField("", text: $polisSeries).textFieldStyle(.roundedBorder)
                    }
                    GridRow {
                        Text("Имя:").font(.caption)
                        TextField("", text: $firstName).textFieldStyle(.roundedBorder)
                        Text("ИД пациента:").font(.caption)
                        TextField("", text: .constant("")).textFieldStyle(.roundedBorder)
                        Text("Номер полиса:").font(.caption)
                        TextField("", text: $polisNumber).textFieldStyle(.roundedBorder)
                    }
                    GridRow {
                        Text("Отчество:").font(.caption)
                        TextField("", text: $patronymic).textFieldStyle(.roundedBorder)
                        Text("СНИЛС:").font(.caption)
                        TextField("", text: $snils).textFieldStyle(.roundedBorder)
                        Text("Единый номер:").font(.caption)
                        TextField("", text: .constant("")).textFieldStyle(.roundedBorder)
                    }
                }
                
                Toggle("Показывать умерших:", isOn: $showDeceased).font(.caption)
                
                DisclosureGroup("Дополнительные параметры", isExpanded: $isExtraParamsExpanded) {
                    HStack(spacing: 20) {
                        Text("Возраст (лет) с:").font(.caption)
                        TextField("", text: .constant("")).frame(width: 50).textFieldStyle(.roundedBorder)
                        Text("по:").font(.caption)
                        TextField("", text: .constant("")).frame(width: 50).textFieldStyle(.roundedBorder)
                    }
                    .padding(.top, 4)
                }
                .font(.caption.bold())
                
                HStack(spacing: 10) {
                    Button(action: executeSearch) {
                        Label("НАЙТИ", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    Button(action: clearSearch) {
                        Label("ОЧИСТИТЬ", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        dismiss()
                        onAddNewPatient()
                    }) {
                        Label("ДОБАВИТЬ НОВОГО", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
                .font(.caption.bold())
                
                Divider()
                
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            wizardSearchHeader("Фамилия", width: 130)
                            wizardSearchHeader("Имя", width: 130)
                            wizardSearchHeader("Отчество", width: 130)
                            wizardSearchHeader("Дата рождения", width: 110)
                            wizardSearchHeader("Дата смерти", width: 110)
                            wizardSearchHeader("МО прикрепления", width: 150)
                            wizardSearchHeader("РЗ", width: 60)
                            wizardSearchHeader("Льготы", width: 90)
                        }
                        .background(Color.gray.opacity(0.15))
                        
                        let filtered = currentFilteredPatients
                        
                        if !hasSearched {
                            Text("Введите параметры и нажмите «НАЙТИ»")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(30)
                        } else if filtered.isEmpty {
                            Text("Пациенты по заданным критериям не найдены")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(30)
                        } else {
                            ForEach(filtered, id: \.id) { patient in
                                let parts = patient.fullName.components(separatedBy: " ")
                                HStack(spacing: 0) {
                                    wizardSearchCell(parts.count > 0 ? parts[0] : "", width: 130)
                                    wizardSearchCell(parts.count > 1 ? parts[1] : "", width: 130)
                                    wizardSearchCell(parts.count > 2 ? parts[2] : "", width: 130)
                                    wizardSearchCell(formatDate(patient.birthDate), width: 110)
                                    wizardSearchCell(patient.deathDate != nil ? formatDate(patient.deathDate) : "—", width: 110)
                                    wizardSearchCell(patient.attachmentType, width: 150)
                                    wizardSearchCell("Да", width: 60)
                                    wizardSearchCell("—", width: 90)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    onSelectPatient(patient)
                                }
                            }
                        }
                    }
                    .border(Color.gray.opacity(0.3), width: 1)
                }
            }
            .padding(12)
        }
        .frame(width: 850, height: 600)
    }
    
    private var currentFilteredPatients: [PatientRecord] {
        if !hasSearched { return [] }
        return performedSearch
    }
    
    private func executeSearch() {
        hasSearched = true
        performedSearch = patients.filter { p in
            let parts = p.fullName.components(separatedBy: " ")
            let realLastName = parts.first ?? ""
            let realFirstName = parts.count > 1 ? parts[1] : ""
            let realPatronymic = parts.count > 2 ? parts[2] : ""
            
            let matchLastName = lastName.isEmpty || realLastName.localizedCaseInsensitiveCompare(lastName) == .orderedSame || realLastName.lowercased().hasPrefix(lastName.lowercased())
            let matchFirstName = firstName.isEmpty || realFirstName.localizedCaseInsensitiveCompare(firstName) == .orderedSame || realFirstName.lowercased().hasPrefix(firstName.lowercased())
            let matchPatronymic = patronymic.isEmpty || realPatronymic.localizedCaseInsensitiveCompare(patronymic) == .orderedSame || realPatronymic.lowercased().hasPrefix(patronymic.lowercased())
            let matchSnils = snils.isEmpty || p.snils.contains(snils)
            
            var matchDate = true
            if useBirthDateFilter, let bDate = p.birthDate {
                let cal = Calendar.current
                matchDate = cal.isDate(bDate, inSameDayAs: searchBirthDate)
            } else if useBirthDateFilter {
                matchDate = false
            }
            
            return matchLastName && matchFirstName && matchPatronymic && matchSnils && matchDate
        }
    }
    
    private func clearSearch() {
        lastName = ""; firstName = ""; patronymic = ""; snils = ""; polisSeries = ""; polisNumber = ""
        useBirthDateFilter = false
        performedSearch = []
        hasSearched = false
    }
    
    private func wizardSearchHeader(_ text: String, width: CGFloat) -> some View {
        Text(text).font(.caption.bold()).frame(width: width, height: 28).border(Color.gray.opacity(0.3), width: 0.5)
    }
    
    private func wizardSearchCell(_ text: String, width: CGFloat) -> some View {
        Text(text).font(.caption).frame(width: width, height: 28).border(Color.gray.opacity(0.2), width: 0.5)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"; return df.string(from: date)
    }
}

// MARK: - ФОРМА СОЗДАНИЯ СЛУЧАЯ (ШАГ 2)
struct AddVisitWizardFormSheetView: View {
    @Environment(\.dismiss) private var dismiss
    var patient: PatientRecord?
    var onCreateVisit: (OutpatientVisit) -> Void
    
    @State private var attributes = VisitAttributesManager.shared
    
    @State private var visitDate = Date()
    @State private var visitTime = Date()
    
    @State private var selectedDepartment = ""
    @State private var doctorName = "Ковалёв Сергей Львович"
    @State private var visitType = ""
    @State private var location = ""
    @State private var visitKind = ""
    @State private var visitGoal = ""
    @State private var medHelpType = ""
    
    @State private var isICDPickerOpen = false
    @State private var searchICDQuery = ""
    @State private var chosenDiagnosis = "J01.0 Острый верхнечелюстной синусит"
    
    var filteredICDList: [ICDCodeItem] {
        let all = ICD10Loader.shared.items
        if searchICDQuery.isEmpty { return all }
        return all.filter { $0.code.localizedCaseInsensitiveContains(searchICDQuery) || $0.title.localizedCaseInsensitiveContains(searchICDQuery) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(formatDateTab(visitDate))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.12, green: 0.53, blue: 0.95))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .semibold)).foregroundColor(.secondary).padding(.trailing, 14)
                }
                .buttonStyle(.plain)
            }
            .background(Color(red: 0.94, green: 0.94, blue: 0.94))
            
            HStack(spacing: 6) {
                Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold)).foregroundColor(.gray)
                Text("ПОСЕЩЕНИЕ")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                Text("—  \(patient?.fullName ?? "Пациент не выбран")")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(red: 0.91, green: 0.91, blue: 0.91))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 20) {
                        Text("Дата/время приема:").font(.system(size: 13)).foregroundColor(.secondary).frame(width: 150, alignment: .leading)
                        DatePicker("", selection: $visitDate, displayedComponents: [.date]).labelsHidden()
                        DatePicker("", selection: $visitTime, displayedComponents: [.hourAndMinute]).labelsHidden()
                        Spacer()
                    }
                    
                    formRowPicker(label: "Отделение:", selection: $selectedDepartment, items: attributes.departments)
                    
                    HStack(spacing: 20) {
                        Text("Врач:").font(.system(size: 13)).foregroundColor(.secondary).frame(width: 150, alignment: .leading)
                        Text(doctorName).font(.system(size: 13)).bold().frame(maxWidth: .infinity, alignment: .leading).padding(6).background(Color.white).overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                    }
                    
                    Divider().padding(.vertical, 4)
                    
                    formRowPicker(label: "Вид обращения:", selection: $visitType, items: attributes.visitTypes)
                    formRowPicker(label: "Место:", selection: $location, items: attributes.locations)
                    formRowPicker(label: "Прием:", selection: $visitKind, items: attributes.visitKinds)
                    formRowPicker(label: "Цель посещения:", selection: $visitGoal, items: attributes.visitGoals)
                    formRowPicker(label: "Вид мед. помощи:", selection: $medHelpType, items: attributes.medHelpTypes)
                    
                    Spacer().frame(height: 20)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 20) {
                            Text("Основной диагноз:").font(.system(size: 13, weight: .semibold)).frame(width: 150, alignment: .leading)
                            HStack {
                                Text(chosenDiagnosis).font(.system(size: 13)).lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundColor(.gray)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6).background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .contentShape(Rectangle())
                            .onTapGesture { isICDPickerOpen.toggle() }
                        }
                        
                        if isICDPickerOpen {
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Быстрый поиск кода или наименования...", text: $searchICDQuery).textFieldStyle(.roundedBorder)
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 1) {
                                        ForEach(filteredICDList, id: \.code) { item in
                                            Button(action: { chosenDiagnosis = item.displayText; isICDPickerOpen = false }) {
                                                Text(item.displayText).font(.system(size: 12)).foregroundColor(.primary).padding(6).frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .buttonStyle(.plain)
                                            Divider()
                                        }
                                    }
                                }
                                .frame(height: 130).background(Color.white).overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            }
                            .padding(.leading, 170)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color(red: 0.97, green: 0.97, blue: 0.97))
            
            Divider()
            
            HStack {
                Button("Отмена") { dismiss() }.buttonStyle(.bordered)
                Spacer()
                Button("Создать случай лечения") {
                    let calendar = Calendar.current
                    let dComp = calendar.dateComponents([.year, .month, .day], from: visitDate)
                    let tComp = calendar.dateComponents([.hour, .minute], from: visitTime)
                    var combined = DateComponents()
                    combined.year = dComp.year; combined.month = dComp.month; combined.day = dComp.day
                    combined.hour = tComp.hour; combined.minute = tComp.minute
                    
                    let finalDate = calendar.date(from: combined) ?? visitDate
                    let newVisit = OutpatientVisit(
                        visitDate: finalDate,
                        complaintsAndDiagnosis: chosenDiagnosis,
                        patient: patient,
                        patientName: patient?.fullName ?? "—",
                        patientGender: patient?.gender ?? "Мужской",
                        patientBirthDate: patient?.birthDate,
                        patientAddress: patient?.address ?? "",
                        department: selectedDepartment,
                        visitType: visitType,
                        location: location,
                        visitKind: visitKind,
                        visitGoal: visitGoal,
                        medHelpType: medHelpType
                    )
                    onCreateVisit(newVisit)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20).padding(.vertical, 12).background(Color(red: 0.94, green: 0.94, blue: 0.94))
        }
        .frame(width: 780, height: 620)
        .onAppear {
            if selectedDepartment.isEmpty, let first = attributes.departments.first { selectedDepartment = first }
            if visitType.isEmpty, let first = attributes.visitTypes.first { visitType = first }
            if location.isEmpty, let first = attributes.locations.first { location = first }
            if visitKind.isEmpty, let first = attributes.visitKinds.first { visitKind = first }
            if visitGoal.isEmpty, let first = attributes.visitGoals.first { visitGoal = first }
            if medHelpType.isEmpty, let first = attributes.medHelpTypes.first { medHelpType = first }
        }
    }
    
    private func formRowPicker(label: String, selection: Binding<String>, items: [String]) -> some View {
        HStack(spacing: 20) {
            Text(label).font(.system(size: 13)).foregroundColor(.secondary).frame(width: 150, alignment: .leading)
            Picker("", selection: selection) {
                ForEach(items, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu).labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white).overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray.opacity(0.4), lineWidth: 1))
        }
    }
    
    private func formatDateTab(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"; return df.string(from: date)
    }
}

// MARK: - ДЕТАЛЬНЫЙ ПРОСМОТР СЛУЧАЯ
struct VisitFullDetailCaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var visit: OutpatientVisit
    
    @State private var isVisitExpanded = true
    @State private var isVitalExpanded = false
    @State private var isExamExpanded = true
    @State private var isPrescriptionsExpanded = false
    @State private var isMedicationExpanded = false
    @State private var isExemptionExpanded = false
    
    @State private var examinationText: String = ""
    @State private var isEditingExam: Bool = false
    
    @State private var vitalHeight: String = ""
    @State private var vitalWeight: String = ""
    @State private var vitalWaist: String = ""
    @State private var vitalTemperature: String = ""
    @State private var vitalBpSystolic: String = ""
    @State private var vitalBpDiastolic: String = ""
    @State private var vitalHeartRate: String = ""
    @State private var vitalPulse: String = ""
    @State private var vitalSaturation: String = ""
    @State private var vitalRespiratoryRate: String = ""
    
    @State private var isShowingPrescriptionEditor = false
    @State private var isShowingMedicationEditor = false
    @State private var isShowingPrintPreview = false
       
    var body: some View {
        VStack(spacing: 0) {
            topHeaderView
            dateBarView
            
            ScrollView {
                VStack(spacing: 2) {
                    visitSectionView
                    vitalsSectionView
                    examSectionView
                    prescriptionsSectionView
                    medicationUsageSectionView
                    disclosureHeaderRow(title: "МЕДОТВОДЫ / ОТКАЗЫ ОТ ВАКЦИНАЦИИ", isExpanded: $isExemptionExpanded)
                }
                .padding(.horizontal, 12).padding(.top, 6)
            }
            
            Divider()
            bottomSaveBar
        }
        .frame(width: 880, height: 680)
        .overlay(Rectangle().stroke(Color.orange, lineWidth: 1))
        .sheet(isPresented: $isShowingPrescriptionEditor) {
            PrescriptionEditorView { newItem in
                newItem.visit = visit
                visit.prescriptions.append(newItem)
                modelContext.insert(newItem)
                try? modelContext.save()
            }
        }
        .sheet(isPresented: $isShowingPrintPreview) {
            VisitPrintDocumentView(visit: visit)
        }
        .onAppear {
            loadInitialData()
        }
    }
    
    private var topHeaderView: some View {
        HStack(spacing: 12) {
            Text("Случай амбулаторного лечения № 58198 - \(visit.complaintsAndDiagnosis)")
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.93, green: 0.93, blue: 0.93))
                .overlay(Rectangle().stroke(Color.orange, lineWidth: 1.5))
            
            Button(action: {
                exportVisitToWord(visit: visit)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                    Text("В Word")
                }
                .font(.system(size: 12)).padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color(red: 0.93, green: 0.93, blue: 0.93))
                .overlay(Rectangle().stroke(Color.gray.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 6)
    }
    
    private var dateBarView: some View {
        HStack(spacing: 0) {
            Text(formatDate(visit.visitDate))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24).padding(.vertical, 8)
                .background(Color(red: 0.12, green: 0.53, blue: 0.95))
            Spacer()
        }
        .background(Color.white)
        .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
        .padding(.horizontal, 12)
    }
    
    private var visitSectionView: some View {
        disclosureSection(title: "ПОСЕЩЕНИЕ", isExpanded: $isVisitExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Пациент: \(visit.patientName)").font(.system(size: 12)).bold()
                Text("Адрес: \(visit.patientAddress.isEmpty ? "—" : visit.patientAddress)").font(.system(size: 12)).foregroundColor(.secondary)
                
                Divider().padding(.vertical, 2)
                
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Отделение: **\(visit.department)**").font(.system(size: 12))
                        Text("Вид обращения: **\(visit.visitType)**").font(.system(size: 12))
                        Text("Место: **\(visit.location)**").font(.system(size: 12))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Прием: **\(visit.visitKind)**").font(.system(size: 12))
                        Text("Цель посещения: **\(visit.visitGoal)**").font(.system(size: 12))
                        Text("Вид мед. помощи: **\(visit.medHelpType)**").font(.system(size: 12))
                    }
                }
            }
            .padding(10)
        }
    }
    
    private var vitalsSectionView: some View {
        disclosureSection(title: "ВИТАЛЬНЫЕ ПАРАМЕТРЫ", subtitle: isVitalParamsEmpty ? "Не заполнены витальные параметры" : "Заполнены", isExpanded: $isVitalExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    vitalField(title: "Рост, см", text: $vitalHeight)
                    vitalField(title: "Вес, кг", text: $vitalWeight)
                    vitalField(title: "Окружность талии, см", text: $vitalWaist)
                    vitalField(title: "t, °C", text: $vitalTemperature)
                    vitalField(title: "САД, мм рт.ст.", text: $vitalBpSystolic)
                }
                HStack(spacing: 8) {
                    vitalField(title: "ЧДД, дв/мин", text: $vitalRespiratoryRate)
                    vitalField(title: "ЧСС, уд/мин", text: $vitalHeartRate)
                    vitalField(title: "Пульс, уд/мин", text: $vitalPulse)
                    vitalField(title: "Сатурация, %", text: $vitalSaturation)
                    vitalField(title: "ДАД, мм рт.ст.", text: $vitalBpDiastolic)
                }
            }
            .padding(10)
        }
    }
    
    private var examSectionView: some View {
        examDisclosureSection(title: "ОСМОТР", badgeCount: examinationText.isEmpty ? 0 : 1, isExpanded: $isExamExpanded) {
            if isEditingExam {
                MedicalExaminationEditorView(examinationText: $examinationText) {
                    isEditingExam = false
                } onSaveVitals: { h, w, waist, temp, s, d, hr, p, sat in
                    vitalHeight = h
                    vitalWeight = w
                    vitalWaist = waist
                    vitalTemperature = temp
                    vitalBpSystolic = s
                    vitalBpDiastolic = d
                    vitalHeartRate = hr
                    vitalPulse = p
                    vitalSaturation = sat
                }
                .frame(height: 480)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if examinationText.isEmpty {
                        HStack {
                            Text("Осмотр не заполнен.").font(.system(size: 12)).foregroundColor(.secondary)
                            Spacer()
                            Button(action: { isEditingExam = true }) {
                                Label("Заполнить по шаблону", systemImage: "plus.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(examinationText)
                                .font(.system(size: 13))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.04))
                                .cornerRadius(4)
                            
                            HStack {
                                Spacer()
                                Button("Редактировать осмотр") {
                                    isEditingExam = true
                                }
                                .font(.system(size: 11))
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding(10)
            }
        }
    }
    
    private var prescriptionsSectionView: some View {
        prescriptionDisclosureSection(title: "НАЗНАЧЕНИЯ", badgeCount: visit.prescriptions.count, isExpanded: $isPrescriptionsExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                if visit.prescriptions.isEmpty {
                    HStack {
                        Text("Назначения отсутствуют.").font(.system(size: 12)).foregroundColor(.secondary)
                        Spacer()
                        Button(action: { isShowingPrescriptionEditor = true }) {
                            Label("Добавить назначение", systemImage: "plus.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(visit.prescriptions.enumerated()), id: \.element.id) { index, item in
                            let rawName = item.drugName
                            let cleanName = rawName.components(separatedBy: " (").first ?? rawName
                            let prescriptionString = "\(cleanName) \(item.dosage) \(item.frequency) № \(item.duration)"
                            
                            HStack(alignment: .center, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.blue)
                                    .frame(width: 20, alignment: .leading)
                                
                                Text(prescriptionString)
                                    .font(.system(size: 13, weight: .bold))
                                
                                Spacer()
                                
                                Button(role: .destructive, action: {
                                    modelContext.delete(item)
                                    try? modelContext.save()
                                }) {
                                    Image(systemName: "trash").font(.system(size: 12))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.04))
                            .cornerRadius(4)
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: { isShowingPrescriptionEditor = true }) {
                                Label("Добавить препарат", systemImage: "plus")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding(10)
        }
    }
    
    private var medicationUsageSectionView: some View {
        prescriptionDisclosureSection(title: "ИСПОЛЬЗОВАНИЕ МЕДИКАМЕНТОВ", badgeCount: visit.medicationUsages.count, isExpanded: $isMedicationExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                if visit.medicationUsages.isEmpty {
                    HStack {
                        Text("Использование медикаментов не зафиксировано.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: { isShowingMedicationEditor = true }) {
                            Label("Добавить медикамент", systemImage: "plus.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(visit.medicationUsages.enumerated()), id: \.element.id) { index, item in
                            let rawName = item.drugName
                            let cleanName = rawName.components(separatedBy: " (").first ?? rawName
                            let usageString = "\(cleanName) \(item.dosage) \(item.frequency) № \(item.duration)"
                            
                            HStack(alignment: .center, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.blue)
                                    .frame(width: 20, alignment: .leading)
                                
                                Text(usageString)
                                    .font(.system(size: 13, weight: .bold))
                                
                                Spacer()
                                
                                Button(role: .destructive, action: {
                                    modelContext.delete(item)
                                    try? modelContext.save()
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.04))
                            .cornerRadius(4)
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: { isShowingMedicationEditor = true }) {
                                Label("Добавить препарат", systemImage: "plus")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding(10)
        }
        .sheet(isPresented: $isShowingMedicationEditor) {
            PrescriptionEditorView { newItem in
                let usageItem = MedicationUsageItem(
                    drugName: newItem.drugName,
                    dosage: newItem.dosage,
                    frequency: newItem.frequency,
                    duration: newItem.duration
                )
                usageItem.visit = visit
                visit.medicationUsages.append(usageItem)
                modelContext.insert(usageItem)
                try? modelContext.save()
            }
        }
    }
    
    private var bottomSaveBar: some View {
        HStack {
            Spacer()
            Button("Сохранить") {
                saveVisitData()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12).background(Color(red: 0.95, green: 0.95, blue: 0.95))
    }
    
    private func saveVisitData() {
        visit.examinationText = examinationText
        visit.vitalHeight = vitalHeight
        visit.vitalWeight = vitalWeight
        visit.vitalWaist = vitalWaist
        visit.vitalTemperature = vitalTemperature
        visit.vitalBpSystolic = vitalBpSystolic
        visit.vitalBpDiastolic = vitalBpDiastolic
        visit.vitalHeartRate = vitalHeartRate
        visit.vitalPulse = vitalPulse
        visit.vitalSaturation = vitalSaturation
        visit.vitalRespiratoryRate = vitalRespiratoryRate
        try? modelContext.save()
    }
    
    private func loadInitialData() {
        self.examinationText = visit.examinationText
        self.vitalHeight = visit.vitalHeight
        self.vitalWeight = visit.vitalWeight
        self.vitalWaist = visit.vitalWaist
        self.vitalTemperature = visit.vitalTemperature
        self.vitalBpSystolic = visit.vitalBpSystolic
        self.vitalBpDiastolic = visit.vitalBpDiastolic
        self.vitalHeartRate = visit.vitalHeartRate
        self.vitalPulse = visit.vitalPulse
        self.vitalSaturation = visit.vitalSaturation
        self.vitalRespiratoryRate = visit.vitalRespiratoryRate
    }

    private func vitalField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 10)).foregroundColor(.secondary)
            TextField("", text: text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
        }
    }

    private var isVitalParamsEmpty: Bool {
        vitalHeight.isEmpty && vitalWeight.isEmpty && vitalTemperature.isEmpty &&
        vitalBpSystolic.isEmpty && vitalBpDiastolic.isEmpty && vitalHeartRate.isEmpty &&
        vitalPulse.isEmpty && vitalSaturation.isEmpty && vitalWaist.isEmpty && vitalRespiratoryRate.isEmpty
    }
    
    @ViewBuilder
    private func disclosureSection<Content: View>(title: String, subtitle: String? = nil, badgeCount: Int? = nil, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: { isExpanded.wrappedValue.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                        Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                        if let sub = subtitle { Text("— \(sub)").font(.system(size: 11)).foregroundColor(.secondary) }
                        if let badge = badgeCount, badge > 0 {
                            Text("\(badge)").font(.system(size: 10, weight: .bold)).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 1).background(Color.blue).clipShape(Capsule())
                        }
                    }
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 7).background(Color(red: 0.91, green: 0.91, blue: 0.91))
            
            if isExpanded.wrappedValue {
                VStack(alignment: .leading, spacing: 0) { content() }
                .frame(maxWidth: .infinity, alignment: .leading).background(Color.white)
            }
        }
        .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
    }
    
    @ViewBuilder
    private func examDisclosureSection<Content: View>(title: String, badgeCount: Int, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: { isExpanded.wrappedValue.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                        Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                        if badgeCount > 0 {
                            Text("\(badgeCount)").font(.system(size: 10, weight: .bold)).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 1).background(Color.blue).clipShape(Capsule())
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if !isEditingExam {
                    Button(action: {
                        isExpanded.wrappedValue = true
                        isEditingExam = true
                    }) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .bold)).foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Заполнить осмотр по шаблону")
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 7).background(Color(red: 0.91, green: 0.91, blue: 0.91))
            
            if isExpanded.wrappedValue {
                VStack(alignment: .leading, spacing: 0) { content() }
                .frame(maxWidth: .infinity, alignment: .leading).background(Color.white)
            }
        }
        .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
    }
    
    @ViewBuilder
    private func prescriptionDisclosureSection<Content: View>(title: String, badgeCount: Int, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: { isExpanded.wrappedValue.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                        Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                        if badgeCount > 0 {
                            Text("\(badgeCount)").font(.system(size: 10, weight: .bold)).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 1).background(Color.blue).clipShape(Capsule())
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    isExpanded.wrappedValue = true
                    isShowingPrescriptionEditor = true
                }) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .bold)).foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Добавить назначение")
            }
            .padding(.horizontal, 10).padding(.vertical, 7).background(Color(red: 0.91, green: 0.91, blue: 0.91))
            
            if isExpanded.wrappedValue {
                VStack(alignment: .leading, spacing: 0) { content() }
                .frame(maxWidth: .infinity, alignment: .leading).background(Color.white)
            }
        }
        .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
    }
    
    private func disclosureHeaderRow(title: String, isExpanded: Binding<Bool>) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
            }
            .onTapGesture { isExpanded.wrappedValue.toggle() }
            Spacer()
            Button(action: {}) { Image(systemName: "plus").font(.system(size: 12, weight: .bold)).foregroundColor(.secondary) }.buttonStyle(.plain)
        }
        .padding(.horizontal, 10).padding(.vertical, 7).background(Color(red: 0.91, green: 0.91, blue: 0.91))
        .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
    }
    
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"; return df.string(from: date)
    }
}

// MARK: - РЕДАКТИРОВАНИЕ ПОСЕЩЕНИЯ
struct EditVisitSheetView: View {
    @Environment(\.dismiss) private var dismiss
    var visit: OutpatientVisit
    var patients: [PatientRecord]
    var onSave: () -> Void

    @State private var diagnosis: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Редактирование приема")
                .font(.headline)
            TextField("Диагноз", text: $diagnosis)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Отмена") { dismiss() }
                Spacer()
                Button("Сохранить") {
                    visit.complaintsAndDiagnosis = diagnosis
                    onSave()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear {
            diagnosis = visit.complaintsAndDiagnosis
        }
    }
}

// MARK: - ЧЕКБОКС ТАБЛИЦЫ
struct TableRowCheckbox: View {
    @Binding var isOn: Bool

    var body: some View {
        Image(systemName: isOn ? "checkmark.square.fill" : "square")
            .foregroundColor(isOn ? .accentColor : .secondary)
            .onTapGesture {
                isOn.toggle()
            }
    }
}

// MARK: - ДОКУМЕНТ ПЕЧАТИ КАРТЫ АМБУЛАТОРНОГО ПРИЕМА
struct VisitPrintDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    var visit: OutpatientVisit

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Предпросмотр печатной формы (А5, альбомная)")
                    .font(.subheadline.bold())
                Spacer()
                Button("Печать") {
                    printDocument()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Закрыть") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
            .background(Color(red: 0.94, green: 0.94, blue: 0.94))
            
            Divider()
            
            ScrollView {
                printContentBody()
                    .padding(20)
                    .frame(width: 555)
                    .background(Color.white)
            }
        }
        .frame(width: 630, height: 700)
    }
    
    @ViewBuilder
    private func printContentBody() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Дата и время обращения: \(formatDateTime(visit.visitDate))")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Пациент: **\(visit.patientName)**").font(.system(size: 10))
                Text("Дата рождения: **\(formatDate(visit.patientBirthDate))** | Пол: **\(visit.patientGender)**").font(.system(size: 10))
                Text("Адрес: **\(visit.patientAddress.isEmpty ? "—" : visit.patientAddress)**").font(.system(size: 10))
            }
            .padding(5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(4)
            
            if !visit.visitHeight.isEmpty || !visit.visitWeight.isEmpty || !visit.visitTemperature.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Витальные параметры:")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("Рост: \(visit.visitHeight) см | Вес: \(visit.visitWeight) кг | t: \(visit.visitTemperature) °C | АД: \(visit.visitBpSystolic)/\(visit.visitBpDiastolic) | ЧСС: \(visit.visitHeartRate) | Сатурация: \(visit.visitSaturation)%")
                        .font(.system(size: 9))
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 3) {
                Text("ДАННЫЕ ОСМОТРА")
                    .font(.system(size: 10, weight: .bold))
                
                Text(visit.examinationText.isEmpty ? "Осмотр не зафиксирован." : visit.examinationText)
                    .font(.system(size: 10))
                    .lineLimit(6)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Диагноз (по МКБ-10 / жалобы):")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                Text(visit.complaintsAndDiagnosis)
                    .font(.system(size: 10, weight: .semibold))
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 3) {
                Text("НАЗНАЧЕНИЯ ЛЕКАРСТВЕННЫХ ПРЕПАРАТОВ")
                    .font(.system(size: 10, weight: .bold))
                
                if visit.prescriptions.isEmpty {
                    Text("Назначения отсутствуют.").font(.system(size: 9)).foregroundColor(.secondary)
                } else {
                    ForEach(Array(visit.prescriptions.enumerated()), id: \.element.id) { index, item in
                        Text("\(index + 1). \(item.drugName) — \(item.dosage), \(item.frequency), № \(item.duration)")
                            .font(.system(size: 9))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("ИСПОЛЬЗОВАННЫЕ МЕДИКАМЕНТЫ (ФАП)")
                    .font(.system(size: 10, weight: .bold))
                
                if visit.medicationUsages.isEmpty {
                    Text("Использование медикаментов не зафиксировано.").font(.system(size: 9)).foregroundColor(.secondary)
                } else {
                    ForEach(Array(visit.medicationUsages.enumerated()), id: \.element.id) { index, item in
                        Text("\(index + 1). \(item.drugName) — \(item.dosage), \(item.frequency), № \(item.duration)")
                            .font(.system(size: 9))
                    }
                }
            }
            
            Spacer(minLength: 10)
            
            HStack {
                Text("Фельдшер: _____________________ / Ковалёв С.Л. /")
                    .font(.system(size: 10, weight: .bold))
                Spacer()
                Text("М.П.")
                    .font(.system(size: 10, weight: .bold))
            }
        }
    }
    
    private func printDocument() {
        #if os(macOS)
        let printInfo = NSPrintInfo.shared
        printInfo.orientation = .landscape
        printInfo.paperSize = NSSize(width: 595.0, height: 420.0)
        printInfo.leftMargin = 20.0
        printInfo.rightMargin = 20.0
        printInfo.topMargin = 20.0
        printInfo.bottomMargin = 20.0
        
        let contentView = printContentBody()
            .frame(width: 555, height: 380)
            .background(Color.white)
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = CGRect(x: 0, y: 0, width: 595, height: 420)
        hostingView.layoutSubtreeIfNeeded()
        
        let printOp = NSPrintOperation(view: hostingView, printInfo: printInfo)
        printOp.showsPrintPanel = true
        printOp.run()
        #endif
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"; return df.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy HH:mm"; return df.string(from: date)
    }
}

func exportVisitToWord(visit: OutpatientVisit) {
    let htmlContent = generateVisitHTML(for: visit)
    let fileName = "Амбулаторная_карта_\(visit.patientName.replacingOccurrences(of: " ", with: "_"))_\(formatDateForFileName(visit.visitDate)).doc"
    
    #if os(macOS)
    let savePanel = NSSavePanel()
    savePanel.title = "Экспорт амбулаторного приема в Word"
    savePanel.allowedContentTypes = [.init(filenameExtension: "doc")!, .html]
    savePanel.nameFieldStringValue = fileName
    
    savePanel.begin { response in
        if response == .OK, let url = savePanel.url {
            do {
                try htmlContent.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Ошибка сохранения файла: \(error.localizedDescription)")
            }
        }
    }
    #elseif os(iOS)
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    do {
        try htmlContent.write(to: tempURL, atomically: true, encoding: .utf8)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    } catch {
        print("Ошибка сохранения файла на iOS: \(error.localizedDescription)")
    }
    #endif
}

func generateVisitHTML(for visit: OutpatientVisit) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
    let dateStr = dateFormatter.string(from: visit.visitDate)
    
    let birthDateStr: String = {
        guard let bd = visit.patientBirthDate else { return "—" }
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: bd)
    }()
    
    var prescriptionsHTML = ""
    if visit.prescriptions.isEmpty {
        prescriptionsHTML = "<i>Назначения отсутствуют.</i>"
    } else {
        prescriptionsHTML = "<ol>"
        for item in visit.prescriptions {
            prescriptionsHTML += "<li><b>\(item.drugName)</b> — \(item.dosage), \(item.frequency), № \(item.duration)</li>"
        }
        prescriptionsHTML += "</ol>"
    }
    
    var usagesHTML = ""
    if visit.medicationUsages.isEmpty {
        usagesHTML = "<i>Использование медикаментов не зафиксировано.</i>"
    } else {
        usagesHTML = "<ol>"
        for item in visit.medicationUsages {
            usagesHTML += "<li><b>\(item.drugName)</b> — \(item.dosage), \(item.frequency), № \(item.duration)</li>"
        }
        usagesHTML += "</ol>"
    }
    
    return """
    <html>
    <head>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Times New Roman', Times, serif; font-size: 14pt; line-height: 1.3; color: #000; margin: 40px; }
        .date { text-align: left; font-weight: bold; color: #555; margin-bottom: 15px; font-size: 12pt; }
        .section-title { font-weight: bold; margin-top: 15px; margin-bottom: 5px; font-size: 13pt; text-transform: uppercase; }
        .patient-box { background-color: #f9f9f9; border: 1px solid #ccc; padding: 10px; margin-bottom: 15px; }
        ol { margin-top: 5px; padding-left: 20px; }
        li { margin-bottom: 4px; }
        .footer { margin-top: 30px; width: 100%; font-weight: bold; }
    </style>
    </head>
    <body>
        <div class="date">Дата и время обращения: \(dateStr)</div>
        
        <div class="patient-box">
            <b>Пациент:</b> \(visit.patientName)<br>
            <b>Дата рождения:</b> \(birthDateStr) &nbsp;&nbsp;|&nbsp;&nbsp; <b>Пол:</b> \(visit.patientGender)<br>
            <b>Адрес:</b> \(visit.patientAddress.isEmpty ? "—" : visit.patientAddress)
        </div>
        
        \(!visit.visitHeight.isEmpty || !visit.visitWeight.isEmpty ? """
        <div style="font-size: 12pt; color: #333; margin-bottom: 15px;">
            <b>Витальные параметры:</b> Рост: \(visit.visitHeight) см | Вес: \(visit.visitWeight) кг | t: \(visit.visitTemperature) °C | АД: \(visit.visitBpSystolic)/\(visit.visitBpDiastolic) | ЧСС: \(visit.visitHeartRate) | Сатурация: \(visit.visitSaturation)%
        </div>
        """ : "")

        <div class="section-title">Данные осмотра</div>
        <div>\(visit.examinationText.isEmpty ? "Осмотр не зафиксирован." : visit.examinationText.replacingOccurrences(of: "\n", with: "<br>"))</div>

        <div class="section-title" style="margin-top: 20px;">Диагноз (по МКБ-10 / жалобы)</div>
        <div style="font-weight: bold; font-size: 14pt;">\(visit.complaintsAndDiagnosis)</div>

        <div class="section-title" style="margin-top: 20px;">Назначения лекарственных препаратов</div>
        \(prescriptionsHTML)

        <div class="section-title" style="margin-top: 20px;">Использованные медикаменты (ФАП)</div>
        \(usagesHTML)

        <table class="footer" style="margin-top: 40px;">
            <tr>
                <td>Фельдшер: _____________________ / Ковалёв С.Л. /</td>
                <td style="text-align: right;">М.П.</td>
            </tr>
        </table>
    </body>
    </html>
    """
}

func formatDateForFileName(_ date: Date) -> String {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd_HH-mm"
    return df.string(from: date)
}
