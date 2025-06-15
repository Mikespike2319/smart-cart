import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    if let user = appState.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Preferences Section
                Section("Preferences") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    
                    NavigationLink(destination: StorePreferencesView()) {
                        Label("Store Preferences", systemImage: "store.fill")
                    }
                    
                    NavigationLink(destination: ShoppingPreferencesView()) {
                        Label("Shopping Preferences", systemImage: "cart.fill")
                    }
                }
                
                // Account Section
                Section("Account") {
                    Button(action: { showingEditProfile = true }) {
                        Label("Edit Profile", systemImage: "person.fill")
                    }
                    
                    NavigationLink(destination: SecuritySettingsView()) {
                        Label("Security", systemImage: "lock.fill")
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy", systemImage: "hand.raised.fill")
                    }
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink(destination: HelpCenterView()) {
                        Label("Help Center", systemImage: "questionmark.circle.fill")
                    }
                    
                    NavigationLink(destination: ContactSupportView()) {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle.fill")
                    }
                }
                
                // Sign Out Section
                Section {
                    Button(action: signOut) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
        }
    }
    
    private func signOut() {
        appState.signOut()
    }
}

class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager.shared
    
    func updateProfile(name: String, email: String) {
        // TODO: Implement actual API call
    }
    
    func updatePreferences(preferences: [String: Any]) {
        // TODO: Implement actual API call
    }
}

// MARK: - Supporting Views
struct NotificationSettingsView: View {
    var body: some View {
        List {
            Section("Price Alerts") {
                Toggle("Price Drops", isOn: .constant(true))
                Toggle("New Deals", isOn: .constant(true))
                Toggle("Weekly Summary", isOn: .constant(true))
            }
            
            Section("Shopping Reminders") {
                Toggle("List Reminders", isOn: .constant(true))
                Toggle("Store Hours", isOn: .constant(true))
            }
        }
        .navigationTitle("Notifications")
    }
}

struct StorePreferencesView: View {
    var body: some View {
        List {
            Section("Favorite Stores") {
                ForEach(["Kroger", "Whole Foods", "Safeway"], id: \.self) { store in
                    Toggle(store, isOn: .constant(true))
                }
            }
            
            Section("Store Notifications") {
                Toggle("New Store Deals", isOn: .constant(true))
                Toggle("Store Hours Changes", isOn: .constant(true))
            }
        }
        .navigationTitle("Store Preferences")
    }
}

struct ShoppingPreferencesView: View {
    var body: some View {
        List {
            Section("Shopping List") {
                Toggle("Auto-sort by Category", isOn: .constant(true))
                Toggle("Show Price History", isOn: .constant(true))
            }
            
            Section("Price Comparison") {
                Toggle("Include Online Stores", isOn: .constant(true))
                Toggle("Show Price Trends", isOn: .constant(true))
            }
        }
        .navigationTitle("Shopping Preferences")
    }
}

struct SecuritySettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("Change Password") {
                    Text("Change Password View")
                }
                
                NavigationLink("Two-Factor Authentication") {
                    Text("2FA View")
                }
            }
            
            Section {
                NavigationLink("Connected Devices") {
                    Text("Devices View")
                }
                
                NavigationLink("Login History") {
                    Text("Login History View")
                }
            }
        }
        .navigationTitle("Security")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        List {
            Section("Data Collection") {
                Toggle("Usage Analytics", isOn: .constant(true))
                Toggle("Location Services", isOn: .constant(true))
            }
            
            Section {
                NavigationLink("Data Export") {
                    Text("Data Export View")
                }
                
                NavigationLink("Delete Account") {
                    Text("Delete Account View")
                }
            }
        }
        .navigationTitle("Privacy")
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Full Name", text: $fullName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    // TODO: Save changes
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
} 