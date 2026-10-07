import SwiftUI
import SwiftData

@main
struct FAPApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppUser.self,
            PatientRecord.self,
            VaccineSeries.self,
            VaccineDose.self,
            OutpatientVisit.self,
            AdminMedicationItem.self,
            SMPVisitModel.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Ошибка инициализации облачного хранилища: \(error)")
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Не удалось создать ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
