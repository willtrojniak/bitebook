import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
}

@Model
final class PlannedMeal {
    @Attribute(.unique)
    var id: UUID

    var date: Date
    var mealTypeRaw: String
    var recipe: Recipe
    var servings: Int

    var mealType: MealType {
        MealType(rawValue: mealTypeRaw) ?? .breakfast
    }

    init(date: Date, mealType: MealType, recipe: Recipe, servings: Int = 1) {
        self.id = UUID()
        self.date = date
        self.mealTypeRaw = mealType.rawValue
        self.recipe = recipe
        self.servings = servings
    }

    static func matching(date: Date, mealType: MealType) -> Predicate<PlannedMeal> {
        let day = Calendar.current.startOfDay(for: date)
        let mealTypeRaw = mealType.rawValue

        return #Predicate<PlannedMeal> { $0.date == day && $0.mealTypeRaw == mealTypeRaw }
    }
}
