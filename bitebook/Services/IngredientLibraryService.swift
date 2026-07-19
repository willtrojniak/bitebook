import SwiftData

@MainActor
final class IngredientLibraryService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func search(_ query: String) -> [Ingredient] {
        []
    }

    @discardableResult
    func save(ingredient: Ingredient?, name: String, measurement: IngredientMeasurement)
        -> Ingredient
    {
        let saved: Ingredient
        if let ingredient {
            ingredient.update(name: name, measurement: measurement)
            saved = ingredient
        } else {
            let newIngredient = Ingredient(name: name, measurement: measurement)
            modelContext.insert(newIngredient)
            saved = newIngredient
        }

        try? modelContext.save()
        return saved
    }

    func delete(_ ingredient: Ingredient) {
        modelContext.delete(ingredient)
        try? modelContext.save()
    }

    // Recipes referencing this ingredient — used for both the delete-block check and,
    // if blocked, to name the offending recipes. Fetches all recipes and filters via
    // Recipe.ingredients (already a to-many array) in plain Swift rather than a
    // predicate that traverses a relationship, matching the in-memory-filter pattern
    // already used elsewhere in this app instead of relying on SwiftData predicate
    // behavior that hasn't specifically been verified for this shape.
    func recipes(using ingredient: Ingredient) -> [Recipe] {
        let allRecipes = (try? modelContext.fetch(FetchDescriptor<Recipe>())) ?? []

        return allRecipes.filter { recipe in
            recipe.ingredients.contains { $0.ingredient.id == ingredient.id }
        }
    }
}
