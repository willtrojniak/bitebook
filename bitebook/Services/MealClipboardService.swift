import Foundation
import SwiftData

@Observable
final class MealClipboard {
    // nil means nothing has been copied yet; an empty array is a valid
    // copied value (a meal with no recipes assigned).
    private(set) var entries: [RecipeServings]?

    var canPaste: Bool { entries != nil }

    func copy(from date: Date, mealType: MealType, modelContext: ModelContext) {
        entries = MealPlanService(modelContext: modelContext)
            .plannedMeals(for: date, mealType: mealType)
            .map { RecipeServings(recipe: $0.recipe, servings: $0.servings) }
    }

    func paste(to date: Date, mealType: MealType, modelContext: ModelContext) {
        MealPlanService(modelContext: modelContext)
            .setRecipes(entries ?? [], for: date, mealType: mealType)
    }
}
