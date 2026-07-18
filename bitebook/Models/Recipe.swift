import Foundation
import SwiftData

@Model
final class Recipe {
    @Attribute(.unique)
    var id: UUID

    var name: String

    @Relationship(deleteRule: .cascade)
    var ingredients: [RecipeIngredient]

    @Relationship(deleteRule: .cascade, inverse: \PlannedMeal.recipe)
    var plannedMeals: [PlannedMeal] = []

    init(
        name: String,
        ingredients: [RecipeIngredient]
    ) {
        self.id = UUID()

        self.name = name
        self.ingredients = ingredients
    }
}

@Model
final class RecipeIngredient {
    @Attribute(.unique)
    var id: UUID

    var ingredient: Ingredient
    var quantity: Double

    init(
        ingredient: Ingredient,
        quantity: Double
    ) {
        self.id = UUID()

        self.ingredient = ingredient
        self.quantity = quantity
    }
}
