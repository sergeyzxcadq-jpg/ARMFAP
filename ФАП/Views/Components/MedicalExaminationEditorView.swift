import SwiftUI

struct MedicalExaminationEditorView: View {
    @Binding var examinationText: String
    var onComplete: () -> Void
    
    // Замыкание для передачи витальных параметров наружу
    var onSaveVitals: ((String, String, String, String, String, String, String, String, String) -> Void)? = nil
    
    @State private var selectedTab: ExamTab = .complaints
    @State private var isGenerated = false
    
    // Поля вкладки 1: Жалобы и анамнез
    @State private var complaints: String = ""
    @State private var diseaseHistory: String = ""
    @State private var venDiseaseHistory: String = "отрицает"
    @State private var bloodTransfusionHistory: String = "не переливалась"
    @State private var surgeryHistory: String = "не было"
    @State private var drugTolerance: String = "не отмечает"
    
    // Поля вкладки 2: Настоящее состояние
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var bmi: String = ""
    @State private var temperature: String = ""
    
    @State private var generalCondition: String = "удовлетворительное"
    @State private var constitution: String = "нормостеническое"
    @State private var lymphNodes: String = ""
    @State private var skinColor: String = "чистые"
    @State private var skinTone: String = "обычной окраски"
    @State private var mucousMembranes: String = "розовые"
    
    @State private var breathingType: String = "везикулярное"
    @State private var breathingSymmetry: String = "симметричное"
    @State private var rales: String = "хрипов нет"
    @State private var saturation: String = ""
    
    @State private var heartSounds: String = "ясные"
    @State private var heartRhythm: String = "ритмичные"
    @State private var heartRate: String = ""
    @State private var pulseRate: String = ""
    @State private var pulseRhythm: String = "ритмичный"
    @State private var pulseProperties: String = "удовлетворительных свойств"
    
    @State private var bpSystolic: String = "120"
    @State private var bpDiastolic: String = "80"
    
    @State private var tongueState1: String = "чистый"
    @State private var tongueState2: String = "влажный"
    @State private var abdomen1: String = "не вздут"
    @State private var abdomen2: String = "мягкий"
    @State private var abdomenPain: String = "безболезненный"
    @State private var peritonealSigns: String = "нет"
    
    @State private var liverEdge: String = "по краю реберной дуги"
    @State private var liverConsistence: String = "плотно-эластической консистенции"
    @State private var liverPain: String = "безболезненный"
    
    @State private var pasternatskySign: String = "отрицательный с обеих сторон"
    @State private var stool: String = "регулярный"
    @State private var urination: String = "свободное"
    
    // Поля вкладки 3: Локальный статус
    @State private var localStatusText: String = "Без особенностей."

    enum ExamTab: String, CaseIterable {
        case complaints = "Жалобы и анамнез"
        case presentState = "Настоящее состояние"
        case localStatus = "Локальный статус"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(ExamTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.system(size: 13))
                            .fontWeight(selectedTab == tab ? .bold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? Color.white : Color(red: 0.92, green: 0.92, blue: 0.92))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .background(Color(red: 0.88, green: 0.88, blue: 0.88))

            ZStack {
                Color(red: 0.95, green: 0.95, blue: 0.95).ignoresSafeArea()
                
                if isGenerated {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Сгенерированный протокол осмотра:")
                                .font(.headline)
                            Spacer()
                            Button("Вернуться к шаблону") {
                                isGenerated = false
                            }
                            .font(.subheadline)
                            .buttonStyle(.bordered)
                        }
                        
                        TextEditor(text: $examinationText)
                            .font(.system(size: 14))
                            .padding(8)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                    }
                    .padding(16)
                    
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            switch selectedTab {
                            case .complaints:
                                complaintsTabView
                            case .presentState:
                                presentStateTabView
                            case .localStatus:
                                localStatusTabView
                            }
                        }
                        .padding(16)
                    }
                }
            }
            
            Divider()
            
            HStack {
                if !isGenerated {
                    if selectedTab == .presentState {
                        Button("<< Назад") { selectedTab = .complaints }
                            .buttonStyle(.bordered)
                    } else if selectedTab == .localStatus {
                        Button("<< Назад") { selectedTab = .presentState }
                            .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if selectedTab != .localStatus {
                        Button("Далее >>") {
                            if selectedTab == .complaints { selectedTab = .presentState }
                            else if selectedTab == .presentState { selectedTab = .localStatus }
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button(action: generateExaminationProtocol) {
                            Label("Сгенерировать осмотр", systemImage: "sparkles")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Spacer()
                    Button("Готово") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(12)
            .background(Color(red: 0.92, green: 0.92, blue: 0.92))
        }
    }

    private var complaintsTabView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Жалобы").bold()
            TextEditor(text: $complaints)
                .frame(height: 70)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.4), lineWidth: 1))
            
            Text("Анамнез заболевания").bold()
            TextEditor(text: $diseaseHistory)
                .frame(height: 70)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.4), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Анамнез жизни").bold().padding(.top, 4)
                Group {
                    Text("Вен. заболевания, туберкулез, желтуха").font(.caption).foregroundColor(.secondary)
                    TextField("", text: $venDiseaseHistory).textFieldStyle(.roundedBorder)
                    Text("Переливание крови").font(.caption).foregroundColor(.secondary)
                    TextField("", text: $bloodTransfusionHistory).textFieldStyle(.roundedBorder)
                    Text("Травмы, операции").font(.caption).foregroundColor(.secondary)
                    TextField("", text: $surgeryHistory).textFieldStyle(.roundedBorder)
                    Text("Лекарственная непереносимость").font(.caption).foregroundColor(.secondary)
                    TextField("", text: $drugTolerance).textFieldStyle(.roundedBorder)
                }
            }
            .padding(12).background(Color.white).cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        }
    }

    private var presentStateTabView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                HStack { Text("Рост"); TextField("", text: $height).frame(width: 50).textFieldStyle(.roundedBorder); Text("см") }
                HStack { Text("Вес"); TextField("", text: $weight).frame(width: 50).textFieldStyle(.roundedBorder); Text("кг") }
                HStack { Text("Индекс массы тела"); TextField("", text: $bmi).frame(width: 50).textFieldStyle(.roundedBorder) }
                HStack { Text("Температура тела"); TextField("", text: $temperature).frame(width: 50).textFieldStyle(.roundedBorder); Text("°C") }
            }
            .font(.system(size: 13))
            
            HStack(spacing: 16) {
                HStack { Text("Общее состояние"); TextField("", text: $generalCondition).textFieldStyle(.roundedBorder) }
                HStack { Text("Телосложение"); TextField("", text: $constitution).textFieldStyle(.roundedBorder) }
            }
            
            HStack {
                Text("Периферические лимфоузлы")
                TextField("", text: $lymphNodes).textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 8) {
                Text("Кожные покровы")
                TextField("", text: $skinColor).textFieldStyle(.roundedBorder)
                TextField("", text: $skinTone).textFieldStyle(.roundedBorder)
                Text("Видимые слизистые")
                TextField("", text: $mucousMembranes).textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 8) {
                Text("Дыхание")
                TextField("", text: $breathingType).textFieldStyle(.roundedBorder)
                TextField("", text: $breathingSymmetry).textFieldStyle(.roundedBorder)
                TextField("", text: $rales).textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 16) {
                HStack { Text("Сатурация"); TextField("", text: $saturation).frame(width: 60).textFieldStyle(.roundedBorder); Text("%") }
                HStack { Text("Тоны сердца"); TextField("", text: $heartSounds).textFieldStyle(.roundedBorder); TextField("", text: $heartRhythm).textFieldStyle(.roundedBorder) }
            }
            
            HStack(spacing: 8) {
                HStack { Text("ЧСС"); TextField("", text: $heartRate).frame(width: 50).textFieldStyle(.roundedBorder); Text("уд. в мин") }
                HStack { Text("Пульс"); TextField("", text: $pulseRate).frame(width: 50).textFieldStyle(.roundedBorder); Text("уд. в мин") }
                TextField("", text: $pulseRhythm).textFieldStyle(.roundedBorder)
                TextField("", text: $pulseProperties).textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("АД")
                TextField("120", text: $bpSystolic).frame(width: 50).textFieldStyle(.roundedBorder)
                Text("/")
                TextField("80", text: $bpDiastolic).frame(width: 50).textFieldStyle(.roundedBorder)
                Text("мм. рт. ст.")
            }
            
            HStack(spacing: 8) {
                Text("Язык")
                TextField("", text: $tongueState1).textFieldStyle(.roundedBorder)
                TextField("", text: $tongueState2).textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 8) {
                Text("Живот")
                TextField("", text: $abdomen1).textFieldStyle(.roundedBorder)
                TextField("", text: $abdomen2).textFieldStyle(.roundedBorder)
                TextField("", text: $abdomenPain).textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 8) {
                Text("Симптомы раздражения брюшины")
                TextField("", text: $peritonealSigns).textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 8) {
                Text("Печень")
                TextField("", text: $liverEdge).textFieldStyle(.roundedBorder)
                Text("Край")
                TextField("", text: $liverConsistence).textFieldStyle(.roundedBorder)
                TextField("", text: $liverPain).textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Симптом Пастернацкого")
                TextField("", text: $pasternatskySign).textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 8) {
                Text("Стул"); TextField("", text: $stool).textFieldStyle(.roundedBorder)
                Text("Мочеиспускание"); TextField("", text: $urination).textFieldStyle(.roundedBorder)
            }
            .font(.system(size: 13))
        }
    }

    private var localStatusTabView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Локальный статус (Local status)").bold()
            TextEditor(text: $localStatusText)
                .frame(height: 150)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.4), lineWidth: 1))
        }
    }

    private func generateExaminationProtocol() {
        var text = ""
        text += "Жалобы на: \(complaints.isEmpty ? "нет" : complaints).\n\n"
        text += "Анамнез заболевания: \(diseaseHistory.isEmpty ? "со слов пациента..." : diseaseHistory).\n\n"
        text += "Анамнез жизни\n"
        text += "Венерические заболевания, туберкулез, желтуху \(venDiseaseHistory). Кровь \(bloodTransfusionHistory). Травм, операций \(surgeryHistory). Лекарственной непереносимости \(drugTolerance).\n\n"
        text += "Настоящее состояние\n"
        text += "Общее состояние \(generalCondition). Телосложение \(constitution). Кожные покровы \(skinColor), \(skinTone). Видимые слизистые \(mucousMembranes). В легких дыхание \(breathingType), \(breathingSymmetry), \(rales). Тоны сердца \(heartSounds), \(heartRhythm). ЧСС \(heartRate.isEmpty ? "72" : heartRate) уд. в мин. Пульс \(pulseRate.isEmpty ? "72" : pulseRate) уд. в мин, \(pulseRhythm), \(pulseProperties). Артериальное давление \(bpSystolic)/\(bpDiastolic) мм. рт. ст. Язык \(tongueState1), \(tongueState2). Живот \(abdomen1), \(abdomen2), \(abdomenPain). Симптомы раздражения брюшины \(peritonealSigns). Печень \(liverEdge). Край печени \(liverConsistence), \(liverPain). Симптом Пастернацкого \(pasternatskySign). Стул \(stool), оформленный. Мочеиспускание \(urination), безболезненное.\n\n"
        text += "Локальный статус: \(localStatusText)"
        
        examinationText = text
        
        // Передаем заполненные витальные параметры наружу
        onSaveVitals?(height, weight, "", temperature, bpSystolic, bpDiastolic, heartRate, pulseRate, saturation)
        
        isGenerated = true
    }
}
