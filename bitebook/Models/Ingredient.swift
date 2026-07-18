import Foundation
import SwiftData

@Model
final class Ingredient {
    @Attribute(.unique)
    var id: UUID

    var name: String

    init(
        name: String
    ) {
        self.id = UUID()
        self.name = name
    }
}

struct IngredientLibrary {
    static let defaultIngredients: [Ingredient] = [
        // Proteins
        Ingredient(name: "Chicken Breast"),
        Ingredient(name: "Chicken Thigh"),
        Ingredient(name: "Ground Beef"),
        Ingredient(name: "Ground Turkey"),
        Ingredient(name: "Pork Chop"),
        Ingredient(name: "Bacon"),
        Ingredient(name: "Salmon"),
        Ingredient(name: "Shrimp"),
        Ingredient(name: "Tofu"),
        Ingredient(name: "Egg"),

        // Grains & Starches
        Ingredient(name: "Rice"),
        Ingredient(name: "Quinoa"),
        Ingredient(name: "Pasta"),
        Ingredient(name: "Bread"),
        Ingredient(name: "Tortilla"),
        Ingredient(name: "Potato"),
        Ingredient(name: "Sweet Potato"),
        Ingredient(name: "Oats"),

        // Vegetables
        Ingredient(name: "Broccoli"),
        Ingredient(name: "Carrot"),
        Ingredient(name: "Onion"),
        Ingredient(name: "Garlic"),
        Ingredient(name: "Bell Pepper"),
        Ingredient(name: "Spinach"),
        Ingredient(name: "Lettuce"),
        Ingredient(name: "Tomato"),
        Ingredient(name: "Cucumber"),
        Ingredient(name: "Zucchini"),
        Ingredient(name: "Mushroom"),
        Ingredient(name: "Celery"),

        // Fruits
        Ingredient(name: "Apple"),
        Ingredient(name: "Banana"),
        Ingredient(name: "Lemon"),
        Ingredient(name: "Avocado"),

        // Dairy
        Ingredient(name: "Milk"),
        Ingredient(name: "Butter"),
        Ingredient(name: "Cheddar Cheese"),
        Ingredient(name: "Mozzarella Cheese"),
        Ingredient(name: "Parmesan Cheese"),
        Ingredient(name: "Greek Yogurt"),

        // Pantry
        Ingredient(name: "Olive Oil"),
        Ingredient(name: "Salt"),
        Ingredient(name: "Black Pepper"),
        Ingredient(name: "Soy Sauce"),
        Ingredient(name: "Flour"),
        Ingredient(name: "Sugar"),
        Ingredient(name: "Chicken Broth"),
        Ingredient(name: "Canned Tomatoes"),
        Ingredient(name: "Black Beans"),
    ]
}
