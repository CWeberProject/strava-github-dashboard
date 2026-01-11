import SwiftUI

struct HeatmapGridView: View {
    let activityLevels: [String: Int]

    private let days = Constants.daysPerWeek
    private let spacing: CGFloat = 3.0

    var body: some View {
        GeometryReader { geometry in
            // Calculate cell size based on height (7 rows must fit)
            let availableHeight = geometry.size.height - (CGFloat(days - 1) * spacing)
            let cellSize = availableHeight / CGFloat(days)

            // Calculate how many columns fit in the width
            let availableWidth = geometry.size.width
            let weeks = max(1, Int((availableWidth + spacing) / (cellSize + spacing)))

            // Get grid dates for calculated number of weeks
            let gridDates = StravaRepository.getGridDates(weeks: weeks)

            // Calculate actual grid dimensions for centering
            let gridWidth = (cellSize * CGFloat(weeks)) + (spacing * CGFloat(weeks - 1))
            let gridHeight = (cellSize * CGFloat(days)) + (spacing * CGFloat(days - 1))

            VStack(spacing: spacing) {
                ForEach(0..<days, id: \.self) { day in
                    HStack(spacing: spacing) {
                        ForEach(0..<weeks, id: \.self) { week in
                            let index = day * weeks + week
                            cellView(for: index, size: cellSize, gridDates: gridDates)
                        }
                    }
                }
            }
            .frame(width: gridWidth, height: gridHeight)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    @ViewBuilder
    private func cellView(for index: Int, size: CGFloat, gridDates: [Date?]) -> some View {
        if index < gridDates.count, let date = gridDates[index] {
            let dateStr = StravaRepository.formatDate(date)
            let levelValue = activityLevels[dateStr] ?? 0
            let level = ActivityLevel(rawValue: levelValue) ?? .none

            RoundedRectangle(cornerRadius: 2)
                .fill(level.color)
                .frame(width: size, height: size)
        } else {
            // Future date or nil - invisible placeholder
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.clear)
                .frame(width: size, height: size)
        }
    }
}

#Preview {
    HeatmapGridView(activityLevels: [:])
        .frame(width: 150, height: 150)
        .padding()
        .background(Color(hex: Constants.widgetBackgroundColor))
}
