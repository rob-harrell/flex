//
//  BudgetViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import Foundation
import SwiftUI
import CoreData
import SwiftCSV
import KeychainAccess


class BudgetViewModel: ObservableObject {
    //Monthly budget metrics
    @Published var selectedMonthTransactions: [Date: [TransactionViewModel]] = [:]
    @Published var selectedMonthFixedSpendPerDay: [Date: Double] = [:]
    @Published var selectedMonthFlexSpendPerDay: [Date: Double] = [:]
    @Published var selectedMonthIncomePerDay: [Date: Double] = [:]
    @Published var selectedMonthFixedSpend: Double = 0.0
    @Published var selectedMonthFlexSpend: Double = 0.0
    @Published var selectedMonthIncome: Double = 1

    //Income breakdown metrics
    @Published var recentWorkIncome: Double = 0
    @Published var recentBenefitsIncome: Double = 0
    @Published var recentAccrualsIncome: Double = 0
    @Published var recentPensionIncome: Double = 0
    @Published var totalRecentIncome: Double = 0
    
    @Published var isCalculatingMetrics = false
    
    //Fixed spend breakdown metrics
    @Published var recentHousingCosts: Double = 0
    @Published var recentInsuranceCosts: Double = 0
    @Published var recentStudentLoans: Double = 0
    @Published var recentOtherLoans: Double = 0
    @Published var recentCarPayment: Double = 0
    @Published var recentGasAndElectrical: Double = 0
    @Published var recentInternetAndCable: Double = 0
    @Published var recentSewageAndWaste: Double = 0
    @Published var recentPhoneBill: Double = 0
    @Published var recentWaterBill: Double = 0
    @Published var recentOtherUtilities: Double = 0
    @Published var recentStorageCosts: Double = 0
    @Published var recentNursingCosts: Double = 0
    @Published var totalRecentFixedSpend: Double = 0
    
    //Day cell visual arrays
    @Published var budgetCurvePoints: [Date: [CGFloat]] = [:]
    @Published var isDayOverBudget: [Date: Bool] = [:]
    @Published var remainingDailyFlex: Double = 0.0
    @Published var remainingBudgetHeight: Double = 0.0
    @Published var selectedMonthAvgFlexSpend: Double = 0.0
    @Published var avgFlexSpendHeight: Double = 0.0
    
    struct TransactionViewModel {
        var id: Int64
        var amount: Double
        var budgetCategory: String
        var category: String
        var subCategory: String
        var currencyCode: String
        var date: Date
        var isRemoved: Bool
        var name: String
        var pending: Bool
        var productCategory: String
        var merchantName: String
        var fixedAmount: Int16
        var logoURL: String
    }
    
    //MARK core
    enum CoreDataError: Error {
        case userNotFound
        case accountNotFound
        case transactionNotFound
    }
    
    func fetchTransactionsFromCoreData(from startDate: Date, to endDate: Date) -> [TransactionViewModel] {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        // Fetch transactions from Core Data that fall within the date range
        fetchRequest.predicate = NSPredicate(format: "(date >= %@) AND (date <= %@)", startDate as NSDate, endDate as NSDate)

        do {
            let fetchedTransactions = try context.fetch(fetchRequest)
            let transactionViewModels = fetchedTransactions.map { transaction in
                return TransactionViewModel(
                    id: transaction.id,
                    amount: transaction.amount,
                    budgetCategory: transaction.budgetCategory ?? "", // provide a default value
                    category: transaction.category ?? "", // provide a default value
                    subCategory: transaction.subCategory ?? "", // provide a default value
                    currencyCode: transaction.currencyCode ?? "", // provide a default value
                    date: transaction.date ?? Date(), // use the date in GMT
                    isRemoved: transaction.isRemoved,
                    name: transaction.name ?? "", // provide a default value
                    pending: transaction.pending,
                    productCategory: transaction.productCategory ?? "", // provide a default value
                    merchantName: transaction.merchantName ?? "", // provide a default value
                    fixedAmount: transaction.fixedAmount,
                    logoURL: transaction.logoURL ?? ""
                )
            }
            return transactionViewModels
        } catch {
            print("Failed to fetch transactions from Core Data: \(error)")
            return []
        }
    }
    
    func saveTransactionsToCoreData(_ transactions: [TransactionResponse], userId: Int64) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        if let timeZone = TimeZone(secondsFromGMT: 0) {
            dateFormatter.timeZone = timeZone
        } else {
            print("Failed to create GMT timezone")
        }
        
        // Create a DateComponents object with the desired time of day
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM GMT
        dateComponents.minute = 0
        dateComponents.second = 0
        
        // Create a Calendar object
        var calendar = Calendar.current
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timeZone
        } else {
            print("Failed to create GMT timezone")
        }
            
        for transactionResponse in transactions {
            if transactionResponse.name == "Returned Payment" {
                print("Skipped transaction with name: \(transactionResponse.name)")
                continue
            }
            let transaction = Transaction(context: context)
            transaction.id = transactionResponse.id
            transaction.amount = transactionResponse.amount
            transaction.category = transactionResponse.category
            transaction.subCategory = transactionResponse.subCategory
            transaction.currencyCode = transactionResponse.currencyCode
            transaction.isRemoved = transactionResponse.isRemoved
            transaction.name = transactionResponse.name
            transaction.pending = transactionResponse.pending
            transaction.merchantName = transactionResponse.merchantName
            transaction.logoURL = transactionResponse.logoURL
            transaction.productCategory = transactionResponse.productCategory
            transaction.budgetCategory = transactionResponse.budgetCategory
            
            if let authorizedDateString = transactionResponse.authorizedDate {
                guard let authDateAsDate = dateFormatter.date(from: authorizedDateString) else {
                    print("Invalid authorized date: \(authorizedDateString)")
                    continue
                }
                // Get the date components of the authorized date
                var authDateComponents = calendar.dateComponents([.year, .month, .day], from: authDateAsDate)
                // Set the time of the transaction date to 8 PM GMT
                authDateComponents.hour = dateComponents.hour
                authDateComponents.minute = dateComponents.minute
                authDateComponents.second = dateComponents.second
                // Create the transaction date from the date components
                transaction.date = calendar.date(from: authDateComponents)
            } else {
                guard let dateAsDate = dateFormatter.date(from: transactionResponse.date) else {
                    print("Invalid date: \(transactionResponse.date)")
                    continue
                }
                // Get the date components of the transaction date
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: dateAsDate)
                // Set the time of the transaction date to 8 PM GMT
                dateComponents.hour = dateComponents.hour
                dateComponents.minute = dateComponents.minute
                dateComponents.second = dateComponents.second
                // Create the transaction date from the date components
                transaction.date = calendar.date(from: dateComponents)
                print("authorizedDate is nil, using transaction date instead")
            }

            // Get the User from userId
            let userFetchRequest: NSFetchRequest<User> = User.fetchRequest()
            userFetchRequest.predicate = NSPredicate(format: "id == %lld", userId)

            do {
                let users = try context.fetch(userFetchRequest)
                guard let user = users.first else {
                    throw CoreDataError.userNotFound
                }
                transaction.user = user

                // Get the Account from the account ID in the TransactionResponse
                let accountFetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
                accountFetchRequest.predicate = NSPredicate(format: "id == %lld", transactionResponse.accountId)

                let accounts = try context.fetch(accountFetchRequest)
                if let account = accounts.first {
                    transaction.account = account
                } else {
                    print("No account found in Core Data for ID: \(transactionResponse.accountId)")
                    throw CoreDataError.accountNotFound
                }
            } catch {
                print("Failed to fetch user or account from Core Data: \(error)")
                return
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save transactions to Core Data: \(error)")
        }
    }
    
    func modifyTransactionsInCoreData(_ transactions: [TransactionResponse], userId: Int64) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let timeZone = TimeZone(secondsFromGMT: 0) {
            dateFormatter.timeZone = timeZone
        } else {
            print("Failed to create GMT timezone")
        }

        // Create a DateComponents object with the desired time of day
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM GMT
        dateComponents.minute = 0
        dateComponents.second = 0

        // Create a Calendar object
        var calendar = Calendar.current
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timeZone
        } else {
            print("Failed to create GMT timezone")
        }

        for transactionResponse in transactions {
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %lld", transactionResponse.id)

            do {
                let fetchedTransactions = try context.fetch(fetchRequest)
                guard let transaction = fetchedTransactions.first else {
                    throw CoreDataError.transactionNotFound
                }

                // Update the properties of the transaction
                transaction.amount = transactionResponse.amount
                transaction.category = transactionResponse.category
                transaction.subCategory = transactionResponse.subCategory
                transaction.currencyCode = transactionResponse.currencyCode
                transaction.isRemoved = transactionResponse.isRemoved
                transaction.name = transactionResponse.name
                transaction.pending = transactionResponse.pending
                transaction.merchantName = transactionResponse.merchantName
                transaction.logoURL = transactionResponse.logoURL
                transaction.productCategory = transactionResponse.productCategory
                transaction.budgetCategory = transactionResponse.budgetCategory

                if let authorizedDateString = transactionResponse.authorizedDate {
                    guard let authDateAsDate = dateFormatter.date(from: authorizedDateString) else {
                        print("Invalid authorized date: \(authorizedDateString)")
                        continue
                    }
                    // Get the date components of the authorized date
                    var authDateComponents = calendar.dateComponents([.year, .month, .day], from: authDateAsDate)
                    // Set the time of the transaction date to 8 PM GMT
                    authDateComponents.hour = dateComponents.hour
                    authDateComponents.minute = dateComponents.minute
                    authDateComponents.second = dateComponents.second
                    // Create the transaction date from the date components
                    transaction.date = calendar.date(from: authDateComponents)
                } else {
                    guard let dateAsDate = dateFormatter.date(from: transactionResponse.date) else {
                        print("Invalid date: \(transactionResponse.date)")
                        continue
                    }
                    // Get the date components of the transaction date
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: dateAsDate)
                    // Set the time of the transaction date to 8 PM GMT
                    dateComponents.hour = dateComponents.hour
                    dateComponents.minute = dateComponents.minute
                    dateComponents.second = dateComponents.second
                    // Create the transaction date from the date components
                    transaction.date = calendar.date(from: dateComponents)
                    print("authorizedDate is nil, using transaction date instead")
                }
            } catch {
                print("Failed to fetch or modify transaction from Core Data: \(error)")
                return
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save modified transactions to Core Data: \(error)")
        }
    }
    
    func removeTransactionsFromCoreData(_ transactions: [TransactionResponse], userId: Int64) {
        let context = CoreDataStack.shared.persistentContainer.viewContext

        for transactionResponse in transactions {
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %lld", transactionResponse.id)

            do {
                let fetchedTransactions = try context.fetch(fetchRequest)
                guard let transaction = fetchedTransactions.first else {
                    throw CoreDataError.transactionNotFound
                }

                // Delete the transaction
                context.delete(transaction)
            } catch {
                print("Failed to fetch or remove transaction from Core Data: \(error)")
                return
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save changes after removing transactions from Core Data: \(error)")
        }
    }
        
    
    //MARK server
    
    //Call every time user opens app or adds a new account
    func fetchNewTransactionsFromServer(userId: Int64, completion: @escaping (Bool) -> Void) {
        //print("fetchNewTransactionsFromServer started")
        let keychain = Keychain(service: "robharrell.Flex")
        let sessionToken = keychain["sessionToken"] ?? ""

        let path = "/budget/get_new_transactions_for_user/\(userId)"
        ServerCommunicator.shared.callMyServer(
            path: path,
            httpMethod: .get,
            sessionToken: sessionToken
        ) { (result: Result<TransactionsResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let transactionsResponse):
                DispatchQueue.main.async {
                    print("fetchNewTransactionsFromServer success")
                    if !transactionsResponse.added.isEmpty {
                        self.saveTransactionsToCoreData(transactionsResponse.added, userId: userId)
                    }
                    if !transactionsResponse.modified.isEmpty {
                        self.modifyTransactionsInCoreData(transactionsResponse.modified, userId: userId)
                    }
                    if !transactionsResponse.removed.isEmpty {
                        self.removeTransactionsFromCoreData(transactionsResponse.removed, userId: userId)
                    }
                    completion(true)
                }
            case .failure(let error):
                print("Failed to fetch user data from server: \(error)")
                completion(false)
            }
        }
    }
    
    //Call every time user opens app in case user has switched device
    func fetchTransactionHistoryFromServer(userId: Int64, bankAccounts: [UserViewModel.BankAccount], completion: @escaping (Bool) -> Void) {
        print("fetchTransactionHistoryFromServer started")
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let dispatchGroup = DispatchGroup()

        for bankAccount in bankAccounts {
            let transactionFetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            transactionFetchRequest.predicate = NSPredicate(format: "account.id == %lld", bankAccount.id)

            do {
                let transactions = try context.fetch(transactionFetchRequest)
                if transactions.isEmpty {
                    dispatchGroup.enter()

                    let path = "/budget/get_transaction_history_for_account/\(bankAccount.id)"
                    let keychain = Keychain(service: "robharrell.Flex")
                    let sessionToken = keychain["sessionToken"] ?? ""

                    ServerCommunicator.shared.callMyServer(
                        path: path,
                        httpMethod: .get,
                        sessionToken: sessionToken
                    ) { (result: Result<TransactionHistoryResponse, ServerCommunicator.Error>) in
                        switch result {
                        case .success(let transactionsResponse):
                            DispatchQueue.main.async {
                                print("fetchTransactionHistoryFromServer success for account \(bankAccount.id)")
                                if !transactionsResponse.isEmpty {
                                    self.saveTransactionsToCoreData(transactionsResponse, userId: userId)
                                }
                                dispatchGroup.leave()
                            }
                        case .failure(let error):
                            print("Failed to fetch transaction history from server: \(error)")
                            dispatchGroup.leave()
                        }
                    }
                }
            } catch {
                print("Failed to fetch accounts from Core Data: \(error)")
            }
        }
        dispatchGroup.notify(queue: .main) {
            UserDefaults.standard.set(true, forKey: "hasFetchedFullTransactionHistory")
            completion(true)
        }
    }
    
    //Mark business logic
    func calculateSelectedMonthBudgetMetrics(for month: Date, monthlyIncome: Double, monthlyFixedSpend: Double) {
        print("starting calculating budget metrics")
        // Reset selectedMonthFlexSpend, selectedMonthIncome, and selectedMonthFixedSpend to zero
        self.selectedMonthFlexSpend = 0.0
        self.selectedMonthIncome = 0.0
        self.selectedMonthFixedSpend = 0.0
        self.selectedMonthFlexSpendPerDay = [:]
        self.selectedMonthIncomePerDay = [:]
        self.selectedMonthFixedSpendPerDay = [:]

        // Create a date range for the given month
        let calendar = Calendar.current
        var startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        // Get the number of days in the month
        let range = calendar.range(of: .day, in: .month, for: month)!
        let numDays = range.count

        // Adjust the start of the month to start from the beginning of the day in GMT
        startOfMonth = calendar.startOfDay(for: startOfMonth)
        
        // Fetch transactions from Core Data for the given month
        let selectedMonthTransactionsList = self.fetchTransactionsFromCoreData(from: startOfMonth, to: endOfMonth)

        // Group transactions by date
        self.selectedMonthTransactions = Dictionary(grouping: selectedMonthTransactionsList, by: {
            // Convert the date of the transaction to the user's local timezone
            let userLocalDate = Calendar.current.startOfDay(for: $0.date)
            return userLocalDate
        }).mapValues { transactions in
            // Sort transactions by date and time in ascending order
            transactions.sorted { $0.date < $1.date }
        }
        
        // Calculate total fixed spending for the month
        self.selectedMonthFixedSpend = selectedMonthTransactions.values
            .flatMap { $0 }
            .filter { $0.budgetCategory == "Fixed" }
            .map { $0.amount }
            .reduce(0, +)
        
        // Calculate total budget for the month
        let flexBudget = monthlyIncome - max(monthlyFixedSpend, selectedMonthFixedSpend)
        
        // Initialize cumulative spend
        var cumulativeSpend = 0.0
       
        for day in 1...numDays {
            let dateComponents = DateComponents(year: calendar.component(.year, from: month), month: calendar.component(.month, from: month), day: day)
            if let date = calendar.date(from: dateComponents) {
                let userLocalDate = calendar.startOfDay(for: date)
                var totalFixedSpend = 0.0
                var totalFlexSpend = 0.0
                var totalIncome = 0.0

                if let transactions = selectedMonthTransactions[userLocalDate] {
                    for transaction in transactions {
                        switch transaction.budgetCategory {
                        case "Fixed":
                            totalFixedSpend += transaction.amount
                        case "Flex":
                            totalFlexSpend += transaction.amount
                        case "Income":
                            totalIncome += abs(transaction.amount)
                        default:
                            break
                        }
                    }
                    // Add total spend to cumulative spend
                    cumulativeSpend += totalFlexSpend
                }

                self.selectedMonthFixedSpendPerDay[userLocalDate] = totalFixedSpend
                self.selectedMonthFlexSpendPerDay[userLocalDate] = totalFlexSpend
                self.selectedMonthIncomePerDay[userLocalDate] = totalIncome
                // Check if cumulative spend exceeds total budget
                self.isDayOverBudget[userLocalDate] = cumulativeSpend > flexBudget
            }
        }

        // Calculate total fixed and flexible spending and income for the month
        self.selectedMonthFlexSpend = self.selectedMonthFlexSpendPerDay.values.reduce(0, +)
        self.selectedMonthIncome = self.selectedMonthIncomePerDay.values.reduce(0, +)
                        
        // Call prepareBezierPathInputs after flexSpendPerDay is populated
        let spendPerDay = self.selectedMonthFlexSpendPerDay.mapValues { CGFloat($0) }
        self.budgetCurvePoints = prepareBudgetCurveInputs(spendPerDay: spendPerDay, exponent: 0.5)
        
        // Use for remaining budget curve height
        let maxDayFlexSpend = max(spendPerDay.values.max() ?? 1.0, 1.0)
        let currentDayOfMonth = calendar.component(.day, from: Date())
        let remainingDaysInMonth = range.count - currentDayOfMonth
        let remainingFlex = monthlyIncome - max(monthlyFixedSpend, selectedMonthFixedSpend) - self.selectedMonthFlexSpend
        self.selectedMonthAvgFlexSpend = self.selectedMonthFlexSpend / Double(currentDayOfMonth)
        self.avgFlexSpendHeight = self.selectedMonthAvgFlexSpend / maxDayFlexSpend
        self.remainingDailyFlex = remainingFlex / Double(remainingDaysInMonth)
        self.remainingBudgetHeight = max(remainingDailyFlex / Double(maxDayFlexSpend), 0.0)
       
        self.isCalculatingMetrics = false
        print("finished calculating budget metrics")

    }
    
    func calculateRecentBudgetStats() {
        // Get transactions for past month up until yesterday
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let startOfLastMonthFromYesterday = calendar.date(byAdding: .month, value: -1, to: yesterday)!
        let recentTransactions = self.fetchTransactionsFromCoreData(from: startOfLastMonthFromYesterday, to: yesterday)

        for transaction in recentTransactions {
            switch transaction.productCategory {
            case "Paycheck":
                self.recentWorkIncome += abs(transaction.amount)
            case "Benefits":
                self.recentBenefitsIncome += abs(transaction.amount)
            case "Dividends & Interest":
                self.recentAccrualsIncome += abs(transaction.amount)
            case "Pension":
                self.recentPensionIncome += abs(transaction.amount)
            case "Housing":
                self.recentHousingCosts += transaction.amount
            case "Insurance":
                self.recentInsuranceCosts += transaction.amount
            case "Sudent Loan":
                self.recentStudentLoans += transaction.amount
            case "Other Loans":
                self.recentOtherLoans += transaction.amount
            case "Auto Loan":
                self.recentCarPayment += transaction.amount
            case "Gas & Electricity":
                self.recentGasAndElectrical += transaction.amount
            case "Internet & Cable":
                self.recentInternetAndCable += transaction.amount
            case "Sewage & Waste Management":
                self.recentSewageAndWaste += transaction.amount
            case "Phone Bill":
                self.recentPhoneBill += transaction.amount
            case "Water Bill":
                self.recentWaterBill += transaction.amount
            case "Other Utilities":
                self.recentOtherUtilities += transaction.amount
            case "Storage":
                self.recentStorageCosts += transaction.amount
            case "Nursing Care":
                self.recentNursingCosts += transaction.amount
                
            default:
                break
            }
        }

        // Calculate recent income averages
        self.totalRecentIncome = abs(self.recentWorkIncome + self.recentBenefitsIncome + self.recentAccrualsIncome + self.recentPensionIncome)
        
        print("avgRecentWorkIncome \(self.recentWorkIncome)")
        print("avgTotalRecentIncome \(self.totalRecentIncome)")

        //Calculate recent fixed spend averages
        self.recentHousingCosts = recentHousingCosts
        self.recentInsuranceCosts = recentInsuranceCosts / 2
        self.recentStudentLoans = recentStudentLoans / 2
        self.recentOtherLoans = recentOtherLoans / 2
        self.recentCarPayment = recentCarPayment / 2
        self.recentGasAndElectrical = recentGasAndElectrical / 2
        self.recentInternetAndCable = recentInternetAndCable / 2
        self.recentSewageAndWaste = recentSewageAndWaste / 2
        self.recentPhoneBill = recentPhoneBill / 2
        self.recentWaterBill = recentWaterBill / 2
        self.recentOtherUtilities = recentOtherUtilities / 2
        self.recentStorageCosts = recentStorageCosts / 2
        self.recentNursingCosts = recentNursingCosts / 2
        self.totalRecentFixedSpend = (self.recentHousingCosts + self.recentInsuranceCosts + self.recentStudentLoans + self.recentOtherLoans + self.recentCarPayment + self.recentGasAndElectrical + self.recentInternetAndCable + self.recentSewageAndWaste + self.recentPhoneBill + self.recentWaterBill + self.recentOtherUtilities + self.recentStorageCosts + self.recentNursingCosts)

    }
    
    func prepareBudgetCurveInputs(spendPerDay: [Date: CGFloat], exponent: CGFloat) -> [Date: [CGFloat]] {
        // Normalize the spend amounts with power transformation
        guard let maxSpend = spendPerDay.values.max(), maxSpend > 0 else {
            return spendPerDay.mapValues { _ in [CGFloat(0), CGFloat(0), CGFloat(0)] }
        }

        let normalizedData = spendPerDay.mapValues { value in
            let nonNegativeValue = max(value, 0)
            return pow(nonNegativeValue / maxSpend, exponent)
        }

        // Prepare the data points for each day
        var dataPointsPerDay: [Date: [CGFloat]] = [:]

        let sortedDates = spendPerDay.keys.sorted()

        for i in 0..<sortedDates.count {
            let date = sortedDates[i]
            var firstPoint: CGFloat
            let secondPoint = normalizedData[date]!
            var thirdPoint: CGFloat

            if i == 0 {
                firstPoint = secondPoint
            } else {
                firstPoint = (normalizedData[sortedDates[i - 1]]! + secondPoint) / 2
            }

            if i == sortedDates.count - 1 {
                thirdPoint = secondPoint
            } else {
                thirdPoint = (secondPoint + normalizedData[sortedDates[i + 1]]!) / 2
            }

            dataPointsPerDay[date] = [firstPoint, secondPoint, thirdPoint]
        }
        return dataPointsPerDay
    }
}
