//
//  SharedViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 2/10/24.
//

import Foundation
import CoreData

class DateViewModel: ObservableObject {
    @Published var selectedMonth: Date
    @Published var selectedDay: Date
    @Published var currentMonth: Date
    @Published var currentDay: Date
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
        
        let firstTransactionDate = getFirstTransactionDate()

        // Calculate the number of months between the first transaction date and the current date
        let monthDifference = calendar.dateComponents([.month], from: firstTransactionDate, to: currentDate).month!

        // Generate dates for all months between the first transaction date and today
        var allDates: [[Date]] = []
        for monthOffset in 0...monthDifference {
            var components = calendar.dateComponents([.year, .month], from: currentDate)
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
    
    func getFirstTransactionDate() -> Date {
        // Check if the first transaction date is already saved in the user defaults
        if let firstTransactionDate = UserDefaults.standard.object(forKey: "firstTransactionDate") as? Date {
            return firstTransactionDate
        }

        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        // Fetch all transactions from Core Data
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        do {
            let fetchedTransactions = try context.fetch(fetchRequest)
            if let firstTransaction = fetchedTransactions.first, let firstTransactionDate = firstTransaction.date {
                // Save the first transaction date to the user defaults
                UserDefaults.standard.set(firstTransactionDate, forKey: "firstTransactionDate")
                return firstTransactionDate
            }
        } catch {
            print("Failed to fetch transactions from Core Data: \(error)")
        }
        
        // If no transactions were found, return the current date
        return Date()
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
}
