import SwiftData
import SwiftUI

struct MealCell: Identifiable {
    let id = UUID()

    let date: Date
    let mealType: MealType
}

struct MealCellView: View {
    let recipes: [Recipe]
    let canPaste: Bool
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if recipes.isEmpty {
                Text("Add")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recipes.prefix(3)) { recipe in
                    Text(recipe.name)
                        .font(.caption)
                        .lineLimit(1)
                }

                if recipes.count > 3 {
                    Text("+\(recipes.count - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 70,
            alignment: recipes.isEmpty ? .center : .topLeading
        )
        .padding(6)
        .background(.gray.opacity(0.1))
        .cornerRadius(8)
        .contextMenu {
            Button("Copy Recipes", systemImage: "doc.on.doc", action: onCopy)

            Button("Paste Recipes", systemImage: "doc.on.clipboard", action: onPaste)
                .disabled(!canPaste)

            Divider()

            Button("Clear Recipes", systemImage: "trash", role: .destructive, action: onClear)
                .disabled(recipes.isEmpty)
        }
    }
}

struct PlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MealClipboard.self) private var clipboard

    @State private var selectedMeal: MealCell?
    @State private var currentWeek = Date()

    @Query(sort: \PlannedMeal.date)
    private var plannedMeals: [PlannedMeal]

    private var mondayStartIsoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current

        return calendar
    }

    private var weekDates: [Date] {
        let startOfWeek = mondayStartIsoCalendar.date(
            from: mondayStartIsoCalendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: currentWeek)
        )!

        return (0..<7).compactMap {
            mondayStartIsoCalendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }

    let rowLabelWidth: CGFloat = 140

    private func recipes(for date: Date, mealType: MealType) -> [Recipe] {
        plannedMeals.filter {
            mondayStartIsoCalendar.isDate($0.date, inSameDayAs: date) && $0.mealType == mealType
        }.map { $0.recipe }
    }

    private var weeklyPlannedMeals: [PlannedMeal] {
        plannedMeals.filter { plannedMeal in
            weekDates.contains { mondayStartIsoCalendar.isDate($0, inSameDayAs: plannedMeal.date) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    GridRow {
                        Spacer().frame(width: 0, height: 0)

                        WeekHeaderView(currentWeek: $currentWeek, weekDates: weekDates)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .gridCellColumns(7)
                    }
                    .padding(.vertical, 16)

                    // Header row
                    GridRow {
                        Text("")
                            .frame(width: rowLabelWidth)

                        ForEach(weekDates, id: \.self) { date in
                            VStack {
                                Text(
                                    date.formatted(
                                        .dateTime.weekday(.abbreviated)
                                    )
                                )

                                Text(
                                    date.formatted(
                                        .dateTime.day()
                                    )
                                )
                                .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    // Meal rows
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        GridRow {
                            Text(mealType.rawValue)
                                .fontWeight(.medium)
                                .frame(width: rowLabelWidth, alignment: .center)

                            ForEach(weekDates, id: \.self) { date in
                                MealCellView(
                                    recipes: recipes(for: date, mealType: mealType),
                                    canPaste: clipboard.canPaste,
                                    onCopy: {
                                        clipboard.copy(
                                            from: date, mealType: mealType,
                                            modelContext: modelContext)
                                    },
                                    onPaste: {
                                        clipboard.paste(
                                            to: date, mealType: mealType, modelContext: modelContext
                                        )
                                    },
                                    onClear: {
                                        MealPlanService(modelContext: modelContext)
                                            .setRecipes([], for: date, mealType: mealType)
                                    }
                                )
                                .onTapGesture {
                                    selectedMeal = MealCell(
                                        date: date,
                                        mealType: mealType
                                    )
                                }
                            }
                        }
                    }
                }

                Divider()

                WeeklyIngredientsView(
                    ingredients: ShoppingListService.aggregatedIngredients(for: weeklyPlannedMeals)
                )
            }
            .padding()
        }
        .sheet(item: $selectedMeal) { meal in
            MealEditorView(date: meal.date, mealType: meal.mealType)
        }
    }
}

#Preview {
    PlannerView()
}
