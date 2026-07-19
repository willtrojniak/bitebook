import SwiftData
import SwiftUI

private struct DraftRecipeIngredient: Identifiable {
    let id = UUID()

    let ingredient: Ingredient

    var quantity: Double
    var unitOfMeasurement: UnitOfMeasurement
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
                    quantity: $0.quantity,
                    unitOfMeasurement: $0.unitOfMeasurement
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(item.quantity <= 0 ? .red : .clear, lineWidth: 1.5)
                                )

                                Picker("", selection: $item.unitOfMeasurement) {
                                    ForEach(item.ingredient.validUnitsOfMeasurement, id: \.self) {
                                        unit in
                                        Text(unit.label(for: item.quantity)).tag(unit)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: 100)
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
                .disabled(recipeName.isEmpty || hasInvalidQuantities)
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

    private var hasInvalidQuantities: Bool {
        selectedIngredients.contains { $0.quantity <= 0 }
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
                unitOfMeasurement: ingredient.defaultUnitOfMeasurement
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
            ingredients: selectedIngredients.map {
                ($0.ingredient, $0.quantity, $0.unitOfMeasurement)
            }
        )
        dismiss()
    }

    private func deleteRecipe() {
        guard let recipe else { return }

        RecipeService(modelContext: modelContext).delete(recipe)
        dismiss()
    }
}
