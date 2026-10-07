//
//  ContentView.swift
//  ФАП
//
//  Created by Sergey Kowalew on 07.10.2026.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var currentUser: AppUser? = nil
    
    @State private var selectedCabinet: CabinetType? = nil
    @State private var isShowingWiFiSync = false
    
    @State private var outpatientSubTab: OutpatientSubTab = .journal
    @State private var procedureSubTab: DefaultSubTab = .journal
    @State private var vaccinationSubTab: DefaultSubTab = .journal
    @State private var healthCheckSubTab: DefaultSubTab = .journal
    @State private var flgSubTab: DefaultSubTab = .journal
    
    @State private var adminSubTab: AdminSubTab = .users

    enum CabinetType: Hashable {
        case outpatient
        case procedure
        case vaccination
        case healthCheck
        case flg
        case admin
    }
    
    enum DefaultSubTab: Hashable {
        case journal
        case exchange
    }
    
    enum AdminSubTab: Hashable {
        case users
        case attributes
        case medications
    }

    var body: some View {
        Group {
            if let user = currentUser {
                NavigationSplitView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.fullName)
                                    .font(.subheadline.bold())
                                    .lineLimit(1)
                                Text("\(user.position) (@\(user.username))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.08))
                        
                        Divider()
                        
                        if let cabinet = selectedCabinet {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCabinet = nil
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Все кабинеты")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                            
                            switch cabinet {
                            case .outpatient:
                                List {
                                    Section("АМБУЛАТОРНЫЙ ПРИЕМ") {
                                        Button(action: { outpatientSubTab = .population }) {
                                            Label("Прикреплённое население", systemImage: "person.3.fill")
                                        }
                                        .foregroundColor(outpatientSubTab == .population ? .blue : .primary)
                                        
                                        Button(action: { outpatientSubTab = .journal }) {
                                            Label("Журнал приёма", systemImage: "book.fill")
                                        }
                                        .foregroundColor(outpatientSubTab == .journal ? .blue : .primary)
                                        
                                        Button(action: { outpatientSubTab = .smpJournal }) {
                                            Label("Журнал вызовов СМП", systemImage: "ambulance.fill")
                                        }
                                        .foregroundColor(outpatientSubTab == .smpJournal ? .blue : .primary)
                                        
                                        Button(action: { outpatientSubTab = .exchange }) {
                                            Label("Обмен данными", systemImage: "arrow.triangle.2.circlepath")
                                        }
                                        .foregroundColor(outpatientSubTab == .exchange ? .blue : .primary)
                                    }
                                }
                                .listStyle(.sidebar)
                                
                            case .procedure:
                                List {
                                    Section("ПРОЦЕДУРНЫЙ КАБИНЕТ") {
                                        Button(action: { procedureSubTab = .journal }) {
                                            Label("Журнал процедур", systemImage: "cross.vial.fill")
                                        }
                                        .foregroundColor(procedureSubTab == .journal ? .blue : .primary)
                                        
                                        Button(action: { procedureSubTab = .exchange }) {
                                            Label("Обмен данными", systemImage: "arrow.triangle.2.circlepath")
                                        }
                                        .foregroundColor(procedureSubTab == .exchange ? .blue : .primary)
                                    }
                                }
                                .listStyle(.sidebar)
                                
                            case .vaccination:
                                List {
                                    Section("ПРИВИВОЧНЫЙ КАБИНЕТ") {
                                        Button(action: { vaccinationSubTab = .journal }) {
                                            Label("Прививочная картотека", systemImage: "syringe.fill")
                                        }
                                        .foregroundColor(vaccinationSubTab == .journal ? .blue : .primary)
                                        
                                        Button(action: { vaccinationSubTab = .exchange }) {
                                            Label("Обмен данными", systemImage: "arrow.triangle.2.circlepath")
                                        }
                                        .foregroundColor(vaccinationSubTab == .exchange ? .blue : .primary)
                                    }
                                }
                                .listStyle(.sidebar)
                                
                            case .healthCheck:
                                List {
                                    Section("ДИСПАНСЕРИЗАЦИЯ") {
                                        Button(action: { healthCheckSubTab = .journal }) {
                                            Label("Картотека диспансеризации", systemImage: "heart.text.square.fill")
                                        }
                                        .foregroundColor(healthCheckSubTab == .journal ? .blue : .primary)
                                        
                                        Button(action: { healthCheckSubTab = .exchange }) {
                                            Label("Обмен данными", systemImage: "arrow.triangle.2.circlepath")
                                        }
                                        .foregroundColor(healthCheckSubTab == .healthCheck ? .blue : .primary)
                                    }
                                }
                                .listStyle(.sidebar)
                                
                            case .flg:
                                List {
                                    Section("КАБИНЕТ ФЛГ") {
                                        Button(action: { flgSubTab = .journal }) {
                                            Label("Журнал ФЛГ", systemImage: "lungs.fill")
                                        }
                                        .foregroundColor(flgSubTab == .journal ? .blue : .primary)
                                        
                                        Button(action: { flgSubTab = .exchange }) {
                                            Label("Обмен данными", systemImage: "arrow.triangle.2.circlepath")
                                        }
                                        .foregroundColor(flgSubTab == .exchange ? .blue : .primary)
                                    }
                                }
                                .listStyle(.sidebar)
                                
                            case .admin:
                                List {
                                    Section("АДМИНИСТРИРОВАНИЕ") {
                                        Button(action: { adminSubTab = .users }) {
                                            Label("Учётные записи", systemImage: "person.2.fill")
                                        }
                                        .foregroundColor(adminSubTab == .users ? .blue : .primary)
                                        
                                        Button(action: { adminSubTab = .attributes }) {
                                            Label("Редактирование атрибутов посещения", systemImage: "list.bullet.rectangle.portrait")
                                        }
                                        .foregroundColor(adminSubTab == .attributes ? .blue : .primary)
                                        
                                        Button(action: { adminSubTab = .medications }) {
                                            Label("Медикаменты", systemImage: "pills.fill")
                                        }
                                        .foregroundColor(adminSubTab == .medications ? .blue : .primary)
                                    }
                                }
                                .listStyle(.sidebar)
                            }
                            
                        } else {
                            List {
                                Section("КАБИНЕТЫ ФАП") {
                                    Button(action: { openCabinet(.outpatient) }) {
                                        Label("1. Амбулаторный прием", systemImage: "stethoscope")
                                    }
                                    
                                    Button(action: { openCabinet(.procedure) }) {
                                        Label("2. Процедурный кабинет", systemImage: "cross.vial.fill")
                                    }
                                    
                                    Button(action: { openCabinet(.vaccination) }) {
                                        Label("3. Прививочный кабинет", systemImage: "syringe")
                                    }
                                    
                                    Button(action: { openCabinet(.healthCheck) }) {
                                        Label("4. Диспансеризация", systemImage: "heart.text.square.fill")
                                    }
                                    
                                    Button(action: { openCabinet(.flg) }) {
                                        Label("5. ФЛГ", systemImage: "lungs.fill")
                                    }
                                }
                            }
                            .listStyle(.sidebar)
                        }
                        
                        Spacer()
                        Divider()
                        
                        if user.isAdmin || user.isDefaultAdmin {
                            Button(action: {
                                adminSubTab = .users
                                openCabinet(.admin)
                            }) {
                                HStack {
                                    Image(systemName: "person.badge.key.fill")
                                        .foregroundColor(.purple)
                                    Text("Панель администратора")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.purple)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                        }
                        
                        Button(action: { isShowingWiFiSync = true }) {
                            HStack {
                                Image(systemName: "wifi")
                                    .foregroundColor(.blue)
                                Text("Синхронизация по Wi-Fi")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                        
                        Button(action: {
                            withAnimation { currentUser = nil }
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Выйти из аккаунта")
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                    .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
                    
                } detail: {
                    if let cabinet = selectedCabinet {
                        switch cabinet {
                        case .outpatient:
                            OutpatientView(activeSubTab: outpatientSubTab)
                        case .procedure:
                            ProcedureRoomView(subTab: procedureSubTab)
                        case .vaccination:
                            PatientListView()
                        case .healthCheck:
                            HealthCheckView(subTab: healthCheckSubTab)
                        case .flg:
                            FLGView(subTab: flgSubTab)
                        case .admin:
                            if user.isAdmin || user.isDefaultAdmin {
                                AdminUsersView(selectedAdminTab: $adminSubTab)
                            } else {
                                Text("Доступ запрещен.")
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "cross.case.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.blue)
                            Text("Добро пожаловать в АРМ «Фельдшерско-акушерского пункта»")
                                .font(.title.bold())
                                .foregroundColor(.secondary)
                            
                            Button(action: { isShowingWiFiSync = true }) {
                                Label("Синхронизировать данные по Wi-Fi", systemImage: "wifi")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .sheet(isPresented: $isShowingWiFiSync) {
                    WiFiSyncView()
                }
            } else {
                ZStack {
                    Color.gray.opacity(0.12).ignoresSafeArea()
                    LoginView(currentUser: $currentUser)
                }
            }
        }
    }
    
    private func openCabinet(_ cabinet: CabinetType) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedCabinet = cabinet
        }
    }
}

// MARK: - Процедурка
struct ProcedureRoomView: View {
    var subTab: ContentView.DefaultSubTab
    
    var body: some View {
        if subTab == .journal {
            TreatmentRoomView()
        } else {
            DataExchangeView()
        }
    }
}

struct HealthCheckView: View {
    var subTab: ContentView.DefaultSubTab
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            Text("4. Диспансеризация (\(subTab == .journal ? "Картотека" : "Обмен данными"))")
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FLGView: View {
    var subTab: ContentView.DefaultSubTab
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            Text("5. Кабинет ФЛГ (\(subTab == .journal ? "Журнал" : "Обмен данными"))")
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
