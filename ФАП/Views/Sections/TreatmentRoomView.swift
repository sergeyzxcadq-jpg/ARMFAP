import SwiftUI

// Структура записи процедурного кабинета (в памяти)
struct ProcedureRecord: Identifiable {
    let id = UUID()
    var number: Int
    var patientName: String
    var age: String
    var procedureName: String
    var administrationRoute: String
    var recordDate: Date
    var daysMarks: [Int: String] = [:]
}

struct TreatmentRoomView: View {
    @State private var selectedDate: Date = Date()
    @State private var showingAddSheet = false
    
    @State private var records: [ProcedureRecord] = [
        ProcedureRecord(
            number: 1,
            patientName: "Иванов Иван Иванович",
            age: "45",
            procedureName: "Цефтриаксон 1г №10",
            administrationRoute: "В/м",
            recordDate: Date(),
            daysMarks: [1: "+", 2: "+", 3: "+"]
        ),
        ProcedureRecord(
            number: 2,
            patientName: "Петрова Анна Сергеевна",
            age: "62",
            procedureName: "Актовегин 5 мл на физ. растворе",
            administrationRoute: "В/в капельно",
            recordDate: Date(),
            daysMarks: [1: "+", 2: "+"]
        )
    ]

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left") }
                .buttonStyle(.bordered)

                Text(monthYearFormatter.string(from: selectedDate).capitalized)
                    .font(.headline).frame(width: 200, alignment: .center)

                Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right") }
                .buttonStyle(.bordered)

                Spacer()

                Button(action: { showingAddSheet = true }) { Label("Добавить процедуру", systemImage: "plus") }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            #if os(iOS)
            .background(Color(.systemBackground))
            #else
            .background(Color(.windowBackgroundColor))
            #endif

            Divider()

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        HeaderCell(title: "№", width: 50)
                        HeaderCell(title: "Ф.И.О. пациента", width: 220)
                        HeaderCell(title: "Возраст", width: 70)
                        HeaderCell(title: "Наименование процедуры\n(препарат, доза, кол-во)", width: 300)
                        HeaderCell(title: "Способ введения", width: 140)
                        
                        ForEach(1...numberOfDaysInCurrentMonth(), id: \.self) { day in
                            HeaderCell(title: "\(day)", width: 36)
                        }
                    }
                    .background(Color.accentColor)

                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach($records) { $record in
                                if isSameMonth(record.recordDate, selectedDate) {
                                    HStack(spacing: 0) {
                                        DataCell(text: "\(record.number)", width: 50)
                                        DataCell(text: record.patientName, width: 220, alignment: .leading)
                                        DataCell(text: record.age, width: 70)
                                        DataCell(text: record.procedureName, width: 300, alignment: .leading)
                                        DataCell(text: record.administrationRoute, width: 140)

                                        ForEach(1...numberOfDaysInCurrentMonth(), id: \.self) { day in
                                            ZStack {
                                                Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                                    #if os(iOS)
                                                    .background(Color(.systemBackground))
                                                    #else
                                                    .background(Color(.windowBackgroundColor))
                                                    #endif
                                                
                                                Text(record.daysMarks[day] ?? "")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.accentColor)
                                            }
                                            .frame(width: 36, height: 40)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                record.daysMarks[day] = record.daysMarks[day] == "+" ? nil : "+"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Журнал процедур")
        .sheet(isPresented: $showingAddSheet) {
            AddProcedureRecordView { newRec in
                var recordToAdd = newRec
                recordToAdd.recordDate = selectedDate
                let count = records.filter { isSameMonth($0.recordDate, selectedDate) }.count
                recordToAdd.number = count + 1
                records.append(recordToAdd)
            }
        }
    }

    private func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, equalTo: date2, toGranularity: .month)
    }

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func numberOfDaysInCurrentMonth() -> Int {
        return Calendar.current.range(of: .day, in: .month, for: selectedDate)?.count ?? 31
    }
}

struct HeaderCell: View {
    let title: String
    let width: CGFloat
    var body: some View {
        Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            .multilineTextAlignment(.center).padding(.horizontal, 2)
            .frame(width: width, height: 50).border(Color.white.opacity(0.2), width: 0.5)
    }
}

struct DataCell: View {
    let text: String
    let width: CGFloat
    var alignment: Alignment = .center
    var body: some View {
        Text(text).font(.system(size: 12)).padding(.horizontal, 4)
            .frame(width: width, height: 40, alignment: alignment)
            .border(Color.gray.opacity(0.3), width: 0.5).lineLimit(2)
    }
}

struct AddProcedureRecordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var patientName = ""
    @State private var age = ""
    @State private var procedureName = ""
    @State private var administrationRoute = "В/м"
    var onSave: (ProcedureRecord) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Данные пациента") {
                    TextField("Ф.И.О. пациента", text: $patientName)
                    TextField("Возраст", text: $age)
                }
                Section("Назначение процедуры") {
                    TextField("Наименование", text: $procedureName)
                    Picker("Способ", selection: $administrationRoute) {
                        Text("В/м").tag("В/м"); Text("В/в").tag("В/в"); Text("В/в кап.").tag("В/в капельно")
                        Text("П/к").tag("П/к"); Text("Per os").tag("Per os")
                    }
                }
            }
            .navigationTitle("Новое назначение")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave(ProcedureRecord(number: 0, patientName: patientName, age: age, procedureName: procedureName, administrationRoute: administrationRoute, recordDate: Date()))
                        dismiss()
                    }.disabled(patientName.isEmpty || procedureName.isEmpty)
                }
            }
        }
    }
}
