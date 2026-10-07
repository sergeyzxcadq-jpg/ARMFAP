import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppUser.username) private var users: [AppUser]
    
    @Binding var currentUser: AppUser?
    
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isShowingAddUserModal = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Верхняя синяя шапка
                VStack(spacing: 8) {
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                    
                    Text("АРМ «Фельдшерско-акушерского пункта»")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("Авторизация медработника")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color(red: 0.0, green: 0.45, blue: 0.68))
                
                // Основной блок формы
                VStack(alignment: .leading, spacing: 18) {
                    if users.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 38))
                                .foregroundColor(.blue)
                            
                            Text("Пользователи не найдены")
                                .font(.headline)
                            
                            Text("Для первого входа необходимо зарегистрировать профиль сотрудника.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                withAnimation { isShowingAddUserModal = true }
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                    Text("Зарегистрировать пользователя")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 16)
                    } else {
                        // ПОЛЕ ЛОГИНА СО ВСТРОЕННЫМ ВЫПАДАЮЩИМ СПИСКОМ ПОЛЬЗОВАТЕЛЕЙ
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Имя пользователя (логин)").font(.caption.bold()).foregroundColor(.secondary)
                            HStack(spacing: 6) {
                                Image(systemName: "person.fill").foregroundColor(.blue)
                                TextField("Введите или выберите логин", text: $username)
                                    .textFieldStyle(.plain)
                                
                                // Меню выбора пользователя прямо внутри строки логина
                                Menu {
                                    ForEach(users, id: \.id) { user in
                                        Button(action: {
                                            username = user.username
                                            errorMessage = ""
                                        }) {
                                            Text("\(user.fullName) (\(user.username))")
                                        }
                                    }
                                } label: {
                                    Image(systemName: "chevron.down.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                }
                                .menuStyle(.borderlessButton)
                                .frame(width: 24, height: 24)
                                .help("Выбрать из списка зарегистрированных")
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Пароль").font(.caption.bold()).foregroundColor(.secondary)
                            HStack {
                                Image(systemName: "lock.fill").foregroundColor(.blue)
                                SecureField("Введите пароль", text: $password)
                                    .textFieldStyle(.plain)
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Button(action: performLogin) {
                            HStack {
                                Spacer()
                                Text("Войти в систему").font(.headline)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty)
                        
                        Divider().padding(.vertical, 4)
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation { isShowingAddUserModal = true }
                            }) {
                                Label("Добавить ещё одного пользователя", systemImage: "person.badge.plus")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                    }
                }
                .padding(28)
            }
            .frame(width: 440)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 6)
            .disabled(isShowingAddUserModal)
            
            if isShowingAddUserModal {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { isShowingAddUserModal = false } }
                
                AddUserOverlayView(
                    onClose: { withAnimation { isShowingAddUserModal = false } },
                    onUserCreated: { newUser in
                        modelContext.insert(newUser)
                        try? modelContext.save()
                        self.username = newUser.username
                        withAnimation { isShowingAddUserModal = false }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func performLogin() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        if let user = users.first(where: { $0.username.lowercased() == trimmedUsername.lowercased() }) {
            if user.passwordHash == password {
                withAnimation { currentUser = user }
            } else {
                errorMessage = "Неверный пароль. Попробуйте снова."
            }
        } else {
            errorMessage = "Пользователь с таким логином не найден."
        }
    }
}

// MARK: - Всплывающий оверлей регистрации сотрудника
struct AddUserOverlayView: View {
    var onClose: () -> Void
    var onUserCreated: (AppUser) -> Void
    
    @Query private var existingUsers: [AppUser]
    
    @State private var username = ""
    @State private var fullName = ""
    @State private var position = "Фельдшер"
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isAdmin = false
    @State private var validationError = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("Регистрация сотрудника")
                    .font(.title2.bold())
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Логин").font(.caption.bold())
                    TextField("например: ivanov_fap", text: $username)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("ФИО полностью").font(.caption.bold())
                    TextField("Иванов Иван Иванович", text: $fullName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Должность").font(.caption.bold())
                    TextField("Заведующий ФАП / Фельдшер", text: $position)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Пароль").font(.caption.bold())
                    SecureField("Введите пароль", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Подтверждение пароля").font(.caption.bold())
                    SecureField("Повторите пароль", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
                
                Toggle("Права администратора системы", isOn: $isAdmin)
                    .font(.subheadline.bold())
                    .padding(.top, 4)
            }
            
            if !validationError.isEmpty {
                Text(validationError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack {
                Button("Отмена", action: onClose)
                    .buttonStyle(.bordered)
                Spacer()
                Button("Сохранить") {
                    validateAndSave()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(maxWidth: 440)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
        .onAppear {
            if existingUsers.isEmpty {
                isAdmin = true
            }
        }
    }
    
    private func validateAndSave() {
        validationError = ""
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        let trimmedFullName = fullName.trimmingCharacters(in: .whitespaces)
        
        if trimmedUsername.isEmpty {
            validationError = "Заполните имя пользователя (логин)."
            return
        }
        if trimmedFullName.isEmpty {
            validationError = "Заполните ФИО сотрудника."
            return
        }
        if password.isEmpty {
            validationError = "Введите пароль."
            return
        }
        if password != confirmPassword {
            validationError = "Пароли не совпадают."
            return
        }
        
        let shouldBeAdmin = existingUsers.isEmpty ? true : isAdmin
        
        let newUser = AppUser(
            username: trimmedUsername,
            fullName: trimmedFullName,
            position: position.trimmingCharacters(in: .whitespaces),
            passwordHash: password,
            isAdmin: shouldBeAdmin
        )
        
        onUserCreated(newUser)
    }
}
