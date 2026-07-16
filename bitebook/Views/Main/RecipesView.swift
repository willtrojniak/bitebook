import SwiftData
import SwiftUI

struct RecipesView: View {
    @State private var showingCreateRecipe = false
    var body: some View {
        Button {
            showingCreateRecipe = !showingCreateRecipe
        } label: {
            Text("New Recipe")
        }.sheet(isPresented: $showingCreateRecipe) {
            RecipeEditorView()
        }

        RecipeListView()
    }
}
