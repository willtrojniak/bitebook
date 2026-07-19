import Foundation

struct AggregatedIngredient: Identifiable {
    let ingredient: Ingredient
    let quantity: Double

    var id: UUID { ingredient.id }
}

enum ShoppingListService {
    static func aggregatedIngredients(for plannedMeals: [PlannedMeal]) -> [AggregatedIngredient] {
        var totals: [UUID: (ingredient: Ingredient, quantity: Double)] = [:]

        for plannedMeal in plannedMeals {
            for recipeIngredient in plannedMeal.recipe.ingredients {
                let rawAmount = recipeIngredient.quantity * Double(plannedMeal.servings)
                let ingredient = recipeIngredient.ingredient

                let amount =
                    ingredient.convertQuantity(
                        rawAmount,
                        from: recipeIngredient.unitOfMeasurement,
                        to: ingredient.defaultUnitOfMeasurement
                    ) ?? rawAmount

                totals[ingredient.id, default: (ingredient, 0)].quantity += amount
            }
        }

        return totals.values
            .map { AggregatedIngredient(ingredient: $0.ingredient, quantity: $0.quantity) }
            .sorted { $0.ingredient.name < $1.ingredient.name }
    }
}
