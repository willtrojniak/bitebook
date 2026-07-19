import SwiftData
import SwiftUI

struct ShoppingListItemEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Ingredient.name)
    private var ingredients: [Ingredient]

    @State private var selectedIngredient: Ingredient?
    @State private var quantity: Double = 1
    @State private var unitOfMeasurement: UnitOfMeasurement = .unit
    @State private var showingIngredientPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Item")
                .font(.title2)
                .bold()

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Ingredient")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button {
                    showingIngredientPicker = true
                } label: {
                    HStack {
                        Text(selectedIngredient?.name ?? "Choose an Ingredient")
                            .foregroundStyle(selectedIngredient == nil ? .secondary : .primary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingIngredientPicker, arrowEdge: .top) {
                    IngredientPickerView(
                        ingredients: ingredients,
                        selectedIngredientIDs: selectedIngredient.map { Set([$0.id]) } ?? []
                    ) { ingredient in
                        selectIngredient(ingredient)
                        showingIngredientPicker = false
                    }
                }

                if let selectedIngredient {
                    HStack {
                        Text("Amount")

                        Spacer()

                        TextField(
                            "Amount",
                            value: $quantity,
                            format: .number
                        )
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(quantity <= 0 ? .red : .clear, lineWidth: 1.5)
                        )

                        Picker("", selection: $unitOfMeasurement) {
                            ForEach(selectedIngredient.validUnitsOfMeasurement, id: \.self) {
                                unit in
                                Text(unit.label(for: quantity)).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveItem()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 420, height: 260, alignment: .top)
    }

    private var isValid: Bool {
        selectedIngredient != nil && quantity > 0
    }

    private func selectIngredient(_ ingredient: Ingredient) {
        selectedIngredient = ingredient
        quantity = 1
        unitOfMeasurement = ingredient.defaultUnitOfMeasurement
    }

    private func saveItem() {
        guard let selectedIngredient else { return }

        ShoppingListItemService(modelContext: modelContext).addItem(
            ingredient: selectedIngredient,
            quantity: quantity,
            unitOfMeasurement: unitOfMeasurement
        )
        dismiss()
    }
}
