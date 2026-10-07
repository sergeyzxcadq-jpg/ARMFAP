import Foundation
import SwiftData

// MARK: - 1. Модель пользователя / медработника
@Model
final class AppUser {
    var id: UUID = UUID()
    var username: String = ""
    var passwordHash: String = ""
    var fullName: String = ""
    var position: String = ""
    var isAdmin: Bool = false
    var isDefaultAdmin: Bool = false

    init(username: String, passwordHash: String, fullName: String, position: String, isAdmin: Bool = false, isDefaultAdmin: Bool = false) {
        self.id = UUID()
        self.username = username
        self.passwordHash = passwordHash
        self.fullName = fullName
        self.position = position
        self.isAdmin = isAdmin
        self.isDefaultAdmin = isDefaultAdmin
    }
}

// MARK: - 2. Модели пациентов и амбулаторного приема
@Model
final class PatientRecord {
    var id: UUID = UUID()
    var fullName: String = ""
    var birthDate: Date = Date()
    var snils: String = ""
    var address: String = ""
    var phone: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \OutpatientVisit.patient)
    var visits: [OutpatientVisit]? = []

    init(fullName: String, birthDate: Date, snils: String, address: String, phone: String) {
        self.id = UUID()
        self.fullName = fullName
        self.birthDate = birthDate
        self.snils = snils
        self.address = address
        self.phone = phone
        self.visits = []
    }
}

@Model
final class OutpatientVisit {
    var id: UUID = UUID()
    var visitDate: Date = Date()
    var diagnosis: String = ""
    var complaints: String = ""
    var treatment: String = ""
    
    var patient: PatientRecord?

    init(visitDate: Date, diagnosis: String, complaints: String, treatment: String, patient: PatientRecord? = nil) {
        self.id = UUID()
        self.visitDate = visitDate
        self.diagnosis = diagnosis
        self.complaints = complaints
        self.treatment = treatment
        self.patient = patient
    }
}

// MARK: - 3. Модели вызовов СМП
@Model
final class SMPVisitModel {
    var id: UUID = UUID()
    var callDate: Date = Date()
    var patientName: String = ""
    var reason: String = ""
    var result: String = ""

    init(callDate: Date, patientName: String, reason: String, result: String) {
        self.id = UUID()
        self.callDate = callDate
        self.patientName = patientName
        self.reason = reason
        self.result = result
    }
}

// MARK: - 4. Модели прививок
@Model
final class VaccineSeries {
    var id: UUID = UUID()
    var vaccineName: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \VaccineDose.series)
    var doses: [VaccineDose]? = []

    init(vaccineName: String) {
        self.id = UUID()
        self.vaccineName = vaccineName
        self.doses = []
    }
}

@Model
final class VaccineDose {
    var id: UUID = UUID()
    var doseNumber: Int = 1
    var administrationDate: Date = Date()
    var batchNumber: String = ""
    
    var series: VaccineSeries?

    init(doseNumber: Int, administrationDate: Date, batchNumber: String, series: VaccineSeries? = nil) {
        self.id = UUID()
        self.doseNumber = doseNumber
        self.administrationDate = administrationDate
        self.batchNumber = batchNumber
        self.series = series
    }
}

// MARK: - 5. Справочник медикаментов для админки
@Model
final class AdminMedicationItem {
    var id: UUID = UUID()
    var name: String = ""
    var defaultDose: String = ""

    init(name: String, defaultDose: String) {
        self.id = UUID()
        self.name = name
        self.defaultDose = defaultDose
    }
}
