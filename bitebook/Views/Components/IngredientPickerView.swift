import SwiftUI

struct IngredientPickerView: View {
    let ingredients: [Ingredient]
    let selectedIngredientIDs: Set<UUID>
    let onSelect: (Ingredient) -> Void

    @State private var searchText = ""
    @State private var showingCreateIngredient = false

    private var filteredIngredients: [Ingredient] {
        if searchText.isEmpty {
            return ingredients
        }

        return ingredients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showsCreateNewRow: Bool {
        guard !trimmedSearchText.isEmpty else { return false }
        return !ingredients.contains {
            $0.name.compare(trimmedSearchText, options: .caseInsensitive) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
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

                List {
                    if showsCreateNewRow {
                        Button {
                            showingCreateIngredient = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Color.accentColor)

                                Text("Create \u{201C}\(trimmedSearchText)\u{201D}")
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(filteredIngredients) { ingredient in
                        let isSelected = selectedIngredientIDs.contains(ingredient.id)

                        Button {
                            onSelect(ingredient)
                        } label: {
                            HStack {
                                Text(ingredient.name)
                                    .foregroundStyle(isSelected ? .secondary : .primary)

                                Text("· \(ingredient.defaultUnitOfMeasurement.label(for: 1))")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Image(
                                    systemName: isSelected
                                        ? "checkmark.circle.fill" : "plus.circle"
                                )
                                .foregroundStyle(isSelected ? .green : .accentColor)
                            }
                            .padding(.trailing, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isSelected)
                    }
                }
                .listStyle(.plain)
            }
            .navigationDestination(isPresented: $showingCreateIngredient) {
                IngredientEditorView(initialName: trimmedSearchText) { newIngredient in
                    onSelect(newIngredient)
                }
            }
        }
        .frame(width: 420, height: 400)
    }
}
