import SwiftData

@MainActor
final class ShoppingListItemService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func addItem(ingredient: Ingredient, quantity: Double, unitOfMeasurement: UnitOfMeasurement) {
        modelContext.insert(
            ShoppingListItem(
                ingredient: ingredient,
                quantity: quantity,
                unitOfMeasurement: unitOfMeasurement,
                isFromWeeklyPlan: false
            )
        )
        try? modelContext.save()
    }

    func toggleChecked(_ item: ShoppingListItem) {
        item.isChecked.toggle()
        try? modelContext.save()
    }

    func delete(_ item: ShoppingListItem) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    func clearChecked() {
        let allItems = (try? modelContext.fetch(FetchDescriptor<ShoppingListItem>())) ?? []

        for item in allItems where item.isChecked {
            modelContext.delete(item)
        }

        try? modelContext.save()
    }

    // Replaces previously-synced, still-unchecked items with fresh quantities from the
    // current plan. Checked items and manually-added items (isFromWeeklyPlan == false) are
    // left untouched.
    func syncCurrentWeekIngredients(plannedMeals: [PlannedMeal]) {
        let allItems = (try? modelContext.fetch(FetchDescriptor<ShoppingListItem>())) ?? []

        for item in allItems where item.isFromWeeklyPlan && !item.isChecked {
            modelContext.delete(item)
        }

        let aggregated = ShoppingListService.aggregatedIngredients(for: plannedMeals)

        for entry in aggregated {
            modelContext.insert(
                ShoppingListItem(
                    ingredient: entry.ingredient,
                    quantity: entry.quantity,
                    unitOfMeasurement: entry.ingredient.defaultUnitOfMeasurement,
                    isFromWeeklyPlan: true
                )
            )
        }

        try? modelContext.save()
    }
}
