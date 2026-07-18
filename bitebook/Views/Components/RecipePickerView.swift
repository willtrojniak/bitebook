import SwiftUI

struct RecipePickerView: View {
    let recipes: [Recipe]
    let selectedRecipeIDs: Set<UUID>
    let onSelect: (Recipe) -> Void

    @State private var searchText = ""

    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        }

        return recipes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search Recipes", text: $searchText)
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

            List(filteredRecipes) { recipe in
                let isSelected = selectedRecipeIDs.contains(recipe.id)

                Button {
                    onSelect(recipe)
                } label: {
                    HStack {
                        Text(recipe.name)
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
