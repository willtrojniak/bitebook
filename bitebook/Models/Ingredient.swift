import Foundation
import SwiftData

enum MeasurementUnit: String, Codable, CaseIterable {
    case gram, ounce, pound, slice, unit, cup, tablespoon, teaspoon, clove, milliliter, can

    func label(for quantity: Double) -> String {
        quantity == 1 ? rawValue : rawValue + "s"
    }
}

@Model
final class Ingredient {
    @Attribute(.unique)
    var id: UUID

    var name: String
    var unitRaw: String

    var unit: MeasurementUnit {
        get { MeasurementUnit(rawValue: unitRaw) ?? .unit }
        set { unitRaw = newValue.rawValue }
    }

    init(
        name: String,
        unit: MeasurementUnit
    ) {
        self.id = UUID()
        self.name = name
        self.unitRaw = unit.rawValue
    }
}

struct IngredientLibrary {
    static let defaultIngredients: [Ingredient] = [
        // Proteins
        Ingredient(name: "Chicken Breast", unit: .pound),
        Ingredient(name: "Chicken Thigh", unit: .pound),
        Ingredient(name: "Ground Beef", unit: .pound),
        Ingredient(name: "Ground Turkey", unit: .pound),
        Ingredient(name: "Pork Chop", unit: .unit),
        Ingredient(name: "Bacon", unit: .slice),
        Ingredient(name: "Salmon", unit: .ounce),
        Ingredient(name: "Shrimp", unit: .ounce),
        Ingredient(name: "Tofu", unit: .ounce),
        Ingredient(name: "Egg", unit: .unit),

        // Grains & Starches
        Ingredient(name: "Rice", unit: .cup),
        Ingredient(name: "Quinoa", unit: .cup),
        Ingredient(name: "Pasta", unit: .ounce),
        Ingredient(name: "Bread", unit: .slice),
        Ingredient(name: "Tortilla", unit: .unit),
        Ingredient(name: "Potato", unit: .unit),
        Ingredient(name: "Sweet Potato", unit: .unit),
        Ingredient(name: "Oats", unit: .cup),

        // Vegetables
        Ingredient(name: "Broccoli", unit: .cup),
        Ingredient(name: "Carrot", unit: .unit),
        Ingredient(name: "Onion", unit: .unit),
        Ingredient(name: "Garlic", unit: .clove),
        Ingredient(name: "Bell Pepper", unit: .unit),
        Ingredient(name: "Spinach", unit: .cup),
        Ingredient(name: "Lettuce", unit: .cup),
        Ingredient(name: "Tomato", unit: .unit),
        Ingredient(name: "Cucumber", unit: .unit),
        Ingredient(name: "Zucchini", unit: .unit),
        Ingredient(name: "Mushroom", unit: .cup),
        Ingredient(name: "Celery", unit: .unit),

        // Fruits
        Ingredient(name: "Apple", unit: .unit),
        Ingredient(name: "Banana", unit: .unit),
        Ingredient(name: "Lemon", unit: .unit),
        Ingredient(name: "Avocado", unit: .unit),

        // Dairy
        Ingredient(name: "Milk", unit: .cup),
        Ingredient(name: "Butter", unit: .tablespoon),
        Ingredient(name: "Cheddar Cheese", unit: .cup),
        Ingredient(name: "Mozzarella Cheese", unit: .cup),
        Ingredient(name: "Parmesan Cheese", unit: .tablespoon),
        Ingredient(name: "Greek Yogurt", unit: .cup),

        // Pantry
        Ingredient(name: "Olive Oil", unit: .tablespoon),
        Ingredient(name: "Salt", unit: .teaspoon),
        Ingredient(name: "Black Pepper", unit: .teaspoon),
        Ingredient(name: "Soy Sauce", unit: .tablespoon),
        Ingredient(name: "Flour", unit: .cup),
        Ingredient(name: "Sugar", unit: .cup),
        Ingredient(name: "Chicken Broth", unit: .cup),
        Ingredient(name: "Canned Tomatoes", unit: .can),
        Ingredient(name: "Black Beans", unit: .can),
    ]
}
