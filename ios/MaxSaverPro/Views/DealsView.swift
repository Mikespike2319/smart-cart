import SwiftUI
import Combine

struct DealsView: View {
    @StateObject private var viewModel = DealsViewModel()
    @State private var selectedCategory: String?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.deals.isEmpty {
                    ContentUnavailableView(
                        "No Deals Found",
                        systemImage: "tag.fill",
                        description: Text("Check back later for new deals")
                    )
                } else {
                    List {
                        ForEach(viewModel.deals) { deal in
                            DealRowView(deal: deal)
                        }
                    }
                }
            }
            .navigationTitle("Best Deals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("All Categories") {
                            selectedCategory = nil
                        }
                        
                        ForEach(viewModel.categories, id: \.self) { category in
                            Button(category) {
                                selectedCategory = category
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onChange(of: selectedCategory) { category in
                viewModel.filterDeals(by: category)
            }
        }
    }
}

struct DealRowView: View {
    let deal: Deal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(deal.productName)
                    .font(.headline)
                Spacer()
                Text("\(Int(deal.discountPercentage))% OFF")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(8)
            }
            
            HStack {
                Text(deal.storeName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("$\(String(format: "%.2f", deal.currentPrice))")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("Was $\(String(format: "%.2f", deal.averagePrice))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .strikethrough()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

class DealsViewModel: ObservableObject {
    @Published var deals: [Deal] = []
    @Published var isLoading = false
    @Published var categories: [String] = []
    
    private var allDeals: [Deal] = []
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager.shared
    
    init() {
        loadDeals()
    }
    
    func loadDeals() {
        isLoading = true
        // TODO: Implement actual API call
        // For now, use mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.allDeals = [
                Deal(id: 1, productName: "Organic Bananas", storeName: "Whole Foods", currentPrice: 2.99, averagePrice: 3.99, discountPercentage: 25),
                Deal(id: 2, productName: "Greek Yogurt", storeName: "Kroger", currentPrice: 3.99, averagePrice: 4.99, discountPercentage: 20),
                Deal(id: 3, productName: "Chicken Breast", storeName: "Safeway", currentPrice: 5.99, averagePrice: 7.99, discountPercentage: 25)
            ]
            self.deals = self.allDeals
            self.categories = ["Produce", "Dairy", "Meat", "Bakery"]
            self.isLoading = false
        }
    }
    
    func filterDeals(by category: String?) {
        guard let category = category else {
            deals = allDeals
            return
        }
        
        // TODO: Implement actual category filtering
        // For now, just filter the mock data
        deals = allDeals.filter { $0.productName.contains(category) }
    }
}

#Preview {
    DealsView()
} 