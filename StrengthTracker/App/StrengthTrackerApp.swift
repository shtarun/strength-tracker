import SwiftUI
import SwiftData

@main
struct StrengthTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                UserProfile.self,
                EquipmentProfile.self,
                Exercise.self,
                ExerciseTemplate.self,
                WorkoutTemplate.self,
                WorkoutSession.self,
                WorkoutSet.self,
                PainFlag.self
            ])
            
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // Schema migration failed - delete existing store and try again
                print("⚠️ Schema migration failed: \(error). Recreating database...")
                
                // Delete ALL SwiftData stores in Application Support
                let fileManager = FileManager.default
                let appSupportURL = URL.applicationSupportDirectory
                
                if let contents = try? fileManager.contentsOfDirectory(at: appSupportURL, includingPropertiesForKeys: nil) {
                    for url in contents {
                        if url.lastPathComponent.contains("store") || url.lastPathComponent.contains("Store") {
                            try? fileManager.removeItem(at: url)
                            print("🗑️ Deleted: \(url.lastPathComponent)")
                        }
                    }
                }
                
                // Also try the specific default.store paths
                let defaultStorePaths = [
                    appSupportURL.appending(path: "default.store"),
                    appSupportURL.appending(path: "default.store-shm"),
                    appSupportURL.appending(path: "default.store-wal")
                ]
                
                for url in defaultStorePaths {
                    try? fileManager.removeItem(at: url)
                }
                
                // Try again with fresh store
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ Successfully recreated database")
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    seedDataIfNeeded()
                }
        }
        .modelContainer(modelContainer)
    }
    
    @MainActor
    private func seedDataIfNeeded() {
        let context = modelContainer.mainContext
        
        // Always ensure exercises are seeded
        ExerciseLibrary.shared.seedExercises(in: context)
        
        // Check if user has profile but empty templates (due to previous race condition)
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let templateDescriptor = FetchDescriptor<WorkoutTemplate>()
        
        guard let profiles = try? context.fetch(profileDescriptor),
              let profile = profiles.first,
              let equipment = profile.equipmentProfile else {
            return
        }
        
        // Configure LLMService with stored API keys on app launch
        LLMService.shared.configure(
            claudeAPIKey: profile.claudeAPIKey,
            openAIAPIKey: profile.openAIAPIKey
        )
        
        let templates = (try? context.fetch(templateDescriptor)) ?? []
        
        // If user exists but has no templates, regenerate them
        if templates.isEmpty {
            TemplateGenerator.generateDefaultTemplates(
                for: profile,
                equipment: equipment,
                in: context
            )
        }
        
        // Check if existing templates have no exercises (another symptom of the race condition)
        let emptyTemplates = templates.filter { $0.exercises.isEmpty }
        if !emptyTemplates.isEmpty {
            // Delete empty templates
            for template in emptyTemplates {
                context.delete(template)
            }
            
            // Regenerate all templates
            TemplateGenerator.generateDefaultTemplates(
                for: profile,
                equipment: equipment,
                in: context
            )
        }
        
        try? context.save()
    }
}
