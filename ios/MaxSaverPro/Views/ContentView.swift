import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppState.Tab.home)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppState.Tab.search)
            
            ShoppingListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
                .tag(AppState.Tab.shoppingList)
            
            DealsView()
                .tabItem {
                    Label("Deals", systemImage: "tag.fill")
                }
                .tag(AppState.Tab.deals)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppState.Tab.profile)
        }
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

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search products...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
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