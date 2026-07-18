import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Recipe.name)
    private var recipes: [Recipe]

    @State private var recipeToEdit: Recipe?
    @State private var recipeToDelete: Recipe?

    var body: some View {
        Group {
            if recipes.isEmpty {
                ContentUnavailableView(
                    "No Recipes Yet",
                    systemImage: "book.pages",
                    description: Text("Create a recipe to get started.")
                )
            } else {
                List(recipes) { recipe in
                    Button {
                        recipeToEdit = recipe
                    } label: {
                        RecipeRowView(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            recipeToDelete = recipe
                        }
                    }
                }
                .listStyle(.inset)
                #if MACOS
                    .alternatingRowBackgrounds()
                #endif
            }
        }
        .navigationTitle("Recipes")
        .sheet(item: $recipeToEdit) { recipe in
            RecipeEditorView(recipe: recipe)
        }
        .confirmationDialog(
            "Delete Recipe?",
            isPresented: Binding(
                get: { recipeToDelete != nil },
                set: { isPresented in
                    if !isPresented { recipeToDelete = nil }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
        } message: {
            Text("This will remove the recipe and its ingredients.")
        }
    }

    private func deleteRecipe() {
        guard let recipeToDelete else { return }

        RecipeService(modelContext: modelContext).delete(recipeToDelete)
        self.recipeToDelete = nil
    }
}

private struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name)
                    .font(.body)

                Text(ingredientSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var ingredientSummary: String {
        switch recipe.ingredients.count {
        case 0:
            return "No ingredients"
        case 1:
            return "1 ingredient"
        default:
            return "\(recipe.ingredients.count) ingredients"
        }
    }
}
