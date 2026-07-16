import SwiftData
import SwiftUI

private struct DraftRecipeIngredient: Identifiable {
    let id = UUID()

    let ingredient: Ingredient

    var quantity: Double
}

struct RecipeEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Ingredient.name)
    private var ingredients: [Ingredient]

    @State private var recipeName = ""
    @State private var selectedIngredients: [DraftRecipeIngredient] = []

    var body: some View {
        VStack(spacing: 16) {
            Text("Create Recipe")
                .font(.title)

            TextField("Recipe Name", text: $recipeName)
                .textFieldStyle(.roundedBorder)

            Divider()

            IngredientPickerView(
                ingredients: ingredients
            ) { ingredient in
                addIngredient(ingredient)
            }

            Divider()

            List {
                ForEach($selectedIngredients) { $item in
                    HStack {
                        Text(item.ingredient.name)

                        Spacer()

                        TextField(
                            "Amount",
                            value: $item.quantity,
                            format: .number
                        )
                        .frame(width: 80)
                    }
                }
                .onDelete { indexSet in
                    selectedIngredients.remove(atOffsets: indexSet)
                }
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Save") {
                    saveRecipe()
                }
                .disabled(recipeName.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }

    private func addIngredient(_ ingredient: Ingredient) {
        guard
            !selectedIngredients.contains(
                where: { $0.ingredient.id == ingredient.id }
            )
        else {
            return
        }

        selectedIngredients.append(
            DraftRecipeIngredient(
                ingredient: ingredient,
                quantity: 1,
            )
        )
    }

    private func saveRecipe() {
        let recipe = Recipe(
            name: recipeName,
            ingredients: selectedIngredients.map {
                RecipeIngredient(
                    ingredient: $0.ingredient,
                    quantity: $0.quantity,
                )
            }
        )

        modelContext.insert(recipe)

        try? modelContext.save()
        dismiss()
    }
}

struct IngredientPickerView: View {
    let ingredients: [Ingredient]
    let onSelect: (Ingredient) -> Void

    @State private var searchText = ""

    private var filteredIngredients: [Ingredient] {
        if searchText.isEmpty {
            return ingredients
        }

        return ingredients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack {
            TextField(
                "Search Ingredients",
                text: $searchText
            )
            .textFieldStyle(.roundedBorder)

            List(filteredIngredients) { ingredient in
                Button {
                    onSelect(ingredient)
                } label: {
                    HStack {
                        Text(ingredient.name)

                        Spacer()

                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
