import SwiftUI
import Combine

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var showScanner = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search products...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            viewModel.search(query: newValue)
                        }
                    
                    Button(action: { showScanner = true }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title2)
                    }
                }
                .padding()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try different search terms or scan a barcode")
                    )
                } else {
                    List(viewModel.searchResults) { result in
                        NavigationLink(destination: ProductDetailView(product: result)) {
                            ProductRowView(result: result)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView { barcode in
                    viewModel.searchByBarcode(barcode)
                    showScanner = false
                }
            }
        }
    }
}

struct ProductRowView: View {
    let result: SearchResult
    
    var body: some View {
        HStack {
            if let imageUrl = result.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(result.name)
                    .font(.headline)
                Text(result.store)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("$\(String(format: "%.2f", result.price))")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

class SearchViewModel: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager.shared
    
    func search(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        networkManager.searchProducts(query: query)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("Search error: \(error)")
                    }
                },
                receiveValue: { [weak self] results in
                    self?.searchResults = results
                }
            )
            .store(in: &cancellables)
    }
    
    func searchByBarcode(_ barcode: String) {
        // TODO: Implement barcode search
        print("Searching for barcode: \(barcode)")
    }
}

#Preview {
    SearchView()
} 