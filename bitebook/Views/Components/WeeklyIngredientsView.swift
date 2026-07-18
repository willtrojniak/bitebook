import SwiftUI

struct WeeklyIngredientsView: View {
    let ingredients: [AggregatedIngredient]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients This Week")
                .font(.headline)
                .foregroundStyle(.secondary)

            if ingredients.isEmpty {
                Text("No ingredients needed — plan a meal to see what you'll need.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(ingredients) { entry in
                        HStack {
                            Text(entry.ingredient.name)
                            Spacer()
                            Text(entry.quantity.formatted())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)

                        if entry.id != ingredients.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
