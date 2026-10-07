//
//  TherapistExamView.swift
//  ФАП
//
//  Created by Sergey Kowalew on 14.08.2026.
//


import SwiftUI

struct TherapistExamView: View {
    // Данные, принимаемые из карточки приёма
    var visitDate: Date
    var doctorName: String = "Ковалёв Сергей Львович"
    var initialDiagnosis: String
    var onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // Поля ввода для заполнения (где были подчеркивания "_")
    @State private var temperature: String = "36.6"
    @State private var spO2: String = "98"
    @State private var complaintsText: String = ""
    @State private var anamnesisText: String = ""
    
    @State private var skinField: String = "обычные"
    @State private var lymphNodesField: String = "не пальпируются"
    @State private var jointsField: String = "не изменены"
    @State private var zevField: String = "чистый, гиперемированный"
    @State private var tonsilsField: String = "обычные"
    @State private var respRate: String = "16"
    @State private var lungPercussionField: String = ""
    @State private var heartTonesField: String = "чистые, ясные"
    @State private var bpSystolic: String = "120"
    @State private var bpDiastolic: String = "80"
    @State private var pulseRate: String = "75"
    @State private var liverSize: String = ""
    @State private var enthesitisArea: String = ""
    @State private var anuriaField: String = "нет"
    @State private var kidneysField: String = "нет, безболезненны"
    @State private var micturitionField: String = "нормальное, безболезненное"
    @State private var otherOrgans: String = "нет особенностей"
    
    @State private var diagnosticPlan: String = ""
    @State private var treatmentPlan: String = ""
    @State private var sickLeaveNumber: String = ""
    @State private var sickLeaveFrom: String = ""
    @State private var sickLeaveTo: String = ""
    @State private var returnDateDay: String = ""
    @State private var returnDateMonth: String = ""
    @State private var returnDateYear: String = "2026"
    
    @State private var diagnosisField: String = ""
    
    // Интерактивное форматирование текста (клик для изменения стиля)
    @State private var toggledStyles: [String: ExamStyle] = [:]
    
    enum ExamStyle {
        case normal, italic, underline, boldItalic
        
        mutating func toggle() {
            switch self {
            case .normal: self = .italic
            case .italic: self = .underline
            case .underline: self = .boldItalic
            case .boldItalic: self = .normal
            }
        }
        
        func apply(to text: String) -> Text {
            let base = Text(text)
            switch self {
            case .normal: return base
            case .italic: return base.italic()
            case .underline: return base.underline()
            case .boldItalic: return base.bold().italic()
            }
        }
    }
    
    private func clickableText(_ key: String, defaultText: String) -> some View {
        let style = toggledStyles[key] ?? .normal
        return style.apply(to: defaultText)
            .foregroundColor(style == .normal ? .primary : .blue)
            .contentShape(Rectangle())
            .onTapGesture {
                var current = toggledStyles[key] ?? .normal
                current.toggle()
                toggledStyles[key] = current
            }
            .help("Нажмите, чтобы изменить стиль (обычный -> курсив -> подчеркнутый)")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Верхняя панель
            HStack {
                Text("Осмотр терапевта (Электронная медицинская карта)")
                    .font(.headline.bold())
                Spacer()
                Button(action: { dismiss() }) { Image(systemName: "xmark") }
                    .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Основной документ осмотра
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    
                    // Шапка
                    HStack {
                        Text("ОСМОТР ТЕРАПЕВТА")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.bottom, 6)
                    
                    HStack {
                        Text("Дата: **\(formattedDate(visitDate))**")
                        Spacer()
                        HStack(spacing: 4) {
                            Text("t -")
                            TextField("36.6", text: $temperature)
                                .frame(width: 45)
                                .textFieldStyle(.roundedBorder)
                            Text("°")
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text("SpO2 -")
                            TextField("98", text: $spO2)
                                .frame(width: 45)
                                .textFieldStyle(.roundedBorder)
                            Text("%")
                        }
                    }
                    .font(.subheadline)
                    
                    Divider()
                    
                    // Жалобы
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Жалобы:").font(.subheadline.bold())
                        TextEditor(text: $complaintsText)
                            .frame(height: 70)
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    
                    // Анамнез
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Анамнез:").font(.subheadline.bold())
                        TextEditor(text: $anamnesisText)
                            .frame(height: 70)
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    
                    Divider()
                    
                    // Объективный статус с интерактивными кликабельными стилями
                    Group {
                        HStack(alignment: .top, spacing: 6) {
                            clickableText("skin_lbl", defaultText: "Кожные покровы:")
                            TextField("обычные", text: $skinField)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            clickableText("lymph_lbl", defaultText: "Лимфатические узлы:")
                            TextField("не пальпируются", text: $lymphNodesField)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            clickableText("joints_lbl", defaultText: "Суставы:")
                            TextField("не изменены", text: $jointsField)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            clickableText("zev_lbl", defaultText: "Зев:")
                            TextField("чистый, гиперемированный", text: $zevField)
                                .textFieldStyle(.roundedBorder)
                            clickableText("tonsils_lbl", defaultText: "Миндалины:")
                            TextField("обычные", text: $tonsilsField)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            clickableText("resp_lbl", defaultText: "Число дыханий")
                            TextField("16", text: $respRate)
                                .frame(width: 50)
                                .textFieldStyle(.roundedBorder)
                            clickableText("resp_desc", defaultText: "в мин. В легких: дыхание везикулярное, хрипы: нет.")
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            clickableText("heart_lbl", defaultText: "Тоны сердца:")
                            TextField("чистые, ясные", text: $heartTonesField)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                clickableText("ad_lbl", defaultText: "АД")
                                TextField("120", text: $bpSystolic).frame(width: 50).textFieldStyle(.roundedBorder)
                                Text("/")
                                TextField("80", text: $bpDiastolic).frame(width: 50).textFieldStyle(.roundedBorder)
                                Text("мм рт. ст.")
                            }
                            HStack(spacing: 4) {
                                clickableText("pulse_lbl", defaultText: "Пульс")
                                TextField("75", text: $pulseRate).frame(width: 50).textFieldStyle(.roundedBorder)
                                Text("уд./мин.")
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            clickableText("belly_lbl", defaultText: "Живот:")
                            Text("мягкий, безболезненный при пальпации.")
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            clickableText("liver_lbl", defaultText: "Печень:")
                            TextField("не увеличена", text: $liverSize)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            clickableText("mict_lbl", defaultText: "Мочеиспускание:")
                            TextField("нормальное, безболезненное", text: $micturitionField)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .font(.subheadline)
                    
                    Divider()
                    
                    // Диагноз (Автоподстановка из приема)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Диагноз:").font(.subheadline.bold())
                        TextField("Диагноз", text: $diagnosisField)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline.bold())
                    }
                    
                    // Обследования
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Обследования:").font(.subheadline.bold())
                        TextEditor(text: $diagnosticPlan)
                            .frame(height: 70)
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    
                    // Лечение
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Лечение:").font(.subheadline.bold())
                        TextEditor(text: $treatmentPlan)
                            .frame(height: 80)
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    
                    // Больничный лист и явка
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("Больничный лист №")
                            TextField("№", text: $sickLeaveNumber).frame(width: 90).textFieldStyle(.roundedBorder)
                            Text("с")
                            TextField("дд.мм.гггг", text: $sickLeaveFrom).frame(width: 100).textFieldStyle(.roundedBorder)
                            Text("по")
                            TextField("дд.мм.гггг", text: $sickLeaveTo).frame(width: 100).textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(spacing: 8) {
                            Text("Явка: «")
                            TextField("01", text: $returnDateDay).frame(width: 40).textFieldStyle(.roundedBorder)
                            Text("»")
                            TextField("месяц", text: $returnDateMonth).frame(width: 90).textFieldStyle(.roundedBorder)
                            TextField("2026", text: $returnDateYear).frame(width: 60).textFieldStyle(.roundedBorder)
                            Text("г.")
                        }
                    }
                    .font(.subheadline)
                    
                    Divider()
                    
                    // Подпись врача (автоматически)
                    HStack {
                        Text("Врач: **\(doctorName)**")
                        Spacer()
                        Text("Дата: **\(formattedDate(visitDate))**")
                    }
                    .font(.subheadline)
                    
                }
                .padding(16)
            }
            
            Divider()
            
            // Нижняя панель действий
            HStack {
                Button("Отмена") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Сохранить и закрыть осмотр") {
                    let fullExamResult = "Диагноз: \(diagnosisField)\nЖалобы: \(complaintsText)\nЛечение: \(treatmentPlan)"
                    onSave(fullExamResult)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
        }
        .frame(width: 760, height: 800)
        .onAppear {
            // Автоматически заполняем диагноз из переданного значения приёма
            self.diagnosisField = initialDiagnosis
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: date)
    }
}