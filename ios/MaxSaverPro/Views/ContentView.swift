import SwiftUI
import Combine

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
                    .environmentObject(appState)
            } else {
                AuthenticationView()
                    .environmentObject(appState)
            }
        }
        .onAppear {
            // Check if user is already logged in
            checkAuthenticationStatus()
        }
    }
    
    private func checkAuthenticationStatus() {
        // TODO: Check for stored authentication token
        // For now, default to not authenticated
        appState.isAuthenticated = false
    }
}

// MARK: - App State Management
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var selectedTab: Tab = .search
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    enum Tab: CaseIterable {
        case search, lists, deals, analytics, profile
        
        var title: String {
            switch self {
            case .search: return "Search"
            case .lists: return "Lists"
            case .deals: return "Deals"
            case .analytics: return "Savings"
            case .profile: return "Profile"
            }
        }
        
        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .lists: return "list.bullet"
            case .deals: return "tag.fill"
            case .analytics: return "chart.bar.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.isAuthenticated = true
            self.currentUser = User(
                id: 1,
                email: email,
                fullName: "Smart Shopper",
                isActive: true,
                createdAt: Date()
            )
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        selectedTab = .search
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .accentColor(.blue)
    }
    
    @ViewBuilder
    private func tabContent(for tab: AppState.Tab) -> some View {
        switch tab {
        case .search:
            SearchView()
        case .lists:
            ShoppingListsView()
        case .deals:
            DealsView()
        case .analytics:
            AnalyticsView()
        case .profile:
            ProfileView()
        }
    }
}

// MARK: - UI Components
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    init(text: Binding<String>, placeholder: String = "Search...") {
        self._text = text
        self.placeholder = placeholder
    }
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Backend Connection Test
struct BackendConnectionTestView: View {
    @StateObject private var networkManager = NetworkManager.shared
    @State private var connectionStatus = "Not tested"
    @State private var isConnecting = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Backend Connection Test")
                .font(.headline)
            
            Text("Status: \(connectionStatus)")
                .font(.subheadline)
                .foregroundColor(connectionStatus == "Connected ✅" ? .green : 
                               connectionStatus == "Failed ❌" ? .red : .blue)
            
            Button(action: testConnection) {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isConnecting ? "Testing..." : "Test Connection")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isConnecting)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func testConnection() {
        isConnecting = true
        connectionStatus = "Testing..."
        
        networkManager.testConnection()
            .sink(
                receiveCompletion: { completion in
                    isConnecting = false
                    if case .failure = completion {
                        connectionStatus = "Failed ❌"
                    }
                },
                receiveValue: { success in
                    connectionStatus = success ? "Connected ✅" : "Failed ❌"
                }
            )
            .store(in: &networkManager.cancellables)
    }
}

struct AuthenticationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "cart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("MaxSaver Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(isSignUp ? .newPassword : .password)
                    
                    Button(action: {
                        // TODO: Implement authentication
                        appState.isAuthenticated = true
                    }) {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isSignUp.toggle()
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Featured Deals
                    VStack(alignment: .leading) {
                        Text("Featured Deals")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<5) { _ in
                                    DealCard()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Searches
                    VStack(alignment: .leading) {
                        Text("Recent Searches")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(0..<3) { _ in
                            RecentSearchRow()
                        }
                    }
                    
                    // Shopping List Preview
                    VStack(alignment: .leading) {
                        Text("Shopping List")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(0..<3) { _ in
                            ShoppingListItemRow()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}

struct DealCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "tag.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .foregroundColor(.blue)
            
            Text("Product Name")
                .font(.headline)
            
            Text("$9.99")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Save 20%")
                .font(.subheadline)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct RecentSearchRow: View {
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            Text("Recent Search")
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct ShoppingListItemRow: View {
    var body: some View {
        HStack {
            Image(systemName: "circle")
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text("Item Name")
                    .font(.headline)
                
                Text("$4.99")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("2")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct SearchView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                // Search results will go here
                ScrollView {
                    LazyVStack {
                        ForEach(0..<10) { _ in
                            ProductRow()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Search")
        }
    }
}

struct ProductRow: View {
    var body: some View {
        HStack {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text("Product Name")
                    .font(.headline)
                
                Text("Brand Name")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("$9.99")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Button(action: {
                // Add to shopping list
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct ShoppingListView: View {
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<10) { _ in
                    ShoppingListItemRow()
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                Button(action: {
                    // Add new item
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct DealsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(0..<10) { _ in
                        DealCard()
                    }
                }
                .padding()
            }
            .navigationTitle("Deals")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(appState.currentUser?.fullName ?? "User Name")
                                .font(.headline)
                            Text(appState.currentUser?.email ?? "user@example.com")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Preferences")) {
                    NavigationLink(destination: Text("Stores")) {
                        Label("Favorite Stores", systemImage: "store.fill")
                    }
                    
                    NavigationLink(destination: Text("Categories")) {
                        Label("Shopping Categories", systemImage: "tag.fill")
                    }
                    
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                }
                
                Section(header: Text("App")) {
                    NavigationLink(destination: Text("About")) {
                        Label("About", systemImage: "info.circle.fill")
                    }
                    
                    NavigationLink(destination: Text("Help")) {
                        Label("Help & Support", systemImage: "questionmark.circle.fill")
                    }
                    
                    Button(action: {
                        appState.isAuthenticated = false
                    }) {
                        Label("Sign Out", systemImage: "arrow.right.square.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
} 