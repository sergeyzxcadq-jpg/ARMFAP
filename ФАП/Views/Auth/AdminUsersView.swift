import SwiftUI
import SwiftData

struct AdminUsersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppUser.username) private var users: [AppUser]
    @Query(sort: \AdminMedicationItem.drugName) private var medications: [AdminMedicationItem]
    
    @Binding var selectedAdminTab: ContentView.AdminSubTab
    
    init(selectedAdminTab: Binding<ContentView.AdminSubTab>? = nil) {
        self._selectedAdminTab = selectedAdminTab ?? Binding(
            get: { .users },
            set: { _ in }
        )
    }
    
    @State private var isShowingAddUser = false
    @State private var userToDelete: AppUser? = nil
    @State private var isShowingDeleteConfirm = false
    
    @State private var isShowingAddMedication = false
    @State private var medToDelete: AdminMedicationItem? = nil
    @State private var isShowingDeleteMedConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Верхняя шапка панели администратора
            HStack(spacing: 16) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Панель администратора")
                        .font(.title2.bold())
                    Text(subtitleText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.gray.opacity(0.06))
            
            Divider()
            
            // Отображение контента в зависимости от выбранной вкладки
            switch selectedAdminTab {
            case .users:
                usersManagementView
            case .attributes:
                AdminAttributesView()
            case .medications:
                medicationsManagementView
            }
        }
        .sheet(isPresented: $isShowingAddUser) {
            AddUserOverlayView(
                onClose: { isShowingAddUser = false },
                onUserCreated: { newUser in
                    modelContext.insert(newUser)
                    try? modelContext.save()
                    isShowingAddUser = false
                }
            )
        }
        .sheet(isPresented: $isShowingAddMedication) {
            AdminAddMedicationModalView { newMed in
                // Явное добавление и принудительное сохранение в модель SwiftData
                modelContext.insert(newMed)
                do {
                    try modelContext.save()
                } catch {
                    print("Ошибка сохранения медикамента: \(error.localizedDescription)")
                }
            }
        }
        .alert("Удаление пользователя", isPresented: $isShowingDeleteConfirm) {
            Button("Удалить", role: .destructive) {
                if let target = userToDelete {
                    modelContext.delete(target)
                    try? modelContext.save()
                }
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Вы действительно хотите удалить учетную запись сотрудника \(userToDelete?.fullName ?? "")?")
        }
        .alert("Удаление медикамента", isPresented: $isShowingDeleteMedConfirm) {
            Button("Удалить", role: .destructive) {
                if let target = medToDelete {
                    modelContext.delete(target)
                    try? modelContext.save()
                }
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Удалить препарат «\(medToDelete?.drugName ?? "")» из справочника?")
        }
    }
    
    private var subtitleText: String {
        switch selectedAdminTab {
        case .users: return "Управление учётными записями сотрудников"
        case .attributes: return "Редактирование атрибутов посещения"
        case .medications: return "Единый справочник лекарственных средств и назначений"
        }
    }
    
    // Вкладка: Учетные записи
    private var usersManagementView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { isShowingAddUser = true }) {
                    Label("Добавить сотрудника", systemImage: "person.badge.plus")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .padding(12)
            }
            
            Divider()
            
            if users.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.3.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("В системе нет зарегистрированных пользователей")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(users) { user in
                        HStack(spacing: 16) {
                            Image(systemName: user.isAdmin || user.isDefaultAdmin ? "person.crop.circle.badge.checkmark" : "person.crop.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(user.isAdmin || user.isDefaultAdmin ? .purple : .blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(user.fullName)
                                        .font(.headline)
                                    if user.isAdmin || user.isDefaultAdmin {
                                        Text("Администратор")
                                            .font(.caption2.bold())
                                            .foregroundColor(.purple)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                HStack(spacing: 16) {
                                    Text("Логин: **\(user.username)**")
                                    Text("Должность: **\(user.position.isEmpty ? "Не указана" : user.position)**")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive, action: {
                                userToDelete = user
                                isShowingDeleteConfirm = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            .help("Удалить пользователя")
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.inset)
            }
        }
    }
    
    // Вкладка: Медикаменты (Единый справочник)
    private var medicationsManagementView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Справочник медикаментов (единая база для назначений)")
                    .font(.headline)
                Spacer()
                Button(action: { isShowingAddMedication = true }) {
                    Label("Добавить медикамент", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .padding(12)
            }
            .padding(.horizontal)
            
            Divider()
            
            if medications.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "pills.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Справочник медикаментов пуст")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Добавьте препараты, чтобы они появились в назначениях врачей.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(medications) { med in
                        HStack(spacing: 16) {
                            Image(systemName: "cross.vial.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(med.drugName)
                                    .font(.headline)
                                
                                HStack(spacing: 16) {
                                    Text("Дозировка: **\(med.dosage.isEmpty ? "—" : med.dosage)**")
                                    Text("Способ: **\(med.administration.isEmpty ? "—" : med.administration)**")
                                    Text("Кратность: **\(med.frequency.isEmpty ? "—" : med.frequency)**")
                                    Text("Курс: **\(med.duration.isEmpty ? "—" : med.duration)**")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive, action: {
                                medToDelete = med
                                isShowingDeleteMedConfirm = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

// MARK: - Модальное окно добавления медикамента в единую базу
struct AdminAddMedicationModalView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (AdminMedicationItem) -> Void
    
    @State private var drugName = ""
    @State private var dosage = "500 мг"
    @State private var administration = "Внутрь"
    @State private var frequency = "3 раза в день"
    @State private var duration = "7 дней"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Добавление медикамента в единый справочник")
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Название препарата:").font(.caption.bold())
                    TextField("например: Амоксициллин", text: $drugName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Дозировка:").font(.caption.bold())
                    TextField("например: 500 мг", text: $dosage)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Способ применения:").font(.caption.bold())
                    TextField("например: Внутрь, после еды", text: $administration)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Кратность приема:").font(.caption.bold())
                    TextField("например: 3 раза в день", text: $frequency)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Курс (длительность):").font(.caption.bold())
                    TextField("например: 7 дней", text: $duration)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(20)
            
            Divider()
            
            HStack {
                Button("Отмена") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Сохранить в справочник") {
                    let trimmedName = drugName.trimmingCharacters(in: .whitespaces)
                    guard !trimmedName.isEmpty else { return }
                    
                    let newItem = AdminMedicationItem(
                        drugName: trimmedName,
                        dosage: dosage,
                        administration: administration,
                        frequency: frequency,
                        duration: duration
                    )
                    onSave(newItem)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(drugName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(14)
            .background(Color.gray.opacity(0.1))
        }
        .frame(width: 480, height: 420)
    }
}
