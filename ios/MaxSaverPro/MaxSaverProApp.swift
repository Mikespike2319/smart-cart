import SwiftUI

@main
struct SmartCartApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isAuthenticated {
                MainTabView()
                    .environmentObject(appState)
            } else {
                AuthenticationView()
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppState.Tab.search)
            
            ShoppingListsView()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }
                .tag(AppState.Tab.lists)
            
            DealsView()
                .tabItem {
                    Label("Deals", systemImage: "tag.fill")
                }
                .tag(AppState.Tab.deals)
            
            AnalyticsView()
                .tabItem {
                    Label("Savings", systemImage: "chart.bar.fill")
                }
                .tag(AppState.Tab.analytics)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppState.Tab.profile)
        }
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case search
        case shoppingList
        case deals
        case profile
    }
}

struct User: Codable {
    let id: Int
    let email: String
    let fullName: String
    let preferences: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case preferences
    }
} 