//
//  AdminAttributesView.swift
//  ФАП
//
//  Created by Sergey Kowalew on 18.08.2026.
//

import SwiftUI

struct AdminAttributesView: View {
    @State private var attributes = VisitAttributesManager.shared
    @State private var selectedCategory: AttributeCategory = .departments
    
    @State private var newItemText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum AttributeCategory: String, CaseIterable, Identifiable {
        case departments = "Отделение"
        case visitTypes = "Вид обращения"
        case locations = "Место"
        case visitKinds = "Прием"
        case visitGoals = "Цель посещения"
        case medHelpTypes = "Вид мед. помощи"
        case medications = "Медикаменты"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Левая панель выбора категории
            VStack(alignment: .leading, spacing: 0) {
                Text("Категории атрибутов")
                    .font(.headline)
                    .padding()
                
                Divider()
                
                List {
                    ForEach(AttributeCategory.allCases) { cat in
                        Button(action: {
                            selectedCategory = cat
                        }) {
                            Text(cat.rawValue)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(selectedCategory == cat ? Color.accentColor.opacity(0.2) : Color.clear)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(width: 240)
            
            Divider()
            
            // Правая панель со списком значений и добавлением
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Редактирование: \(selectedCategory.rawValue)")
                        .font(.title2.bold())
                    Spacer()
                }
                
                // Добавление нового элемента
                HStack(spacing: 12) {
                    TextField(selectedCategory == .medications ? "Название медикамента и дозировка..." : "Новое значение...", text: $newItemText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: addItem) {
                        Label("Добавить", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                
                Divider()
                
                // Список текущих значений
                List {
                    ForEach(currentItems, id: \.self) { item in
                        HStack {
                            Text(item)
                            Spacer()
                            Button(role: .destructive, action: {
                                removeItem(item)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.inset)
            }
            .padding(24)
        }
    }
    
    private var currentItems: [String] {
        get {
            switch selectedCategory {
            case .departments: return attributes.departments
            case .visitTypes: return attributes.visitTypes
            case .locations: return attributes.locations
            case .visitKinds: return attributes.visitKinds
            case .visitGoals: return attributes.visitGoals
            case .medHelpTypes: return attributes.medHelpTypes
            case .medications: return attributes.medications
            }
        }
    }
    
    private func addItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        var list = currentItems
        if !list.contains(trimmed) {
            list.append(trimmed)
            saveList(list)
            newItemText = ""
        }
    }
    
    private func removeItem(_ item: String) {
        var list = currentItems
        list.removeAll { $0 == item }
        saveList(list)
    }
    
    private func saveList(_ list: [String]) {
        switch selectedCategory {
        case .departments: attributes.departments = list
        case .visitTypes: attributes.visitTypes = list
        case .locations: attributes.locations = list
        case .visitKinds: attributes.visitKinds = list
        case .visitGoals: attributes.visitGoals = list
        case .medHelpTypes: attributes.medHelpTypes = list
        case .medications: attributes.medications = list
        }
    }
}
