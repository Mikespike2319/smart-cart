import SwiftUI

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var selectedTab = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Authentication
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await NetworkManager.shared.signIn(email: email, password: password)
            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await NetworkManager.shared.signUp(email: email, password: password, name: name)
            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }
} 