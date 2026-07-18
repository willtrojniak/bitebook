import SwiftData
import SwiftUI

struct RecipesView: View {
    @State private var showingCreateRecipe = false

    var body: some View {
        NavigationStack {
            RecipeListView()
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingCreateRecipe = true
                        } label: {
                            Label("New Recipe", systemImage: "plus")
                        }
                    }
                }
        }
        .sheet(isPresented: $showingCreateRecipe) {
            RecipeEditorView()
        }
    }
}
