import SwiftData
import SwiftUI

struct IngredientLibraryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Ingredient.name)
    private var ingredients: [Ingredient]

    @State private var ingredientToEdit: Ingredient?
    @State private var showingCreateIngredient = false
    @State private var blockedDeletionRecipeNames: [String]?

    var body: some View {
        Group {
            if ingredients.isEmpty {
                ContentUnavailableView(
                    "No Ingredients Yet",
                    systemImage: "carrot",
                    description: Text("Add an ingredient to get started.")
                )
            } else {
                List(ingredients) { ingredient in
                    Button {
                        ingredientToEdit = ingredient
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ingredient.name)

                            Text(ingredient.measurementSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            attemptDelete(ingredient)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Ingredients")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateIngredient = true
                } label: {
                    Label("Add Ingredient", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateIngredient) {
            IngredientEditorView()
        }
        .sheet(item: $ingredientToEdit) { ingredient in
            IngredientEditorView(ingredient: ingredient)
        }
        .alert(
            "Can't Delete Ingredient",
            isPresented: Binding(
                get: { blockedDeletionRecipeNames != nil },
                set: { isPresented in
                    if !isPresented { blockedDeletionRecipeNames = nil }
                }
            )
        ) {
            Button("OK") { blockedDeletionRecipeNames = nil }
        } message: {
            Text(
                "This ingredient is used in: \((blockedDeletionRecipeNames ?? []).joined(separator: ", ")). Remove it from those recipes first."
            )
        }
    }

    private func attemptDelete(_ ingredient: Ingredient) {
        let service = IngredientLibraryService(modelContext: modelContext)
        let usedIn = service.recipes(using: ingredient)

        if usedIn.isEmpty {
            service.delete(ingredient)
        } else {
            blockedDeletionRecipeNames = usedIn.map { $0.name }
        }
    }
}
