import SwiftData
import SwiftUI

// A plain-value snapshot of a row's displayed content. List rows read only from this —
// never live properties off a ShoppingListItem — so a bulk delete (e.g. "Clear Checked")
// that removes several rows in one update can't crash mid-diff/animation by touching a
// model object whose backing data has already been deleted.
private struct ShoppingRow: Identifiable {
    let id: UUID
    let ingredientName: String
    let quantityLabel: String
    let isChecked: Bool
}

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

    private var sortedRows: [ShoppingRow] {
        shoppingListItems
            .sorted {
                if $0.isChecked != $1.isChecked {
                    return !$0.isChecked
                }
                return $0.ingredient.name.localizedCaseInsensitiveCompare($1.ingredient.name)
                    == .orderedAscending
            }
            .map {
                ShoppingRow(
                    id: $0.id,
                    ingredientName: $0.ingredient.name,
                    quantityLabel:
                        "\($0.quantity.formatted(.number.precision(.fractionLength(0...3)))) \($0.unitOfMeasurement.label(for: $0.quantity))",
                    isChecked: $0.isChecked
                )
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
                    List(sortedRows) { row in
                        Button {
                            toggleChecked(row)
                        } label: {
                            HStack(spacing: 12) {
                                Image(
                                    systemName: row.isChecked
                                        ? "checkmark.circle.fill" : "circle"
                                )
                                .foregroundStyle(row.isChecked ? .green : .secondary)

                                Text(row.ingredientName)
                                    .strikethrough(row.isChecked)
                                    .foregroundStyle(row.isChecked ? .secondary : .primary)

                                Spacer()

                                Text(row.quantityLabel)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                delete(row)
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

    private func toggleChecked(_ row: ShoppingRow) {
        guard let item = shoppingListItems.first(where: { $0.id == row.id }) else { return }
        ShoppingListItemService(modelContext: modelContext).toggleChecked(item)
    }

    private func delete(_ row: ShoppingRow) {
        guard let item = shoppingListItems.first(where: { $0.id == row.id }) else { return }
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
