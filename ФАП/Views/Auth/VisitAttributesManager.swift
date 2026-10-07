//
//  VisitAttributesManager.swift
//  ФАП
//
//  Created by Sergey Kowalew on 18.08.2026.
//


import Foundation
import SwiftUI

@Observable
final class VisitAttributesManager {
    static let shared = VisitAttributesManager()
    
    // Ключи для UserDefaults
    private let kDepartments = "attr_departments"
    private let kVisitTypes = "attr_visitTypes"
    private let kLocations = "attr_locations"
    private let kVisitKinds = "attr_visitKinds"
    private let kVisitGoals = "attr_visitGoals"
    private let kMedHelpTypes = "attr_medHelpTypes"
    private let kMedications = "attr_medications" // Новая вкладка медикаментов
    
    var departments: [String] {
        get { UserDefaults.standard.stringArray(forKey: kDepartments) ?? ["Терапия 1", "ФАП Амбулатория", "Процедурный кабинет"] }
        set { UserDefaults.standard.set(newValue, forKey: kDepartments) }
    }
    
    var visitTypes: [String] {
        get { UserDefaults.standard.stringArray(forKey: kVisitTypes) ?? ["1. Заболевание", "2. Профилактический осмотр"] }
        set { UserDefaults.standard.set(newValue, forKey: kVisitTypes) }
    }
    
    var locations: [String] {
        get { UserDefaults.standard.stringArray(forKey: kLocations) ?? ["1. Поликлиника", "2. На дому"] }
        set { UserDefaults.standard.set(newValue, forKey: kLocations) }
    }
    
    var visitKinds: [String] {
        get { UserDefaults.standard.stringArray(forKey: kVisitKinds) ?? ["Первично", "Повторно"] }
        set { UserDefaults.standard.set(newValue, forKey: kVisitKinds) }
    }
    
    var visitGoals: [String] {
        get { UserDefaults.standard.stringArray(forKey: kVisitGoals) ?? ["1. Лечебно-диагностическая", "2. Профилактическая"] }
        set { UserDefaults.standard.set(newValue, forKey: kVisitGoals) }
    }
    
    var medHelpTypes: [String] {
        get { UserDefaults.standard.stringArray(forKey: kMedHelpTypes) ?? [
            "13. первичная специализированная медико-санитарная помощь",
            "15. первичная врачебная медико-санитарная помощь"
        ] }
        set { UserDefaults.standard.set(newValue, forKey: kMedHelpTypes) }
    }
    
    // Список медикаментов для справочника
    var medications: [String] {
        get { UserDefaults.standard.stringArray(forKey: kMedications) ?? [
            "Амоксициллин (500 мг)",
            "Парацетамол (500 мг)",
            "Ибупрофен (400 мг)",
            "Каптоприл (25 мг)",
            "Омепразол (20 мг)",
            "Амброксол (30 мг)",
            "Лоратадин (10 мг)"
        ] }
        set { UserDefaults.standard.set(newValue, forKey: kMedications) }
    }
}
