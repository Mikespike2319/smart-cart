import SwiftUI
import Combine

struct ShoppingListsView: View {
    @StateObject private var viewModel = ShoppingListsViewModel()
    @State private var showingNewListSheet = false
    @State private var newListName = ""
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.shoppingLists.isEmpty {
                    ContentUnavailableView(
                        "No Shopping Lists",
                        systemImage: "list.bullet",
                        description: Text("Create your first shopping list to get started")
                    )
                } else {
                    List {
                        ForEach(viewModel.shoppingLists) { list in
                            NavigationLink(destination: ShoppingListDetailView(list: list)) {
                                ShoppingListRowView(list: list)
                            }
                        }
                        .onDelete(perform: viewModel.deleteList)
                    }
                }
            }
            .navigationTitle("Shopping Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewListSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewListSheet) {
                NavigationView {
                    Form {
                        Section {
                            TextField("List Name", text: $newListName)
                        }
                    }
                    .navigationTitle("New Shopping List")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingNewListSheet = false
                        },
                        trailing: Button("Create") {
                            viewModel.createList(name: newListName)
                            newListName = ""
                            showingNewListSheet = false
                        }
                        .disabled(newListName.isEmpty)
                    )
                }
            }
        }
    }
}

struct ShoppingListRowView: View {
    let list: ShoppingList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(list.name)
                .font(.headline)
            
            if let items = list.items {
                Text("\(items.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("Created \(list.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

class ShoppingListsViewModel: ObservableObject {
    @Published var shoppingLists: [ShoppingList] = []
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager.shared
    
    init() {
        loadShoppingLists()
    }
    
    func loadShoppingLists() {
        isLoading = true
        // TODO: Implement actual API call
        // For now, use mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.shoppingLists = [
                ShoppingList(id: 1, userId: 1, name: "Weekly Groceries", createdAt: Date(), items: []),
                ShoppingList(id: 2, userId: 1, name: "Party Supplies", createdAt: Date().addingTimeInterval(-86400), items: [])
            ]
            self.isLoading = false
        }
    }
    
    func createList(name: String) {
        // TODO: Implement actual API call
        let newList = ShoppingList(
            id: shoppingLists.count + 1,
            userId: 1,
            name: name,
            createdAt: Date(),
            items: []
        )
        shoppingLists.append(newList)
    }
    
    func deleteList(at offsets: IndexSet) {
        // TODO: Implement actual API call
        shoppingLists.remove(atOffsets: offsets)
    }
}

#Preview {
    ShoppingListsView()
} 