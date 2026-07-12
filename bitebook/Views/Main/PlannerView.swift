import SwiftUI

struct MealCell: Identifiable {
    let id = UUID()

    let day: String
    let meal: String
}

struct MealCellView: View {
    let meal: String
    let day: String
    let food: String

    var body: some View {
        VStack {
            Text(food)
                .font(.caption)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 70
        )
        .background(.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MealEditorView: View {
    let meal: MealCell

    var body: some View {
        VStack {
            Text("\(meal.meal) - \(meal.day)")
                .font(.title)

            TextField("Meal", text: .constant(""))
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

struct PlannerView: View {
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let meals = ["Breakfast", "Lunch", "Dinner"]

    @State private var selectedMeal: MealCell?
    @State private var currentWeek = Date()

    private var isoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current

        return calendar
    }

    private var weekDates: [Date] {
        let startOfWeek = isoCalendar.date(
            from: isoCalendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: currentWeek)
        )!

        return (0..<7).compactMap {
            isoCalendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }

    let rowLabelWidth: CGFloat = 140

    var body: some View {
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
            ForEach(meals, id: \.self) { meal in
                GridRow {
                    Text(meal)
                        .fontWeight(.medium)
                        .frame(width: rowLabelWidth, alignment: .center)

                    ForEach(days, id: \.self) { day in
                        MealCellView(
                            meal: meal,
                            day: day,
                            food: "Add"
                        )
                        .onTapGesture {
                            selectedMeal = MealCell(
                                day: day,
                                meal: meal
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(item: $selectedMeal) { meal in
            MealEditorView(meal: meal)
        }
    }
}

#Preview {
    PlannerView()
}
