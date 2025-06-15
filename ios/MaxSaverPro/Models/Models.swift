import Foundation

// MARK: - User
struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let name: String
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Product
struct Product: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let category: String
    let brand: String?
    let imageUrl: String?
    let barcode: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Store
struct Store: Codable, Identifiable {
    let id: Int
    let name: String
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Price
struct Price: Codable, Identifiable {
    let id: Int
    let productId: Int
    let storeId: Int
    let price: Double
    let currency: String
    let isOnSale: Bool
    let saleEndsAt: Date?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - ShoppingList
struct ShoppingList: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let createdAt: Date
    let updatedAt: Date
    var items: [ShoppingListItem]
}

// MARK: - ShoppingListItem
struct ShoppingListItem: Codable, Identifiable {
    let id: Int
    let shoppingListId: Int
    let productId: Int
    let quantity: Int
    let isChecked: Bool
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - SearchResult
struct SearchResult: Codable {
    let products: [Product]
    let total: Int
    let page: Int
    let pageSize: Int
} 