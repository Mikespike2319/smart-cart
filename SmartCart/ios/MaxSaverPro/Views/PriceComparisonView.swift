import SwiftUI

struct PriceComparisonView: View {
    let product: Product
    @StateObject private var viewModel = PriceComparisonViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product Header
                ProductHeaderView(product: product)
                
                // Current Prices
                CurrentPricesView(prices: viewModel.prices)
                
                // Price History Chart
                if !viewModel.priceHistory.isEmpty {
                    PriceHistoryChartView(priceHistory: viewModel.priceHistory)
                }
                
                // Price Predictions
                if !viewModel.predictions.isEmpty {
                    PricePredictionsView(predictions: viewModel.predictions)
                }
                
                // Best Deals
                if !viewModel.bestDeals.isEmpty {
                    BestDealsView(deals: viewModel.bestDeals)
                }
            }
            .padding()
        }
        .navigationTitle("Price Comparison")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.refreshData()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            viewModel.loadData(for: product)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct ProductHeaderView: View {
    let product: Product
    
    var body: some View {
        VStack(spacing: 10) {
            if let imageUrl = product.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
                .cornerRadius(10)
            }
            
            Text(product.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(product.category)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct CurrentPricesView: View {
    let prices: [Price]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Prices")
                .font(.headline)
            
            ForEach(prices) { price in
                HStack {
                    Text(price.storeName)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(price.price, specifier: "%.2f")")
                            .fontWeight(.bold)
                        
                        if price.isSale {
                            Text("On Sale")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
            }
        }
    }
}

struct PriceHistoryChartView: View {
    let priceHistory: [PriceHistory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Price History")
                .font(.headline)
            
            Chart {
                ForEach(priceHistory) { history in
                    LineMark(
                        x: .value("Date", history.date),
                        y: .value("Price", history.price)
                    )
                    .foregroundStyle(by: .value("Store", history.storeName))
                }
            }
            .frame(height: 200)
        }
    }
}

struct PricePredictionsView: View {
    let predictions: [PricePrediction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Price Predictions")
                .font(.headline)
            
            ForEach(predictions) { prediction in
                HStack {
                    Text("\(prediction.daysAhead) days")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(prediction.predictedPrice, specifier: "%.2f")")
                            .fontWeight(.bold)
                        
                        Text("\(Int(prediction.confidence * 100))% confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
            }
        }
    }
}

struct BestDealsView: View {
    let deals: [Deal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Best Deals")
                .font(.headline)
            
            ForEach(deals) { deal in
                HStack {
                    VStack(alignment: .leading) {
                        Text(deal.productName)
                            .fontWeight(.medium)
                        
                        Text(deal.storeName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(deal.currentPrice, specifier: "%.2f")")
                            .fontWeight(.bold)
                        
                        Text("\(Int(deal.discountPercentage))% off")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
            }
        }
    }
}

class PriceComparisonViewModel: ObservableObject {
    @Published var prices: [Price] = []
    @Published var priceHistory: [PriceHistory] = []
    @Published var predictions: [PricePrediction] = []
    @Published var bestDeals: [Deal] = []
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let apiClient = APIClient.shared
    
    func loadData(for product: Product) {
        Task {
            do {
                // Load current prices
                let prices = try await apiClient.getProductPrices(productId: product.id)
                await MainActor.run {
                    self.prices = prices
                }
                
                // Load price history
                let history = try await apiClient.getPriceHistory(productId: product.id)
                await MainActor.run {
                    self.priceHistory = history
                }
                
                // Load price predictions
                let predictions = try await apiClient.getPricePredictions(productId: product.id)
                await MainActor.run {
                    self.predictions = predictions
                }
                
                // Load best deals
                let deals = try await apiClient.getBestDeals(category: product.category)
                await MainActor.run {
                    self.bestDeals = deals
                }
            } catch {
                await MainActor.run {
                    self.showError = true
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func refreshData() {
        // Implement refresh logic
    }
}

// MARK: - Models
struct Price: Identifiable {
    let id: Int
    let storeName: String
    let price: Double
    let isSale: Bool
    let saleEndDate: Date?
}

struct PriceHistory: Identifiable {
    let id: Int
    let storeName: String
    let price: Double
    let date: Date
}

struct PricePrediction: Identifiable {
    let id: Int
    let daysAhead: Int
    let predictedPrice: Double
    let confidence: Double
}

struct Deal: Identifiable {
    let id: Int
    let productName: String
    let storeName: String
    let currentPrice: Double
    let discountPercentage: Double
} 