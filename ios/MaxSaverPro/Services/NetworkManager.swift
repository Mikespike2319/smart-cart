import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(String)
    case unauthorized
    case unknown
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://api.smartcart.app"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication
    func signIn(email: String, password: String) async throws -> User {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(User.self, from: data)
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password, "name": name]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 201:
            return try JSONDecoder().decode(User.self, from: data)
        case 400:
            throw NetworkError.serverError("Invalid input")
        default:
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Products
    func searchProducts(query: String, page: Int = 1) async throws -> SearchResult {
        let url = URL(string: "\(baseURL)/products/search?q=\(query)&page=\(page)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(SearchResult.self, from: data)
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    func getProductPrices(productId: Int) async throws -> [Price] {
        let url = URL(string: "\(baseURL)/products/\(productId)/prices")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode([Price].self, from: data)
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Shopping Lists
    func getShoppingLists() async throws -> [ShoppingList] {
        let url = URL(string: "\(baseURL)/shopping-lists")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode([ShoppingList].self, from: data)
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    func createShoppingList(name: String) async throws -> ShoppingList {
        let url = URL(string: "\(baseURL)/shopping-lists")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["name": name]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 201:
            return try JSONDecoder().decode(ShoppingList.self, from: data)
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Analytics
    func getUserSavings(days: Int = 30) async throws -> [String: Any] {
        let url = URL(string: "\(baseURL)/analytics/savings?days=\(days)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    func getPriceTrends(productId: Int, days: Int = 30) async throws -> [String: Any] {
        let url = URL(string: "\(baseURL)/analytics/products/\(productId)/trends?days=\(days)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
} 