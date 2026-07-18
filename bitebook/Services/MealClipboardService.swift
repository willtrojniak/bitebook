import Foundation
import SwiftData

@Observable
final class MealClipboard {
    // nil means nothing has been copied yet; an empty array is a valid
    // copied value (a meal with no recipes assigned).
    private(set) var recipes: [Recipe]?

    var canPaste: Bool { recipes != nil }

    func copy(from date: Date, mealType: MealType, modelContext: ModelContext) {
        recipes = MealPlanService(modelContext: modelContext).recipes(for: date, mealType: mealType)
    }

    func paste(to date: Date, mealType: MealType, modelContext: ModelContext) {
        MealPlanService(modelContext: modelContext)
            .setRecipes(recipes ?? [], for: date, mealType: mealType)
    }
}
