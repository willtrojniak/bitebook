import Foundation
import SwiftData

@Model
final class ShoppingListItem {
    @Attribute(.unique)
    var id: UUID

    var ingredient: Ingredient
    var quantity: Double
    var unitOfMeasurement: UnitOfMeasurement
    var isChecked: Bool

    // true for items inserted by "Add This Week's Ingredients" — distinguishes them from
    // manually-added items so a resync only ever replaces its own previous output, never
    // something the user added themselves.
    var isFromWeeklyPlan: Bool

    init(
        ingredient: Ingredient,
        quantity: Double,
        unitOfMeasurement: UnitOfMeasurement,
        isFromWeeklyPlan: Bool
    ) {
        precondition(
            ingredient.convertQuantity(
                1, from: ingredient.defaultUnitOfMeasurement, to: unitOfMeasurement) != nil,
            "unitOfMeasurement must be a unit this ingredient has a conversion factor for")

        self.id = UUID()
        self.ingredient = ingredient
        self.quantity = quantity
        self.unitOfMeasurement = unitOfMeasurement
        self.isChecked = false
        self.isFromWeeklyPlan = isFromWeeklyPlan
    }
}
