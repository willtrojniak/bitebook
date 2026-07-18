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

    var recipe: Recipe? = nil

    @State private var recipeName: String
    @State private var selectedIngredients: [DraftRecipeIngredient]
    @State private var showingDeleteConfirmation = false
    @State private var showingIngredientPicker = false

    init(recipe: Recipe? = nil) {
        self.recipe = recipe
        _recipeName = State(initialValue: recipe?.name ?? "")
        _selectedIngredients = State(
            initialValue: recipe?.ingredients.map {
                DraftRecipeIngredient(
                    ingredient: $0.ingredient,
                    quantity: $0.quantity
                )
            } ?? []
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                TextField("New Recipe", text: $recipeName)
                    .textFieldStyle(.plain)
                    .font(.title2)
                    .bold()

                Spacer()

                if recipe != nil {
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Delete Recipe")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Ingredients")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        showingIngredientPicker = true
                    } label: {
                        Label("Add Ingredient", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .popover(isPresented: $showingIngredientPicker, arrowEdge: .top) {
                        IngredientPickerView(
                            ingredients: ingredients,
                            selectedIngredientIDs: Set(selectedIngredients.map { $0.ingredient.id })
                        ) { ingredient in
                            addIngredient(ingredient)
                        }
                        .frame(width: 280, height: 320)
                    }
                }

                if selectedIngredients.isEmpty {
                    Text("No ingredients added yet.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                } else {
                    List {
                        ForEach($selectedIngredients) { $item in
                            HStack(spacing: 12) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.secondary)

                                Text(item.ingredient.name)

                                Spacer()

                                TextField(
                                    "Amount",
                                    value: $item.quantity,
                                    format: .number
                                )
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 64)
                            }
                            .padding(.vertical, 2)
                            .padding(.trailing, 8)
                            .swipeActions {
                                Button("Remove", systemImage: "trash", role: .destructive) {
                                    removeIngredient(item)
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveRecipe()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(recipeName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520, height: 520, alignment: .top)
        .confirmationDialog(
            "Delete Recipe?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
        } message: {
            Text("This will remove the recipe and its ingredients.")
        }
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

    private func removeIngredient(_ item: DraftRecipeIngredient) {
        selectedIngredients.removeAll { $0.id == item.id }
    }

    private func saveRecipe() {
        RecipeService(modelContext: modelContext).save(
            recipe: recipe,
            name: recipeName,
            ingredients: selectedIngredients.map { ($0.ingredient, $0.quantity) }
        )
        dismiss()
    }

    private func deleteRecipe() {
        guard let recipe else { return }

        RecipeService(modelContext: modelContext).delete(recipe)
        dismiss()
    }
}

struct IngredientPickerView: View {
    let ingredients: [Ingredient]
    let selectedIngredientIDs: Set<UUID>
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
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search Ingredients", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)

            Divider()

            List(filteredIngredients) { ingredient in
                let isSelected = selectedIngredientIDs.contains(ingredient.id)

                Button {
                    onSelect(ingredient)
                } label: {
                    HStack {
                        Text(ingredient.name)
                            .foregroundStyle(isSelected ? .secondary : .primary)

                        Spacer()

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                            .foregroundStyle(isSelected ? .green : .accentColor)
                    }
                    .padding(.trailing, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isSelected)
            }
            .listStyle(.plain)
        }
    }
}
