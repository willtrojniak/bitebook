import SwiftData
import SwiftUI

struct ShoppingView: View {
    @Environment(\.modelContext) private var modelContext

    @Query
    private var shoppingListItems: [ShoppingListItem]

    @Query(sort: \PlannedMeal.date)
    private var plannedMeals: [PlannedMeal]

    @State private var showingAddItem = false

    private var mondayStartIsoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current

        return calendar
    }

    private var currentWeekDates: [Date] {
        let startOfWeek = mondayStartIsoCalendar.date(
            from: mondayStartIsoCalendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: Date())
        )!

        return (0..<7).compactMap {
            mondayStartIsoCalendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }

    private var currentWeekPlannedMeals: [PlannedMeal] {
        plannedMeals.filter { plannedMeal in
            currentWeekDates.contains {
                mondayStartIsoCalendar.isDate($0, inSameDayAs: plannedMeal.date)
            }
        }
    }

    private var sortedItems: [ShoppingListItem] {
        shoppingListItems.sorted {
            if $0.isChecked != $1.isChecked {
                return !$0.isChecked
            }
            return $0.ingredient.name.localizedCaseInsensitiveCompare($1.ingredient.name)
                == .orderedAscending
        }
    }

    private var hasCheckedItems: Bool {
        shoppingListItems.contains { $0.isChecked }
    }

    var body: some View {
        NavigationStack {
            Group {
                if shoppingListItems.isEmpty {
                    ContentUnavailableView(
                        "Your Shopping List Is Empty",
                        systemImage: "cart",
                        description: Text(
                            "Add this week's ingredients or add an item to get started.")
                    )
                } else {
                    List(sortedItems) { item in
                        Button {
                            toggleChecked(item)
                        } label: {
                            HStack(spacing: 12) {
                                Image(
                                    systemName: item.isChecked
                                        ? "checkmark.circle.fill" : "circle"
                                )
                                .foregroundStyle(item.isChecked ? .green : .secondary)

                                Text(item.ingredient.name)
                                    .strikethrough(item.isChecked)
                                    .foregroundStyle(item.isChecked ? .secondary : .primary)

                                Spacer()

                                Text(
                                    "\(item.quantity.formatted(.number.precision(.fractionLength(0...3)))) \(item.unitOfMeasurement.label(for: item.quantity))"
                                )
                                .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                delete(item)
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("Shopping")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addThisWeeksIngredients()
                    } label: {
                        Label("Add This Week's Ingredients", systemImage: "calendar")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        clearChecked()
                    } label: {
                        Label("Clear Checked", systemImage: "checklist.unchecked")
                    }
                    .disabled(!hasCheckedItems)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                ShoppingListItemEditorView()
            }
        }
    }

    private func toggleChecked(_ item: ShoppingListItem) {
        ShoppingListItemService(modelContext: modelContext).toggleChecked(item)
    }

    private func delete(_ item: ShoppingListItem) {
        ShoppingListItemService(modelContext: modelContext).delete(item)
    }

    private func clearChecked() {
        ShoppingListItemService(modelContext: modelContext).clearChecked()
    }

    private func addThisWeeksIngredients() {
        ShoppingListItemService(modelContext: modelContext).syncCurrentWeekIngredients(
            plannedMeals: currentWeekPlannedMeals)
    }
}

#Preview {
    ShoppingView()
}
