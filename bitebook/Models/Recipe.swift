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
    var unitOfMeasurement: UnitOfMeasurement

    init(
        ingredient: Ingredient,
        quantity: Double,
        unitOfMeasurement: UnitOfMeasurement
    ) {
        precondition(
            ingredient.convertQuantity(
                1, from: ingredient.defaultUnitOfMeasurement, to: unitOfMeasurement) != nil,
            "UnitOfMeasurement must be a unit this ingredient has a conversion factor for")

        self.id = UUID()

        self.ingredient = ingredient
        self.quantity = quantity
        self.unitOfMeasurement = unitOfMeasurement
    }
}
