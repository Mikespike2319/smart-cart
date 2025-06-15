import SwiftUI

@main
struct MaxSaverProApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
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