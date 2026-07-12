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
        Ingredient(
            name: "Chicken Breast"
        ),

        Ingredient(
            name: "Egg"
        ),

        Ingredient(
            name: "Rice"
        ),

        Ingredient(
            name: "Broccoli"
        ),
    ]
}
