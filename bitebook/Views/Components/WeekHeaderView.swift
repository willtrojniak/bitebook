import SwiftUI

struct WeekHeaderView: View {
    @Binding var currentWeek: Date
    var weekDates: [Date]

    func previousWeek() {
        currentWeek = Calendar.current.date(
            byAdding: .weekOfYear,
            value: -1,
            to: currentWeek
        )!
    }

    func nextWeek() {
        currentWeek = Calendar.current.date(
            byAdding: .weekOfYear,
            value: 1,
            to: currentWeek
        )!
    }

    private var weekTitle: String {
        guard
            let firstDay = weekDates.first,
            let lastDay = weekDates.last
        else {
            return ""
        }

        let calendar = Calendar.current

        let firstMonth = firstDay.formatted(.dateTime.month(.abbreviated))
        let lastMonth = lastDay.formatted(.dateTime.month(.abbreviated))

        let firstYear = calendar.component(.year, from: firstDay)
        let lastYear = calendar.component(.year, from: lastDay)

        if firstMonth == lastMonth {
            return "\(firstMonth) \(firstYear)"
        }

        if firstYear == lastYear {
            return "\(firstMonth) - \(lastMonth) \(firstYear)"
        }

        return "\(firstMonth) \(firstYear) - \(lastMonth) \(lastYear)"
    }

    var body: some View {

        HStack(spacing: 12) {
            Button("Today") { currentWeek = Date() }

            HStack(spacing: 4) {
                Button {
                    previousWeek()
                } label: {
                    Image(systemName: "chevron.left")
                }

                Button {
                    nextWeek()
                } label: {
                    Image(systemName: "chevron.right")
                }
            }

            Text(weekTitle)
                .font(.title2)
        }
    }
}
