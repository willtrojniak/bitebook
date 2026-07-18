import SwiftData

@MainActor
final class RecipeService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(
        recipe: Recipe?,
        name: String,
        ingredients: [(ingredient: Ingredient, quantity: Double)]
    ) {
        if let recipe {
            recipe.name = name

            for existingIngredient in recipe.ingredients {
                modelContext.delete(existingIngredient)
            }

            recipe.ingredients = ingredients.map {
                RecipeIngredient(
                    ingredient: $0.ingredient,
                    quantity: max($0.quantity, .leastNonzeroMagnitude)
                )
            }
        } else {
            let recipe = Recipe(
                name: name,
                ingredients: ingredients.map {
                    RecipeIngredient(
                    ingredient: $0.ingredient,
                    quantity: max($0.quantity, .leastNonzeroMagnitude)
                )
                }
            )

            modelContext.insert(recipe)
        }

        try? modelContext.save()
    }

    func delete(_ recipe: Recipe) {
        modelContext.delete(recipe)
        try? modelContext.save()
    }
}
