import Foundation
import SwiftData

struct RecipeServings {
    let recipe: Recipe
    let servings: Int
}

@MainActor
final class MealPlanService {
    private let modelContext: ModelContext
    private let calendar = Calendar.current

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func plannedMeals(for date: Date, mealType: MealType) -> [PlannedMeal] {
        let descriptor = FetchDescriptor<PlannedMeal>(
            predicate: PlannedMeal.matching(date: date, mealType: mealType)
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func addRecipe(_ recipe: Recipe, to date: Date, mealType: MealType) {
        let day = calendar.startOfDay(for: date)

        guard
            !plannedMeals(for: day, mealType: mealType).contains(where: {
                $0.recipe.id == recipe.id
            })
        else {
            return
        }

        modelContext.insert(PlannedMeal(date: day, mealType: mealType, recipe: recipe))
        try? modelContext.save()
    }

    func removeRecipe(_ recipe: Recipe, from date: Date, mealType: MealType) {
        for match in plannedMeals(for: date, mealType: mealType) where match.recipe.id == recipe.id
        {
            modelContext.delete(match)
        }

        try? modelContext.save()
    }

    func setServings(_ servings: Int, for plannedMeal: PlannedMeal) {
        plannedMeal.servings = max(1, servings)
        try? modelContext.save()
    }

    func setRecipes(_ entries: [RecipeServings], for date: Date, mealType: MealType) {
        let day = calendar.startOfDay(for: date)

        for existing in plannedMeals(for: day, mealType: mealType) {
            modelContext.delete(existing)
        }

        for entry in entries {
            modelContext.insert(
                PlannedMeal(
                    date: day, mealType: mealType, recipe: entry.recipe, servings: entry.servings)
            )
        }

        try? modelContext.save()
    }
}
