import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    private var appearanceMode: AppearanceMode {
        userProfiles.first?.appearanceMode ?? .auto
    }

    var body: some View {
        Group {
            if userProfiles.isEmpty {
                OnboardingFlow()
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            ProgressView_Custom()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, EquipmentProfile.self], inMemory: true)
}
