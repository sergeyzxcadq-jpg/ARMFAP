import SwiftUI
import SwiftData

struct EditPatientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var patient: PatientRecord
    
    @State private var selectedTab = 0
    
    // Вкладка 1: Пациент
    @State private var lastName: String = ""
    @State private var firstName: String = ""
    @State private var patronymic: String = ""
    @State private var gender: String = "1. Мужской"
    @State private var birthDate: Date = Date()
    @State private var maritalStatus: String = "Состоит в зарегистрированном браке"
    
    @State private var region: String = ""
    @State private var district: String = ""
    @State private var locality: String = ""
    @State private var street: String = ""
    @State private var house: String = ""
    @State private var apartment: String = ""
    @State private var terrainType: String = "город"
    
    @State private var docType: String = "14. Паспорт гражданина Российской Федерации"
    @State private var docSeries: String = ""
    @State private var docNumber: String = ""
    @State private var snils: String = ""
    
    @State private var socStatus: String = "Работает"
    @State private var workplace: String = ""
    @State private var jobPosition: String = ""
    
    @State private var mobilePhone: String = ""
    @State private var homePhone: String = ""
    @State private var workPhone: String = ""
    
    // Вкладка 2: Дополнительно (Полис и инвалидность)
    @State private var policyStatus: String = "Действует"
    @State private var cmoName: String = ""
    @State private var cmoAddress: String = ""
    @State private var cmoOGRN: String = ""
    @State private var policySeries: String = ""
    @State private var policyNumber: String = ""
    @State private var disabilityGroup: String = ""
    @State private var disabilityDegree: String = ""
    @State private var isInvalidFromChildhood: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок окна
            HStack {
                Text("Редактирование данных пациента")
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
            
            // Сегментированный переключатель вкладок
            Picker("", selection: $selectedTab) {
                Text("1. Пациент").tag(0)
                Text("2. Дополнительно").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            // Основной контент формы
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
                        // Блок данных полиса
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
                        
                        // Блок инвалидности
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
            
            // Нижняя панель с кнопками
            HStack {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Сохранить") {
                    savePatientData()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(14)
            .background(Color(red: 0.90, green: 0.90, blue: 0.90))
        }
        .frame(width: 820, height: 600)
        .onAppear {
            loadPatientData()
        }
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
    
    private func loadPatientData() {
        let parts = patient.fullName.components(separatedBy: " ")
        lastName = parts.indices.contains(0) ? parts[0] : ""
        firstName = parts.indices.contains(1) ? parts[1] : ""
        patronymic = parts.indices.contains(2) ? parts[2] : ""
        
        gender = patient.gender.contains("Жен") ? "2. Женский" : "1. Мужской"
        if let bDate = patient.birthDate { birthDate = bDate }
        snils = patient.snils
        mobilePhone = patient.phone
        socStatus = patient.status.isEmpty ? "Работает" : patient.status
        workplace = patient.workPlace
        jobPosition = patient.occupation
        street = patient.address
        
        // Загрузка дополнительных полей
        maritalStatus = patient.maritalStatus.isEmpty ? "Состоит в зарегистрированном браке" : patient.maritalStatus
        policyStatus = patient.policyStatus
        cmoName = patient.cmoName
        cmoAddress = patient.cmoAddress
        cmoOGRN = patient.cmoOGRN
        policySeries = patient.policySeries
        policyNumber = patient.policyNumber
        disabilityGroup = patient.disabilityGroup
        disabilityDegree = patient.disabilityDegree
        isInvalidFromChildhood = patient.isInvalidFromChildhood
        
        region = patient.region
        district = patient.district
        locality = patient.locality
        docType = patient.docType.isEmpty ? docType : patient.docType
        docSeries = patient.docSeries
        docNumber = patient.docNumber
    }
    
    private func savePatientData() {
        let f = lastName.trimmingCharacters(in: .whitespaces)
        let i = firstName.trimmingCharacters(in: .whitespaces)
        let o = patronymic.trimmingCharacters(in: .whitespaces)
        patient.fullName = [f, i, o].filter { !$0.isEmpty }.joined(separator: " ")
        patient.gender = gender.contains("Жен") ? "Женский" : "Мужской"
        patient.birthDate = birthDate
        patient.snils = snils
        patient.phone = mobilePhone
        patient.status = socStatus
        patient.workPlace = workplace
        patient.occupation = jobPosition
        
        let fullAddress = [
            !region.isEmpty ? region : nil,
            !district.isEmpty ? district : nil,
            !locality.isEmpty ? locality : nil,
            !street.isEmpty ? street : nil,
            !house.isEmpty ? "д. \(house)" : nil,
            !apartment.isEmpty ? "кв. \(apartment)" : nil
        ].compactMap { $0 }.joined(separator: ", ")
        
        patient.address = fullAddress.isEmpty ? street : fullAddress
        
        // Сохранение дополнительных полей
        patient.maritalStatus = maritalStatus
        patient.policyStatus = policyStatus
        patient.cmoName = cmoName
        patient.cmoAddress = cmoAddress
        patient.cmoOGRN = cmoOGRN
        patient.policySeries = policySeries
        patient.policyNumber = policyNumber
        patient.disabilityGroup = disabilityGroup
        patient.disabilityDegree = disabilityDegree
        patient.isInvalidFromChildhood = isInvalidFromChildhood
        
        patient.region = region
        patient.district = district
        patient.locality = locality
        patient.docType = docType
        patient.docSeries = docSeries
        patient.docNumber = docNumber
        
        try? modelContext.save()
        dismiss()
    }
}

// Алиас для обратной совместимости, если где-то используется FullPatientEditView
typealias FullPatientEditView = EditPatientView
