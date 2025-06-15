import SwiftUI
import Combine

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Total Savings Card
                            SavingsCard(
                                title: "Total Savings",
                                amount: viewModel.totalSavings,
                                period: "This Month"
                            )
                            
                            // Savings Breakdown
                            SavingsBreakdownView(breakdown: viewModel.savingsBreakdown)
                            
                            // Shopping Habits
                            ShoppingHabitsView(habits: viewModel.shoppingHabits)
                            
                            // Price Trends
                            PriceTrendsView(trends: viewModel.priceTrends)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Savings Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("This Week") {
                            viewModel.updateTimeRange(.week)
                        }
                        Button("This Month") {
                            viewModel.updateTimeRange(.month)
                        }
                        Button("This Year") {
                            viewModel.updateTimeRange(.year)
                        }
                    } label: {
                        Label("Time Range", systemImage: "calendar")
                    }
                }
            }
        }
    }
}

struct SavingsCard: View {
    let title: String
    let amount: Double
    let period: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("$\(String(format: "%.2f", amount))")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.green)
            
            Text(period)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SavingsBreakdownView: View {
    let breakdown: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings by Category")
                .font(.headline)
            
            ForEach(Array(breakdown.keys.sorted()), id: \.self) { category in
                HStack {
                    Text(category)
                    Spacer()
                    Text("$\(String(format: "%.2f", breakdown[category] ?? 0))")
                        .foregroundColor(.green)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ShoppingHabitsView: View {
    let habits: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shopping Habits")
                .font(.headline)
            
            ForEach(Array(habits.keys.sorted()), id: \.self) { habit in
                HStack {
                    Text(habit)
                    Spacer()
                    Text(habits[habit] ?? "")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PriceTrendsView: View {
    let trends: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Trends")
                .font(.headline)
            
            ForEach(Array(trends.keys.sorted()), id: \.self) { item in
                HStack {
                    Text(item)
                    Spacer()
                    Text("\(String(format: "%.1f", trends[item] ?? 0))%")
                        .foregroundColor(trends[item] ?? 0 < 0 ? .green : .red)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

class AnalyticsViewModel: ObservableObject {
    @Published var totalSavings: Double = 0
    @Published var savingsBreakdown: [String: Double] = [:]
    @Published var shoppingHabits: [String: String] = [:]
    @Published var priceTrends: [String: Double] = [:]
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager.shared
    
    init() {
        loadAnalytics()
    }
    
    func loadAnalytics() {
        isLoading = true
        // TODO: Implement actual API call
        // For now, use mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.totalSavings = 156.78
            self.savingsBreakdown = [
                "Groceries": 89.45,
                "Household": 45.32,
                "Personal Care": 22.01
            ]
            self.shoppingHabits = [
                "Most Visited Store": "Kroger",
                "Average Trip Cost": "$85.32",
                "Shopping Frequency": "2x per week"
            ]
            self.priceTrends = [
                "Milk": -5.2,
                "Eggs": -8.7,
                "Bread": 2.3,
                "Chicken": -12.5
            ]
            self.isLoading = false
        }
    }
    
    func updateTimeRange(_ range: TimeRange) {
        // TODO: Implement actual API call
        loadAnalytics()
    }
    
    enum TimeRange {
        case week, month, year
    }
}

#Preview {
    AnalyticsView()
} 