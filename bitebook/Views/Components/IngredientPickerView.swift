import SwiftUI

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

                        if let unitLabel = ingredient.unitLabel(for: 1) {
                            Text("· \(unitLabel)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }

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
