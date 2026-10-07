import SwiftUI

// MARK: - 1. Главные кабинеты ФАП
enum FAPSection: String, CaseIterable, Identifiable {
    case outpatient = "1. Амбулаторный прием"
    case treatment = "2. Процедурный кабинет"
    case vaccination = "3. Прививочный кабинет"
    case disp = "4. Диспансеризация"
    case flg = "5. Кабинет ФЛГ"
    case admin = "6. Управление учетными записями"

    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .outpatient: return "stethoscope"
        case .treatment: return "syringe"
        case .vaccination: return "cross.case.fill"
        case .disp: return "heart.text.square"
        case .flg: return "rays"
        case .admin: return "person.badge.key.fill"
        }
    }
}

// MARK: - 2. Подразделы
enum OutpatientSubTab: String, CaseIterable, Identifiable {
    case population = "Прикреплённое население"
    case journal = "Журнал приёма"
    case smpJournal = "Журнал вызовов СМП"
    case exchange = "Обмен данными"
    
    var id: String { rawValue }
}

enum VaccinationSubTab: String, CaseIterable, Identifiable {
    case registry = "Картотека прививок"
    case exchange = "Импорт / Экспорт (CSV)"

    var id: String { rawValue }
}

enum TreatmentSubTab: String, CaseIterable, Identifiable {
    case journal = "Журнал процедур"
    case medications = "Журнал медикаментов"
    case exchange = "Обмен данными"

    var id: String { rawValue }
}

// MARK: - 3. Главное представление
struct MainSidebarLayoutView: View {
    @State private var activeSection: FAPSection? = nil
    @State private var activeOutpatientTab: OutpatientSubTab = .journal
    @State private var activeVaccinationTab: VaccinationSubTab = .registry
    @State private var activeTreatmentTab: TreatmentSubTab = .journal
    @State private var activeSubTab: String = "Список"
    
    private let sidebarWidth: CGFloat = 280
    
    var body: some View {
        NavigationSplitView {
            Group {
                if let section = activeSection {
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { activeSection = nil }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left.circle.fill")
                                Text("Все кабинеты")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        Divider()
                        
                        Text(section.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                        
                        List {
                            sectionSubMenu(for: section)
                        }
                        .listStyle(.sidebar)
                    }
                } else {
                    List(FAPSection.allCases) { section in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeSection = section
                                setDefaultSubTab(for: section)
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: section.iconName)
                                    .foregroundColor(.blue)
                                Text(section.rawValue)
                                    .font(.headline)
                            }
                            .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                    }
                    .navigationTitle("ФАП «Здоровье»")
                }
            }
            .navigationSplitViewColumnWidth(min: sidebarWidth, ideal: sidebarWidth, max: sidebarWidth)
            .frame(minWidth: sidebarWidth, maxWidth: sidebarWidth)
        } detail: {
            if let section = activeSection {
                detailView(for: section)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "cross.case.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.blue.opacity(0.8))
                    Text("АРМ Фельдшерско-акушерского пункта")
                        .font(.title.bold())
                    Text("Выберите кабинет в левом меню для начала работы")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sectionSubMenu(for section: FAPSection) -> some View {
        switch section {
        case .outpatient:
            Section("Амбулаторная работа") {
                Button(action: { activeOutpatientTab = .population }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(activeOutpatientTab == .population ? .blue : .secondary)
                        Text("Прикреплённое население")
                    }
                    .foregroundColor(activeOutpatientTab == .population ? .blue : .primary)
                }
                .buttonStyle(.plain)
                
                Button(action: { activeOutpatientTab = .journal }) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(activeOutpatientTab == .journal ? .blue : .secondary)
                        Text("Журнал приёма")
                    }
                    .foregroundColor(activeOutpatientTab == .journal ? .blue : .primary)
                }
                .buttonStyle(.plain)
                
                Button(action: { activeOutpatientTab = .smpJournal }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(activeOutpatientTab == .smpJournal ? .blue : .secondary)
                        Text("Журнал вызовов СМП")
                    }
                    .foregroundColor(activeOutpatientTab == .smpJournal ? .blue : .primary)
                }
                .buttonStyle(.plain)

                Button(action: { activeOutpatientTab = .exchange }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(activeOutpatientTab == .exchange ? .blue : .secondary)
                        Text("Обмен / Экспорт (CSV)")
                    }
                    .foregroundColor(activeOutpatientTab == .exchange ? .blue : .primary)
                }
                .buttonStyle(.plain)
            }

        case .vaccination:
            Section("Прививочная работа") {
                Button(action: { activeVaccinationTab = .registry }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(activeVaccinationTab == .registry ? .blue : .secondary)
                        Text("Картотека прививок")
                    }
                    .foregroundColor(activeVaccinationTab == .registry ? .blue : .primary)
                }
                .buttonStyle(.plain)
                
                Button(action: { activeVaccinationTab = .exchange }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(activeVaccinationTab == .exchange ? .blue : .secondary)
                        Text("Импорт / Экспорт (CSV)")
                    }
                    .foregroundColor(activeVaccinationTab == .exchange ? .blue : .primary)
                }
                .buttonStyle(.plain)
            }
            
        case .treatment:
            Section("Процедурный кабинет") {
                Button(action: { activeTreatmentTab = .journal }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(activeTreatmentTab == .journal ? .blue : .secondary)
                        Text("Журнал процедур")
                    }
                    .foregroundColor(activeTreatmentTab == .journal ? .blue : .primary)
                }
                .buttonStyle(.plain)
                
                Button(action: { activeTreatmentTab = .medications }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pills.fill")
                            .foregroundColor(activeTreatmentTab == .medications ? .blue : .secondary)
                        Text("Журнал медикаментов")
                    }
                    .foregroundColor(activeTreatmentTab == .medications ? .blue : .primary)
                }
                .buttonStyle(.plain)
                
                Button(action: { activeTreatmentTab = .exchange }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(activeTreatmentTab == .exchange ? .blue : .secondary)
                        Text("Обмен данными")
                    }
                    .foregroundColor(activeTreatmentTab == .exchange ? .blue : .primary)
                }
                .buttonStyle(.plain)
            }
            
        case .disp:
            Section("Диспансеризация") {
                Button(action: { activeSubTab = "Анкета" }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.secondary)
                        Text("Оформить 1 этап")
                    }
                }
                .buttonStyle(.plain)
            }
            
        case .flg:
            Section("Флюорография") {
                Button(action: { activeSubTab = "Результаты" }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal")
                            .foregroundColor(.secondary)
                        Text("Внести результат ФЛГ")
                    }
                }
                .buttonStyle(.plain)
            }
            
        case .admin:
            Section("Администрирование") {
                Button(action: { activeSubTab = "Пользователи" }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.secondary)
                        Text("Список учетных записей")
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func setDefaultSubTab(for section: FAPSection) {
        switch section {
        case .outpatient: activeOutpatientTab = .journal
        case .vaccination: activeVaccinationTab = .registry
        case .treatment: activeTreatmentTab = .journal
        case .disp: activeSubTab = "Анкета"
        case .flg: activeSubTab = "Результаты"
        case .admin: activeSubTab = "Пользователи"
        }
    }
    
    @ViewBuilder
    private func detailView(for section: FAPSection) -> some View {
        switch section {
        case .outpatient:
            OutpatientView(activeSubTab: activeOutpatientTab)
        case .vaccination:
            if activeVaccinationTab == .registry {
                PatientListView()
            } else {
                DataExchangeView()
            }
        case .treatment:
            if activeTreatmentTab == .journal {
                TreatmentRoomView()
            } else if activeTreatmentTab == .medications {
                MedicationAccountingView()
            } else {
                DataExchangeView()
            }
        case .disp: ClinicalExaminationView()
        case .flg: FluorographyView()
        case .admin: AdminUsersView()
        }
    }
}
