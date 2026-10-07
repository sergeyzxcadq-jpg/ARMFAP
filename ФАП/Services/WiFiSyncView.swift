//
//  WiFiSyncView.swift
//  ФАП
//
//  Created by Sergey Kowalew on 13.08.2026.
//

import Network
import SwiftUI
import SwiftData

struct WiFiSyncView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var patients: [PatientRecord]
    @Query private var visits: [OutpatientVisit]
    @Query private var users: [AppUser]
    
    @State private var syncService = WiFiSyncService()
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Заголовок
            HStack {
                Image(systemName: "wifi.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Беспроводная синхронизация")
                        .font(.title2.bold())
                    Text("Передача данных по локальной сети Wi-Fi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    syncService.stopAll()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Статус
            HStack {
                Circle()
                    .fill(syncService.isServerRunning ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text(syncService.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Список найденных устройств в сети
            VStack(alignment: .leading, spacing: 8) {
                Text("Устройства в сети Wi-Fi:").font(.headline)
                
                if syncService.connectedDevices.isEmpty {
                    VStack {
                        Spacer()
                        Text("Поиск устройств...")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        ProgressView().padding(.top, 4)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                } else {
                    List(syncService.connectedDevices, id: \.hashValue) { endpoint in
                        HStack {
                            Image(systemName: "ipad.and.iphone")
                                .foregroundColor(.blue)
                            
                            if case .service(let name, _, _, _) = endpoint {
                                Text(name).font(.subheadline.bold())
                            } else {
                                Text("Устройство ФАП").font(.subheadline.bold())
                            }
                            
                            Spacer()
                            
                            Button("Отправить базу") {
                                sendDatabase(to: endpoint)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(height: 140)
                    .cornerRadius(8)
                }
            }
            
            HStack {
                Button("Перезапустить поиск") {
                    syncService.startBrowsing()
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding(24)
        .frame(width: 480, height: 380)
        .onAppear {
            syncService.startServer { receivedData in
                importDatabase(data: receivedData)
            }
            syncService.startBrowsing()
        }
        .alert("Синхронизация", isPresented: $showAlert) {
            Button("ОК", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func sendDatabase(to endpoint: NWEndpoint) {
        let exportPackage = SyncPackage(
            patients: patients.map { PatientDTO(from: $0) },
            visits: visits.map { VisitDTO(from: $0) }
        )
        
        guard let data = try? JSONEncoder().encode(exportPackage) else {
            alertMessage = "Ошибка подготовки данных"
            showAlert = true
            return
        }
        
        syncService.sendData(data, to: endpoint) { success in
            if success {
                alertMessage = "База данных успешно отправлена!"
                showAlert = true
            }
        }
    }
    
    private func importDatabase(data: Data) {
        guard let package = try? JSONDecoder().decode(SyncPackage.self, from: data) else {
            alertMessage = "Ошибка чтения полученного пакета"
            showAlert = true
            return
        }
        
        var importedPatients = 0
        for pDTO in package.patients {
            if !patients.contains(where: { $0.fullName == pDTO.fullName && $0.cardNumber == pDTO.cardNumber }) {
                let newP = PatientRecord(fullName: pDTO.fullName, birthDate: pDTO.birthDate)
                newP.cardNumber = pDTO.cardNumber
                newP.address = pDTO.address
                newP.phone = pDTO.phone
                modelContext.insert(newP)
                importedPatients += 1
            }
        }
        
        var importedVisits = 0
        for vDTO in package.visits {
            let newV = OutpatientVisit(
                visitDate: vDTO.visitDate,
                complaintsAndDiagnosis: vDTO.complaintsAndDiagnosis,
                patient: nil,
                patientName: vDTO.patientName,
                patientGender: vDTO.patientGender,
                patientBirthDate: vDTO.patientBirthDate,
                patientAddress: vDTO.patientAddress
            )
            modelContext.insert(newV)
            importedVisits += 1
        }
        
        try? modelContext.save()
        alertMessage = "Успешно импортировано:\nЖителей: \(importedPatients)\nПриёмов: \(importedVisits)"
        showAlert = true
    }
}

// MARK: - Пакеты передачи данных (DTO)

struct SyncPackage: Codable {
    var patients: [PatientDTO]
    var visits: [VisitDTO]
}

struct PatientDTO: Codable {
    var cardNumber: String
    var fullName: String
    var birthDate: Date?
    var address: String
    var phone: String
    
    init(from p: PatientRecord) {
        self.cardNumber = p.cardNumber
        self.fullName = p.fullName
        self.birthDate = p.birthDate
        self.address = p.address
        self.phone = p.phone
    }
}

struct VisitDTO: Codable {
    var visitDate: Date
    var patientName: String
    var patientGender: String
    var patientBirthDate: Date?
    var patientAddress: String
    var complaintsAndDiagnosis: String
    
    init(from v: OutpatientVisit) {
        self.visitDate = v.visitDate
        self.patientName = v.patientName
        self.patientGender = v.patientGender
        self.patientBirthDate = v.patientBirthDate
        self.patientAddress = v.patientAddress
        self.complaintsAndDiagnosis = v.complaintsAndDiagnosis
    }
}
