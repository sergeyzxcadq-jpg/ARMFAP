import SwiftUI

struct AddPatientView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (PatientRecord) -> Void
    
    @State private var selectedTab = 0
    
    // Вкладка 1: Пациент
    @State private var lastName = ""
    @State private var firstName = ""
    @State private var patronymic = ""
    @State private var gender = "1. Мужской"
    @State private var birthDate = Date()
    @State private var maritalStatus = "Состоит в зарегистрированном браке"
    
    @State private var region = "Рязанская обл."
    @State private var district = "Сасовский район"
    @State private var locality = "г. Сасово"
    @State private var street = ""
    @State private var house = ""
    @State private var apartment = ""
    @State private var terrainType = "город"
    
    @State private var docType = "14. Паспорт гражданина Российской Федерации"
    @State private var docSeries = ""
    @State private var docNumber = ""
    @State private var snils = ""
    
    @State private var socStatus = "Работает"
    @State private var workplace = ""
    @State private var jobPosition = ""
    
    @State private var mobilePhone = ""
    @State private var homePhone = ""
    @State private var workPhone = ""
    
    // Вкладка 2: Дополнительно
    @State private var policyStatus = "Действует"
    @State private var cmoName = ""
    @State private var cmoAddress = ""
    @State private var cmoOGRN = ""
    @State private var policySeries = ""
    @State private var policyNumber = ""
    @State private var disabilityGroup = ""
    @State private var disabilityDegree = ""
    @State private var isInvalidFromChildhood = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            HStack {
                Text("Добавление карточки пациента")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.1, green: 0.45, blue: 0.8))
            
            // Вкладки
            Picker("", selection: $selectedTab) {
                Text("1. Пациент").tag(0)
                Text("2. Дополнительно").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            ScrollView {
                if selectedTab == 0 {
                    HStack(alignment: .top, spacing: 24) {
                        // Левая колонка
                        VStack(alignment: .leading, spacing: 10) {
                            formRow(label: "Фамилия") {
                                TextField("", text: $lastName).textFieldStyle(.roundedBorder)
                            }
                            formRow(label: "Имя") {
                                TextField("", text: $firstName).textFieldStyle(.roundedBorder)
                            }
                            formRow(label: "Отчество") {
                                TextField("", text: $patronymic).textFieldStyle(.roundedBorder)
                            }
                            formRow(label: "Пол") {
                                Picker("", selection: $gender) {
                                    Text("1. Мужской").tag("1. Мужской")
                                    Text("2. Женский").tag("2. Женский")
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            formRow(label: "Дата рождения") {
                                DatePicker("", selection: $birthDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Spacer().frame(height: 10)
                            
                            formRow(label: "Регион, область") {
                                TextField("", text: $region).textFieldStyle(.roundedBorder)
                            }
                            formRow(label: "Район") {
                                TextField("", text: $district).textFieldStyle(.roundedBorder)
                            }
                            formRow(label: "Населенный пункт") {
                                TextField("", text: $locality).textFieldStyle(.roundedBorder)
                            }
                            formRow(label: "Улица") {
                                TextField("", text: $street).textFieldStyle(.roundedBorder)
                            }
                            
                            HStack(spacing: 8) {
                                Text("Дом")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                TextField("", text: $house)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 70)
                                
                                Text("Квартира")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                TextField("", text: $apartment)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            formRow(label: "Местность") {
                                Picker("", selection: $terrainType) {
                                    Text("город").tag("город")
                                    Text("село").tag("село")
                                    Text("поселок").tag("поселок")
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Правая колонка
                        VStack(alignment: .leading, spacing: 10) {
                            formRow(label: "Вид документа") {
                                Picker("", selection: $docType) {
                                    Text("14. Паспорт гражданина Российской Федерации").tag("14. Паспорт гражданина Российской Федерации")
                                    Text("Свидетельство о рождении").tag("Свидетельство о рождении")
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            HStack(spacing: 8) {
                                Text("серия")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                TextField("", text: $docSeries)
                                    .textFieldStyle(.roundedBorder)
                                
                                Text("номер")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                TextField("", text: $docNumber)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            formRow(label: "СНИЛС") {
                                TextField("", text: $snils).textFieldStyle(.roundedBorder)
                            }
                            
                            Spacer().frame(height: 15)
                            
                            formRow(label: "Статус") {
                                Picker("", selection: $socStatus) {
                                    Text("Работает").tag("Работает")
                                    Text("Учащийся").tag("Учащийся")
                                    Text("Пенсионер").tag("Пенсионер")
                                    Text("Безработный").tag("Безработный")
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            formRow(label: "Семейное полож.") {
                                Picker("", selection: $maritalStatus) {
                                    Text("Состоит в зарегистрированном браке").tag("Состоит в зарегистрированном браке")
                                    Text("Не состоит в браке").tag("Не состоит в браке")
                                    Text("Вдовец / вдова").tag("Вдовец / вдова")
                                    Text("Разведен / разведена").tag("Разведен / разведена")
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            formRow(label: "Место работы/ учебы") {
                                TextField("", text: $workplace).textFieldStyle(.roundedBorder)
                            }
                            formRow(label: "Кем работает") {
                                TextField("", text: $jobPosition).textFieldStyle(.roundedBorder)
                            }
                            
                            Spacer().frame(height: 10)
                            
                            formRow(label: "Мобильный телефон") {
                                TextField("", text: $mobilePhone).textFieldStyle(.roundedBorder)
                            }
                            formRow(label: "Домашний телефон") {
                                TextField("", text: $homePhone).textFieldStyle(.roundedBorder)
                            }
                            formRow(label: "Рабочий телефон") {
                                TextField("", text: $workPhone).textFieldStyle(.roundedBorder)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                } else {
                    // Вкладка 2: Дополнительно
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Статус полиса")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                Picker("", selection: $policyStatus) {
                                    Text("Действует").tag("Действует")
                                    Text("Недействителен").tag("Недействителен")
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: 250, alignment: .leading)
                            }
                            
                            HStack {
                                Text("СМО ОМС:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                Picker("", selection: $cmoName) {
                                    Text("АО «СОГАЗ-Мед»").tag("АО «СОГАЗ-Мед»")
                                    Text("ООО «АльфаСтрахование-ОМС»").tag("ООО «АльфаСтрахование-ОМС»")
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button("изменить...") {}
                                    .font(.system(size: 12))
                                    .foregroundColor(.accentColor)
                            }
                            
                            HStack {
                                Text("наименование")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                TextField("", text: $cmoName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            HStack(spacing: 12) {
                                Text("адрес")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                TextField("", text: $cmoAddress)
                                    .textFieldStyle(.roundedBorder)
                                
                                Text("ОГРН")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                TextField("", text: $cmoOGRN)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 150)
                            }
                            
                            HStack(spacing: 12) {
                                Text("Полис: серия")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                TextField("", text: $policySeries)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 140)
                                
                                Text("номер")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                TextField("", text: $policyNumber)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(6)
                        
                        HStack(spacing: 10) {
                            Text("Инвалидность:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("группа")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Picker("", selection: $disabilityGroup) {
                                Text("—").tag("")
                                Text("1 группа").tag("1 группа")
                                Text("2 группа").tag("2 группа")
                                Text("3 группа").tag("3 группа")
                            }
                            .labelsHidden()
                            .frame(width: 130)
                            
                            Picker("", selection: $disabilityDegree) {
                                Text("—").tag("")
                                Text("Степень 1").tag("Степень 1")
                                Text("Степень 2").tag("Степень 2")
                                Text("Степень 3").tag("Степень 3")
                            }
                            .labelsHidden()
                            .frame(width: 130)
                            
                            Spacer()
                            
                            Toggle("Инвалид с детства", isOn: $isInvalidFromChildhood)
                                .font(.system(size: 12))
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(6)
                        
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .background(Color(red: 0.94, green: 0.94, blue: 0.94))
            
            Divider()
            
            // Кнопки управления
            HStack {
                Button(action: { dismiss() }) {
                    Text("<< Назад")
                        .frame(width: 90)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: savePatient) {
                    Text("Сохранить")
                        .frame(width: 110)
                }
                .buttonStyle(.borderedProminent)
                .disabled(lastName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(14)
            .background(Color(red: 0.90, green: 0.90, blue: 0.90))
        }
        .frame(width: 820, height: 600)
    }
    
    @ViewBuilder
    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            content()
        }
    }
    
    private func savePatient() {
        let fullName = [lastName, firstName, patronymic]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        let fullAddress = [
            !region.isEmpty ? region : nil,
            !district.isEmpty ? district : nil,
            !locality.isEmpty ? locality : nil,
            !street.isEmpty ? street : nil,
            !house.isEmpty ? "д. \(house)" : nil,
            !apartment.isEmpty ? "кв. \(apartment)" : nil
        ].compactMap { $0 }.joined(separator: ", ")
        
        let p = PatientRecord(fullName: fullName, birthDate: birthDate)
        p.lastName = lastName
        p.firstName = firstName
        p.middleName = patronymic
        p.gender = gender.contains("Жен") ? "Женский" : "Мужской"
        p.birthDate = birthDate
        p.region = region
        p.district = district
        p.locality = locality
        p.address = fullAddress.isEmpty ? street : fullAddress
        p.docType = docType
        p.docSeries = docSeries
        p.docNumber = docNumber
        p.snils = snils
        p.status = socStatus
        p.workPlace = workplace
        p.occupation = jobPosition
        p.phone = mobilePhone
        
        onSave(p)
        dismiss()
    }
}
