// SmartCart/ContentView.swift
// Complete Professional iOS App that connects to your existing backend

import SwiftUI
import Combine
import Foundation
import CoreLocation
import AVFoundation

// MARK: - App State Management
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var selectedTab: Tab = .search
    @Published var isLoading = false
    
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
}

// MARK: - Data Models (matching your backend)
struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let fullName: String
    let isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, isActive
        case fullName = "full_name"
        case createdAt = "created_at"
    }
}

struct Product: Codable, Identifiable {
    let id: Int
    let name: String
    let brand: String?
    let category: String?
    let description: String?
    let imageUrl: String?
    let barcode: String?
    let storeProductId: String?
    let storeId: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, brand, category, description, barcode
        case imageUrl = "image_url"
        case storeProductId = "store_product_id"
        case storeId = "store_id"
    }
}

struct Store: Codable, Identifiable {
    let id: Int
    let name: String
    let isActive: Bool
}

struct Price: Codable, Identifiable {
    let id: Int
    let productId: Int
    let storeId: Int
    let price: Double
    let currency: String
    let isSale: Bool
    let saleEndDate: Date?
    let timestamp: Date
    let store: Store?
    
    enum CodingKeys: String, CodingKey {
        case id, price, currency, timestamp, store
        case productId = "product_id"
        case storeId = "store_id"
        case isSale = "is_sale"
        case saleEndDate = "sale_end_date"
    }
}

struct ShoppingList: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let createdAt: Date
    let items: [ShoppingListItem]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, items
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct ShoppingListItem: Codable, Identifiable {
    let id: Int
    let shoppingListId: Int
    let productId: Int
    let quantity: Int
    let isChecked: Bool
    let product: Product?
    
    enum CodingKeys: String, CodingKey {
        case id, quantity, product
        case shoppingListId = "shopping_list_id"
        case productId = "product_id"
        case isChecked = "is_checked"
    }
}

struct SearchResult: Codable, Identifiable {
    let id: String
    let name: String
    let price: Double
    let imageUrl: String?
    let store: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, price, store
        case imageUrl = "image_url"
    }
}

// MARK: - Network Manager (connects to your backend)
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // CHANGE THIS TO YOUR DEPLOYED BACKEND URL
    private let baseURL = "http://localhost:8000"  // Update when deployed
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - API Methods matching your backend endpoints
    
    func searchProducts(query: String, location: CLLocation? = nil) -> AnyPublisher<[SearchResult], Error> {
        isLoading = true
        var urlComponents = URLComponents(string: "\(baseURL)/products/search")!
        
        var queryItems = [URLQueryItem(name: "q", value: query)]
        if let location = location {
            queryItems.append(URLQueryItem(name: "lat", value: String(location.coordinate.latitude)))
            queryItems.append(URLQueryItem(name: "lng", value: String(location.coordinate.longitude)))
        }
        urlComponents.queryItems = queryItems
        
        return URLSession.shared.dataTaskPublisher(for: urlComponents.url!)
            .map(\.data)
            .decode(type: SearchResponse.self, decoder: JSONDecoder())
            .map(\.results)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { _ in
                self.isLoading = false
            })
            .eraseToAnyPublisher()
    }
    
    func getProductPrices(productId: Int) -> AnyPublisher<[Price], Error> {
        let url = URL(string: "\(baseURL)/products/\(productId)/prices")!
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Price].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getBestDeals(category: String? = nil, limit: Int = 10) -> AnyPublisher<[Deal], Error> {
        var urlComponents = URLComponents(string: "\(baseURL)/products/deals/best")!
        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        urlComponents.queryItems = queryItems
        
        return URLSession.shared.dataTaskPublisher(for: urlComponents.url!)
            .map(\.data)
            .decode(type: [Deal].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getShoppingLists() -> AnyPublisher<[ShoppingList], Error> {
        let url = URL(string: "\(baseURL)/shopping-lists")!
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [ShoppingList].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getSavingsAnalytics(days: Int = 30) -> AnyPublisher<SavingsData, Error> {
        let url = URL(string: "\(baseURL)/analytics/savings?days=\(days)")!
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: SavingsData.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// Supporting types
struct SearchResponse: Codable {
    let results: [SearchResult]
    let count: Int
}

struct Deal: Codable, Identifiable {
    let id: Int
    let productId: Int
    let productName: String
    let storeName: String
    let currentPrice: Double
    let averagePrice: Double
    let discountPercentage: Double
    let isSale: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, isSale
        case productId = "product_id"
        case productName = "product_name"
        case storeName = "store_name"
        case currentPrice = "current_price"
        case averagePrice = "average_price"
        case discountPercentage = "discount_percentage"
    }
}

struct SavingsData: Codable {
    let totalSavings: Double
    let savingsByCategory: [String: Double]
    let bestDeals: [Deal]
    
    enum CodingKeys: String, CodingKey {
        case bestDeals = "best_deals"
        case totalSavings = "total_savings"
        case savingsByCategory = "savings_by_category"
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
}

// MARK: - Search ViewModel
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingResults = false
    
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager.shared
    private let locationManager = LocationManager()
    
    init() {
        // Debounce search to avoid too many API calls
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                if !searchText.isEmpty {
                    self?.performSearch()
                }
            }
            .store(in: &cancellables)
    }
    
    func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.searchProducts(query: searchText, location: locationManager.location)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        self?.isLoading = false
                    }
                },
                receiveValue: { [weak self] results in
                    self?.searchResults = results
                    self?.showingResults = true
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    func requestLocationPermission() {
        locationManager.requestLocation()
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var appState = AppState()
    
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
    }
}

// MARK: - Authentication View
struct AuthenticationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "cart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("Smart Cart")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Find the best grocery deals")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(ModernTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(ModernTextFieldStyle())
                        .textContentType(isSignUp ? .newPassword : .password)
                    
                    Button(action: authenticate) {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .padding()
        }
    }
    
    private func authenticate() {
        // TODO: Implement real authentication with your backend
        // For now, just simulate successful login
        withAnimation {
            appState.isAuthenticated = true
        }
    }
}

// MARK: - Modern Text Field Style
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

// MARK: - Search View
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var showingCamera = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search groceries...", text: $viewModel.searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        Button(action: { showingCamera = true }) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Quick Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            QuickCategoryButton(title: "🥬 Produce", action: { viewModel.searchText = "produce" })
                            QuickCategoryButton(title: "🥛 Dairy", action: { viewModel.searchText = "milk" })
                            QuickCategoryButton(title: "🍞 Bread", action: { viewModel.searchText = "bread" })
                            QuickCategoryButton(title: "🥩 Meat", action: { viewModel.searchText = "chicken" })
                            QuickCategoryButton(title: "🥫 Pantry", action: { viewModel.searchText = "canned goods" })
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Content
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.showingResults {
                    SearchResultsView(results: viewModel.searchResults)
                } else {
                    WelcomeSearchView(onLocationRequest: viewModel.requestLocationPermission)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCamera) {
                CameraView()
            }
        }
    }
}

// MARK: - Quick Category Button
struct QuickCategoryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(15)
        }
    }
}

// MARK: - Welcome Search View
struct WelcomeSearchView: View {
    let onLocationRequest: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("Find the Best Deals")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Search for groceries and compare prices across multiple stores to save money.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onLocationRequest) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Enable Location for Better Results")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Searching for the best prices...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    let results: [SearchResult]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(results) { result in
                    ProductCard(result: result)
                }
            }
            .padding()
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let result: SearchResult
    @State private var showingDetails = false
    
    var body: some View {
        Button(action: { showingDetails = true }) {
            HStack {
                // Product Image
                AsyncImage(url: URL(string: result.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(result.store)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("$\(result.price, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .sheet(isPresented: $showingDetails) {
            ProductDetailView(result: result)
        }
    }
}

// MARK: - Product Detail View
struct ProductDetailView: View {
    let result: SearchResult
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Product Image
                    AsyncImage(url: URL(string: result.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(result.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("$\(result.price, specifier: "%.2f")")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text(result.store)
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        
                        Divider()
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            ActionButton(
                                title: "Add to Shopping List",
                                icon: "plus.circle.fill",
                                color: .green
                            ) {
                                // TODO: Implement add to shopping list
                            }
                            
                            ActionButton(
                                title: "Compare Prices",
                                icon: "chart.bar.fill",
                                color: .blue
                            ) {
                                // TODO: Implement price comparison
                            }
                            
                            ActionButton(
                                title: "Set Price Alert",
                                icon: "bell.fill",
                                color: .orange
                            ) {
                                // TODO: Implement price alerts
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(10)
        }
    }
}

// MARK: - Shopping Lists View
struct ShoppingListsView: View {
    @StateObject private var viewModel = ShoppingListsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.shoppingLists) { list in
                    ShoppingListRow(list: list)
                }
            }
            .navigationTitle("Shopping Lists")
            .toolbar {
                Button(action: viewModel.createNewList) {
                    Image(systemName: "plus")
                }
            }
            .onAppear {
                viewModel.loadShoppingLists()
            }
        }
    }
}

// MARK: - Shopping List Row
struct ShoppingListRow: View {
    let list: ShoppingList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(list.name)
                .font(.headline)
            
            Text("\(list.items?.count ?? 0) items")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shopping Lists ViewModel
class ShoppingListsViewModel: ObservableObject {
    @Published var shoppingLists: [ShoppingList] = []
    @Published var isLoading = false
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadShoppingLists() {
        isLoading = true
        
        networkManager.getShoppingLists()
            .sink(
                receiveCompletion: { _ in
                    self.isLoading = false
                },
                receiveValue: { lists in
                    self.shoppingLists = lists
                }
            )
            .store(in: &cancellables)
    }
    
    func createNewList() {
        // TODO: Implement create new shopping list
    }
}

// MARK: - Deals View
struct DealsView: View {
    @StateObject private var viewModel = DealsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.deals) { deal in
                        DealCard(deal: deal)
                    }
                }
                .padding()
            }
            .navigationTitle("Best Deals")
            .onAppear {
                viewModel.loadDeals()
            }
        }
    }
}

// MARK: - Deal Card
struct DealCard: View {
    let deal: Deal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(Int(deal.discountPercentage))% OFF")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                Spacer()
                
                Text(deal.storeName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(deal.productName)
                .font(.headline)
            
            HStack {
                Text("$\(deal.averagePrice, specifier: "%.2f")")
                    .strikethrough()
                    .foregroundColor(.secondary)
                
                Text("$\(deal.currentPrice, specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("Save $\(deal.averagePrice - deal.currentPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Deals ViewModel
class DealsViewModel: ObservableObject {
    @Published var deals: [Deal] = []
    @Published var isLoading = false
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadDeals() {
        isLoading = true
        
        networkManager.getBestDeals(limit: 20)
            .sink(
                receiveCompletion: { _ in
                    self.isLoading = false
                },
                receiveValue: { deals in
                    self.deals = deals
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Total Savings Card
                    SavingsSummaryCard(totalSavings: viewModel.savingsData?.totalSavings ?? 0)
                    
                    // Savings by Category
                    if let categories = viewModel.savingsData?.savingsByCategory {
                        CategorySavingsCard(categories: categories)
                    }
                    
                    // Best Deals
                    if let deals = viewModel.savingsData?.bestDeals {
                        BestDealsCard(deals: deals)
                    }
                }
                .padding()
            }
            .navigationTitle("Your Savings")
            .onAppear {
                viewModel.loadSavingsData()
            }
        }
    }
}

// MARK: - Savings Summary Card
struct SavingsSummaryCard: View {
    let totalSavings: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Total Savings This Month")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("$\(totalSavings, specifier: "%.2f")")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.green)
            
            Text("Keep up the great work!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Category Savings Card
struct CategorySavingsCard: View {
    let categories: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings by Category")
                .font(.headline)
            
            ForEach(categories.sorted(by: { $0.value > $1.value }), id: \.key) { category, savings in
                HStack {
                    Text(category)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("$\(savings, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Best Deals Card
struct BestDealsCard: View {
    let deals: [Deal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Best Deals")
                .font(.headline)
            
            ForEach(deals.prefix(5)) { deal in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(deal.productName)
                            .font(.subheadline)
                        Text(deal.storeName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$\(deal.averagePrice - deal.currentPrice, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 4)
                
                if deal.id != deals.prefix(5).last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Analytics ViewModel
class AnalyticsViewModel: ObservableObject {
    @Published var savingsData: SavingsData?
    @Published var isLoading = false
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadSavingsData() {
        isLoading = true
        
        networkManager.getSavingsAnalytics()
            .sink(
                receiveCompletion: { _ in
                    self.isLoading = false
                },
                receiveValue: { data in
                    self.savingsData = data
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(appState.currentUser?.fullName ?? "Smart Shopper")
                                .font(.headline)
                            Text(appState.currentUser?.email ?? "user@smartcart.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Shopping") {
                    NavigationLink(destination: Text("Favorite Stores")) {
                        Label("Favorite Stores", systemImage: "building.2.fill")
                    }
                    
                    NavigationLink(destination: Text("Price Alerts")) {
                        Label("Price Alerts", systemImage: "bell.fill")
                    }
                    
                    NavigationLink(destination: Text("Shopping History")) {
                        Label("Shopping History", systemImage: "clock.fill")
                    }
                }
                
                Section("App") {
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    NavigationLink(destination: Text("Help & Support")) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: Text("About")) {
                        Label("About Smart Cart", systemImage: "info.circle")
                    }
                }
                
                Section {
                    Button(action: signOut) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private func signOut() {
        withAnimation {
            appState.isAuthenticated = false
            appState.currentUser = nil
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @State private var priceAlertsEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    Toggle("Price Alerts", isOn: $priceAlertsEnabled)
                }
                
                Section("Privacy") {
                    Toggle("Location Services", isOn: $locationEnabled)
                }
                
                Section("Data") {
                    Button("Clear Cache") {
                        // TODO: Implement clear cache
                    }
                    
                    Button("Export Data") {
                        // TODO: Implement data export
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Camera View
struct CameraView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Barcode Scanner")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Scan product barcodes for instant price comparison across stores.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Open Camera") {
                    // TODO: Implement camera functionality
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("Scanner")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
} 