import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case unknown
}

class APIClient {
    static let shared = APIClient()
    private let baseURL = "http://localhost:8000"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) -> AnyPublisher<User, APIError> {
        let endpoint = "/auth/signin"
        let body = ["email": email, "password": password]
        
        return request(endpoint: endpoint, method: "POST", body: body)
    }
    
    func signUp(email: String, password: String, fullName: String) -> AnyPublisher<User, APIError> {
        let endpoint = "/auth/signup"
        let body = [
            "email": email,
            "password": password,
            "full_name": fullName
        ]
        
        return request(endpoint: endpoint, method: "POST", body: body)
    }
    
    // MARK: - Products
    
    func searchProducts(query: String) -> AnyPublisher<[Product], APIError> {
        let endpoint = "/products/search"
        let queryItems = [URLQueryItem(name: "q", value: query)]
        
        return request(endpoint: endpoint, method: "GET", queryItems: queryItems)
    }
    
    func getProduct(id: Int) -> AnyPublisher<Product, APIError> {
        let endpoint = "/products/\(id)"
        return request(endpoint: endpoint, method: "GET")
    }
    
    // MARK: - Shopping Lists
    
    func getShoppingLists() -> AnyPublisher<[ShoppingList], APIError> {
        let endpoint = "/shopping-lists"
        return request(endpoint: endpoint, method: "GET")
    }
    
    func createShoppingList(name: String) -> AnyPublisher<ShoppingList, APIError> {
        let endpoint = "/shopping-lists"
        let body = ["name": name]
        
        return request(endpoint: endpoint, method: "POST", body: body)
    }
    
    func addToShoppingList(listId: Int, productId: Int, quantity: Int) -> AnyPublisher<ShoppingListItem, APIError> {
        let endpoint = "/shopping-lists/\(listId)/items"
        let body = [
            "product_id": productId,
            "quantity": quantity
        ]
        
        return request(endpoint: endpoint, method: "POST", body: body)
    }
    
    // MARK: - Deals
    
    func getDeals() -> AnyPublisher<[Deal], APIError> {
        let endpoint = "/deals"
        return request(endpoint: endpoint, method: "GET")
    }
    
    // MARK: - Price Comparison
    
    func getProductPrices(productId: Int) async throws -> [Price] {
        let endpoint = "products/\(productId)/prices"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func getPriceHistory(productId: Int, days: Int = 30) async throws -> [PriceHistory] {
        let endpoint = "products/\(productId)/price-history?days=\(days)"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func getPricePredictions(productId: Int, daysAhead: Int = 7) async throws -> [PricePrediction] {
        let endpoint = "products/\(productId)/price-predictions?days_ahead=\(daysAhead)"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func getBestDeals(category: String? = nil, limit: Int = 10) async throws -> [Deal] {
        var endpoint = "deals/best?limit=\(limit)"
        if let category = category {
            endpoint += "&category=\(category)"
        }
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func comparePrices(productIds: [Int]) async throws -> [PriceComparison] {
        let endpoint = "products/compare"
        let body = ["product_ids": productIds]
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    func getPriceAlerts() async throws -> [PriceAlert] {
        let endpoint = "alerts/price"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    // MARK: - Private Methods
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil,
        queryItems: [URLQueryItem]? = nil
    ) -> AnyPublisher<T, APIError> {
        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token if available
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
            }
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<T, APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return Just(data)
                        .decode(type: T.self, decoder: JSONDecoder())
                        .mapError { APIError.decodingError($0) }
                        .eraseToAnyPublisher()
                case 401:
                    return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
                default:
                    return Fail(error: APIError.serverError("Server error: \(httpResponse.statusCode)")).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Models

struct Product: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let brand: String
    let category: String
    let barcode: String
    let imageUrl: String
    let storeId: Int
    let currentPrice: Price
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case brand
        case category
        case barcode
        case imageUrl = "image_url"
        case storeId = "store_id"
        case currentPrice = "current_price"
    }
}

struct Price: Codable {
    let id: Int
    let productId: Int
    let price: Double
    let currency: String
    let timestamp: Date
    let isSale: Bool
    let saleEndDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case price
        case currency
        case timestamp
        case isSale = "is_sale"
        case saleEndDate = "sale_end_date"
    }
}

struct ShoppingList: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let createdAt: Date
    let isActive: Bool
    let items: [ShoppingListItem]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case createdAt = "created_at"
        case isActive = "is_active"
        case items
    }
}

struct ShoppingListItem: Codable, Identifiable {
    let id: Int
    let shoppingListId: Int
    let productId: Int
    let quantity: Int
    let isPurchased: Bool
    let createdAt: Date
    let product: Product
    
    enum CodingKeys: String, CodingKey {
        case id
        case shoppingListId = "shopping_list_id"
        case productId = "product_id"
        case quantity
        case isPurchased = "is_purchased"
        case createdAt = "created_at"
        case product
    }
}

struct Deal: Codable, Identifiable {
    let id: Int
    let product: Product
    let discountPercentage: Double
    let validUntil: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case product
        case discountPercentage = "discount_percentage"
        case validUntil = "valid_until"
    }
}

// MARK: - Price Comparison Models

struct PriceComparison: Codable {
    let productId: Int
    let productName: String
    let prices: [Price]
    let lowestPrice: Price
    let priceDifference: [String: Double]
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case productName = "product_name"
        case prices
        case lowestPrice = "lowest_price"
        case priceDifference = "price_difference"
    }
}

struct PriceAlert: Codable, Identifiable {
    let id: Int
    let productId: Int
    let productName: String
    let storeName: String
    let currentPrice: Double
    let targetPrice: Double
    let savings: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case productName = "product_name"
        case storeName = "store_name"
        case currentPrice = "current_price"
        case targetPrice = "target_price"
        case savings
    }
} 