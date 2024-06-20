//
//  dateViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 2/10/24.
//

import Foundation
import CoreData

class DateViewModel: ObservableObject {
    @Published var selectedMonth: Date {
        didSet {
            updateSelectedMonthDates()
        }
    }
    @Published var selectedDay: Date
    @Published var currentMonth: Date
    @Published var currentDay: Date
    @Published var allTransactionDates: [[Date]] = []
    @Published var selectedMonthDates: [Date] = []

    let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    let calendar = Calendar.current

    init() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        currentMonth = currentMonthDate
        selectedMonth = currentMonthDate
        currentDay = currentDate
        selectedDay = currentDate

        // Populate dates arrays
        updateAllTransactionDates()
        updateSelectedMonthDates()
    }
    
    func updateAllTransactionDates() {
        var firstTransactionDate: Date
        if let date = UserDefaults.standard.object(forKey: "FirstTransactionDate") as? Date {
            // First transaction date is available in UserDefaults
            firstTransactionDate = date
        } else {
            // First transaction date is not available in UserDefaults
            // Fetch the first transaction date from the transaction history
            firstTransactionDate = getFirstTransactionDateFromTransactionHistory()
        }

        // Fetch the first transaction date from the newly added account
        let newFirstTransactionDate = getFirstTransactionDateFromTransactionHistory()

        // If the new first transaction date is older than the current first transaction date, update it
        if newFirstTransactionDate < firstTransactionDate {
            firstTransactionDate = newFirstTransactionDate
            UserDefaults.standard.set(firstTransactionDate, forKey: "FirstTransactionDate")
        }

        // Calculate the number of months between the first transaction date and the current date
        let firstTransactionComponents = calendar.dateComponents([.year, .month], from: firstTransactionDate)
        let currentComponents = calendar.dateComponents([.year, .month], from: Date())
        let monthDifference = (currentComponents.year! - firstTransactionComponents.year!) * 12 + (currentComponents.month! - firstTransactionComponents.month!)

        // Generate dates for all months between the first transaction date and today
        var allDates: [[Date]] = []
        for monthOffset in 0...monthDifference {
            var components = calendar.dateComponents([.year, .month], from: Date())
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
        allTransactionDates = allDates
    }

    func updateSelectedMonthDates() {
        selectedMonthDates = allTransactionDates
            .flatMap { $0 }
            .filter { calendar.isDate($0, equalTo: selectedMonth, toGranularity: .month) }
            .sorted { $0 < $1 }
    }
    
    func getFirstTransactionDateFromTransactionHistory() -> Date {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        // Fetch all transactions from Core Data
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "date != nil")

        do {
            let fetchedTransactions = try context.fetch(fetchRequest)
            if let firstTransaction = fetchedTransactions.first, let firstTransactionDate = firstTransaction.date {
                print("First transaction date from Core Data: \(firstTransactionDate)")
                
                // Store the first transaction date in UserDefaults for future use
                UserDefaults.standard.set(firstTransactionDate, forKey: "FirstTransactionDate")
                
                return firstTransactionDate
            }
        } catch {
            print("Failed to fetch transactions from Core Data: \(error)")
        }
        
        // If no transactions were found, return the current date
        print("No transactions found, returning current date")
        return Date()
    }

    func stringForDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
