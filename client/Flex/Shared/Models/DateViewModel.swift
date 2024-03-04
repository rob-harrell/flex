//
//  SharedViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 2/10/24.
//

import Foundation

class DateViewModel: ObservableObject {
    @Published var selectedMonth: Date
    @Published var selectedDay: Date
    @Published var currentMonth: Date
    @Published var currentDay: Date
    @Published var selectedMonthIndex: Int
    @Published var selectedDayIndex: Int
    @Published var dates: [[Date]] = []

    let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    let calendar = Calendar.current

    init() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        currentMonth = currentMonthDate
        selectedMonth = currentMonthDate
        let currentDayDate = currentDate
        currentDay = currentDayDate
        selectedDay = currentDayDate
        selectedMonthIndex = 11
        selectedDayIndex = calendar.component(.day, from: currentDate) - 1
        generateDatesForPastMonths()
    }
    
    func datesForSelectedMonth() -> [Date] {
        guard let monthIndex = dates.firstIndex(where: { calendar.isDate($0.first!, equalTo: selectedMonth, toGranularity: .month) }) else {
            return []
        }
        return dates[monthIndex]
    }

    func stringForDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    private func generateDatesForPastMonths() {
        let calendar = Calendar.current
        var allDates: [[Date]] = []

        for monthOffset in 0..<12 {
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.month = components.month! - monthOffset
            components.day = 1

            guard let firstDayOfMonth = calendar.date(from: components) else { continue }
            let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
            let daysCount = range.count

            var datesForMonth = [Date]()
            for day in 1...daysCount {
                components.day = day
                if let date = calendar.date(from: components) {
                    datesForMonth.append(date)
                }
            }
            allDates.insert(datesForMonth, at: 0)
        }
        dates = allDates
    }
}
