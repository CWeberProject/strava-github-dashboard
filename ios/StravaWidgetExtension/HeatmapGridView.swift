import SwiftUI

struct HeatmapGridView: View {
    let gridDates: [Date?]
    let activityLevels: [String: Int]

    private let weeks = Constants.weeksToShow
    private let days = Constants.daysPerWeek
    private let cellSize = Constants.cellSize
    private let cellSpacing = Constants.cellSpacing

    var body: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<days, id: \.self) { day in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<weeks, id: \.self) { week in
                        let index = day * weeks + week
                        cellView(for: index)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(for index: Int) -> some View {
        if index < gridDates.count, let date = gridDates[index] {
            let dateStr = StravaRepository.formatDate(date)
            let levelValue = activityLevels[dateStr] ?? 0
            let level = ActivityLevel(rawValue: levelValue) ?? .none

            RoundedRectangle(cornerRadius: 2)
                .fill(level.color)
                .frame(width: cellSize, height: cellSize)
        } else {
            // Future date or nil - invisible placeholder
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.clear)
                .frame(width: cellSize, height: cellSize)
        }
    }
}

#Preview {
    HeatmapGridView(
        gridDates: StravaRepository.getGridDates(),
        activityLevels: [:]
    )
    .padding()
    .background(Color(hex: Constants.widgetBackgroundColor))
}
