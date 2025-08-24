import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            ForEach(viewModel.favorites) { favorite in
                FavoriteRow(item: favorite)
            }
            .onDelete { indexSet in
                viewModel.removeFavorites(at: indexSet)
            }
        }
        .listStyle(.inset)
        .toolbar {
            ToolbarItem {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddFavoriteView(viewModel: viewModel)
        }
    }
}

struct FavoriteRow: View {
    let item: FavoriteItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.headline)
            
            Text(item.template)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddFavoriteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FavoritesViewModel
    @State private var name = ""
    @State private var template = ""
    @State private var tags = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("名称", text: $name)
                TextField("模板", text: $template)
                TextField("标签（用逗号分隔）", text: $tags)
            }
            .padding()
            .navigationTitle("添加收藏")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let tagArray = tags.split(separator: ",").map(String.init)
                        viewModel.addFavorite(name: name, template: template, tags: tagArray)
                        dismiss()
                    }
                    .disabled(name.isEmpty || template.isEmpty)
                }
            }
        }
    }
}

class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteItem] = []
    
    func addFavorite(name: String, template: String, tags: [String]) {
        let favorite = FavoriteItem(name: name, template: template, tags: tags)
        favorites.append(favorite)
    }
    
    func removeFavorites(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
    }
}

struct FavoriteItem: Identifiable {
    let id = UUID()
    let name: String
    let template: String
    let tags: [String]
}
