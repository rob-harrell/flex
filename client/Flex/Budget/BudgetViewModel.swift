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
    @Published var selectedMonthTransactions: [TransactionViewModel] = [] //Holds the selected month's transactions for use in calulating budget metrics
    @Published var budgetPreferences: [BudgetPreferenceViewModel] = [] //To be used in the future
    @Published var selectedMonthFixedSpendPerDay: [Date: Double] = [:] //Holds selected month's fixed spend for use in budget metrics and calendar view
    @Published var selectedMonthFlexSpendPerDay: [Date: Double] = [:] //Holds selected month's income for use in budget metrics and calendar view
    @Published var selectedMonthIncomePerDay: [Date: Double] = [:] //Holds selected month's income for use in budget metrics and calendar view
    @Published var selectedMonthFixedSpend: Double = 0.0 //The selected month's fixed spend ***need to update calculation*** --> change to double
    @Published var selectedMonthFlexSpend: Double = 0.0 //The selected month's flex spend ***need to consolidate with flexspendmonthtodate*** --> change to double
    @Published var selectedMonthIncome: Double = 0.0 //The selected month's income --> change to double
    @Published var selectedMonthSavings: Double = 0.0 //Selected month's savings --> change to double

    //Income breakdown metrics
    @Published var workMonthlyIncome: [Date: Double] = [:] //needs to be populated by fetching transactions from core for previous two full months #####
    @Published var benefitsMonthlyIncome: [Date: Double] = [:] //same as above
    @Published var accrualsMonthlyIncome: [Date: Double] = [:] //same as above
    @Published var pensionMonthlyIncome: [Date: Double] = [:]//same as above
    @Published var avgRecentWorkIncome: Double = 0 //same as above
    @Published var avgRecentBenefitsIncome: Double = 0 //same as above
    @Published var avgRecentAccrualsIncome: Double = 0 //same as above
    @Published var avgRecentPensionIncome: Double = 0 //same as above
    @Published var avgTotalRecentIncome: Double = 0 //same as above
    
    @Published var isCalculatingMetrics = false
    
    //Fixed spend breakdown metrics
    
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
    
    struct BudgetPreferenceViewModel: Decodable {
        var id: Int64?
        var category: String
        var subCategory: String
        var productCategory: String
        var budgetCategory: String
        var fixedAmount: Int16?
        
        //for core
        init(from budgetPreference: BudgetPreference) {
            self.id = budgetPreference.id
            self.category = budgetPreference.category ?? ""
            self.subCategory = budgetPreference.subCategory ?? ""
            self.productCategory = budgetPreference.productCategory ?? ""
            self.budgetCategory = budgetPreference.budgetCategory ?? ""
            self.fixedAmount = budgetPreference.fixedAmount
        }
        
        //for json
        init(category: String, subCategory: String, productCategory: String, budgetCategory: String) {
            self.category = category
            self.subCategory = subCategory
            self.productCategory = productCategory
            self.budgetCategory = budgetCategory
        }
        
        //for server
        init(from budgetPreferenceResponse: BudgetPreferenceResponse) {
            self.id = budgetPreferenceResponse.id
            self.category = budgetPreferenceResponse.category
            self.subCategory = budgetPreferenceResponse.subCategory
            self.productCategory = budgetPreferenceResponse.productCategory
            self.budgetCategory = budgetPreferenceResponse.budgetCategory
            self.fixedAmount = budgetPreferenceResponse.fixedAmount
        }
    }
        
    //Mark init
    func loadDefaultBudgetPreferencesFromJSON() -> [BudgetPreferenceViewModel]? {
        if let url = Bundle.main.url(forResource: "DefaultBudgetPreferences", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode([BudgetPreferenceViewModel].self, from: data)
                return decodedData.map { BudgetPreferenceViewModel(category: $0.category, subCategory: $0.subCategory, productCategory: $0.productCategory, budgetCategory: $0.budgetCategory) }
            } catch {
                print("Failed to load default budget preferences from JSON: \(error)")
            }
        }

        return nil
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
                TransactionViewModel(
                    id: transaction.id,
                    amount: transaction.amount,
                    budgetCategory: transaction.budgetCategory ?? "", // provide a default value
                    category: transaction.category ?? "", // provide a default value
                    subCategory: transaction.subCategory ?? "", // provide a default value
                    currencyCode: transaction.currencyCode ?? "", // provide a default value
                    date: transaction.date ?? Date(), // provide a default value
                    isRemoved: transaction.isRemoved,
                    name: transaction.name ?? "", // provide a default value
                    pending: transaction.pending,
                    productCategory: transaction.productCategory ?? "", // provide a default value
                    merchantName: transaction.merchantName ?? "", // provide a default value
                    fixedAmount: transaction.fixedAmount,
                    logoURL: transaction.logoURL ?? ""
                )
            }
            print("fetched transactions from core data from: \(startDate) to: \(endDate)")
            return transactionViewModels
        } catch {
            print("Failed to fetch transactions from Core Data: \(error)")
            return []
        }
    }
    
    func saveTransactionsToCoreData(_ transactions: [TransactionResponse], userId: Int64, monthlyIncome: Double, monthlyFixedSpend: Double) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
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
            
            if let authorizedDateString = transactionResponse.authorizedDate {
                guard let authDateAsDate = dateFormatter.date(from: authorizedDateString) else {
                    print("Invalid authorized date: \(authorizedDateString)")
                    continue
                }
                transaction.date = authDateAsDate
            } else {
                guard let dateAsDate = dateFormatter.date(from: transactionResponse.date) else {
                    print("Invalid date: \(transactionResponse.date)")
                    continue
                }
                transaction.date = dateAsDate
                print("authorizedDate is nil, using transaction date instead")
            }
            
            // Assign productCategory and budgetCategory from budgetPreferences
            if transactionResponse.merchantName == "Venmo" {
                transaction.productCategory = "Payment apps"
                transaction.budgetCategory = transactionResponse.amount < 0 ? "Income" : "Flex"
            } else if transactionResponse.merchantName == "Zelle" {
                transaction.productCategory = "Payment apps"
                transaction.budgetCategory = transactionResponse.amount < 0 ? "Income" : "Flex"
            } else if transactionResponse.merchantName == "Airbnb" {
                if transaction.amount < 0 {
                    transaction.budgetCategory = "Income"
                }
            }  else if let budgetPreference = budgetPreferences.first(where: { $0.category == transaction.category && $0.subCategory == transaction.subCategory }) {
                transaction.productCategory = budgetPreference.productCategory
                transaction.budgetCategory = budgetPreference.budgetCategory
                transaction.fixedAmount = budgetPreference.fixedAmount ?? transaction.fixedAmount
            } else {
                // Assign default values or leave as is
                transaction.productCategory = "Other"
                transaction.budgetCategory = "Flex"
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
            let currentMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
            self.calculateSelectedMonthBudgetMetrics(for: currentMonth, monthlyIncome: monthlyIncome, monthlyFixedSpend: monthlyFixedSpend)
        } catch {
            print("Failed to save transactions to Core Data: \(error)")
        }
    }
    
    func modifyTransactionsInCoreData(_ transactions: [TransactionResponse], userId: Int64, monthlyIncome: Double, monthlyFixedSpend: Double) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

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
                if transactionResponse.category == "INCOME" {
                    transaction.amount = -transaction.amount
                }
                transaction.category = transactionResponse.category
                transaction.subCategory = transactionResponse.subCategory
                transaction.currencyCode = transactionResponse.currencyCode
                transaction.isRemoved = transactionResponse.isRemoved
                transaction.name = transactionResponse.name
                transaction.pending = transactionResponse.pending
                transaction.merchantName = transactionResponse.merchantName
                transaction.logoURL = transactionResponse.logoURL
                
                if let authorizedDateString = transactionResponse.authorizedDate {
                    guard let authDateAsDate = dateFormatter.date(from: authorizedDateString) else {
                        print("Invalid authorized date: \(authorizedDateString)")
                        continue
                    }
                    transaction.date = authDateAsDate
                } else {
                    guard let dateAsDate = dateFormatter.date(from: transactionResponse.date) else {
                        print("Invalid date: \(transactionResponse.date)")
                        continue
                    }
                    transaction.date = dateAsDate
                    print("authorizedDate is nil, using transaction date instead")
                }

                // Update the productCategory and budgetCategory from budgetPreferences
                if let budgetPreference = budgetPreferences.first(where: { $0.category == transaction.category && $0.subCategory == transaction.subCategory }) {
                    transaction.productCategory = budgetPreference.productCategory
                    transaction.budgetCategory = budgetPreference.budgetCategory
                    transaction.fixedAmount = budgetPreference.fixedAmount ?? transaction.fixedAmount
                } else {
                    // Assign default values or leave as is
                    transaction.productCategory = "Other"
                    transaction.budgetCategory = "Flex"
                }
            } catch {
                print("Failed to fetch or modify transaction from Core Data: \(error)")
                return
            }
        }

        do {
            try context.save()
            let currentMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
            self.calculateSelectedMonthBudgetMetrics(for: currentMonth, monthlyIncome: monthlyIncome, monthlyFixedSpend: monthlyFixedSpend)
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
    
    func fetchBudgetPreferencesFromCoreData() {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<BudgetPreference> = BudgetPreference.fetchRequest()

        do {
            let fetchedBudgetPreferences = try context.fetch(fetchRequest)
            budgetPreferences = fetchedBudgetPreferences.map { BudgetPreferenceViewModel(from: $0) }
            print("Fetched budget preferences from Core Data")
        } catch {
            print("Failed to fetch budget preferences from Core Data: \(error)")
        }
    }
    
    func saveBudgetPreferencesToCoreData(_ budgetPreferences: [BudgetPreferenceViewModel], userId: Int64) {
        let context = CoreDataStack.shared.persistentContainer.viewContext

        // Fetch the User from Core Data
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %lld", userId)

        do {
            let users = try context.fetch(fetchRequest)

            // If the User exists, create the BudgetPreference entities and establish the relationship
            if let user = users.first {
                for budgetPreferenceResponse in budgetPreferences {
                    let budgetPreference = BudgetPreference(context: context)
                    budgetPreference.id = budgetPreferenceResponse.id ?? 0 // Provide a default value
                    budgetPreference.category = budgetPreferenceResponse.category
                    budgetPreference.subCategory = budgetPreferenceResponse.subCategory
                    budgetPreference.budgetCategory = budgetPreferenceResponse.budgetCategory
                    budgetPreference.user = user
                    budgetPreference.productCategory = budgetPreferenceResponse.productCategory
                    budgetPreference.fixedAmount = budgetPreferenceResponse.fixedAmount ?? 0 // Provide a default value
                }

                try context.save()
            }
        } catch {
            print("Failed to fetch User from Core Data or save BudgetPreference to Core Data: \(error)")
        }
    }
    
    
    //MARK server
    
    //Call every time user opens app
    func fetchNewTransactionsFromServer(userId: Int64, monthlyIncome: Double, monthlyFixedSpend: Double) {
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
                    if !transactionsResponse.added.isEmpty {
                        self.saveTransactionsToCoreData(transactionsResponse.added, userId: userId, monthlyIncome: monthlyIncome, monthlyFixedSpend: monthlyFixedSpend)
                    }
                    if !transactionsResponse.modified.isEmpty {
                        self.modifyTransactionsInCoreData(transactionsResponse.modified, userId: userId, monthlyIncome: monthlyIncome, monthlyFixedSpend: monthlyFixedSpend)
                    }
                    if !transactionsResponse.removed.isEmpty {
                        self.removeTransactionsFromCoreData(transactionsResponse.removed, userId: userId)
                    }
                }
            case .failure(let error):
                print("Failed to fetch user data from server: \(error)")
            }
        }
    }
    
    //Call every time user opens app in case user has switched device
    func fetchTransactionHistoryFromServer(userId: Int64, bankAccounts: [UserViewModel.BankAccount], monthlyIncome: Double, monthlyFixedSpend: Double) {
        let context = CoreDataStack.shared.persistentContainer.viewContext

        for bankAccount in bankAccounts {
            let transactionFetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            transactionFetchRequest.predicate = NSPredicate(format: "account.id == %lld", bankAccount.id)

            do {
                let transactions = try context.fetch(transactionFetchRequest)
                if transactions.isEmpty {
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
                                if !transactionsResponse.isEmpty {
                                    self.saveTransactionsToCoreData(transactionsResponse, userId: userId, monthlyIncome: monthlyIncome, monthlyFixedSpend: monthlyFixedSpend)
                                }
                            }
                        case .failure(let error):
                            print("Failed to fetch transaction history from server: \(error)")
                        }
                    }
                }
            } catch {
                print("Failed to fetch transactions from Core Data: \(error)")
            }
        }
    }
    
    // Fetch budget preferences from server
    func fetchBudgetPreferencesFromServer(userId: Int64) {
        let keychain = Keychain(service: "robharrell.Flex")
        let sessionToken = keychain["sessionToken"] ?? ""

        let path = "/budget/get_budget_preferences_for_user/\(userId)"
        ServerCommunicator.shared.callMyServer(
            path: path,
            httpMethod: .get,
            sessionToken: sessionToken
        ) { (result: Result<BudgetPreferencesResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let budgetPreferencesResponse):
                DispatchQueue.main.async {
                    // Map BudgetPreferenceResponse instances to BudgetPreferenceViewModel instances
                    let budgetPreferenceViewModels = budgetPreferencesResponse.map { BudgetPreferenceViewModel(from: $0) }
                    // Save the fetched budget preferences to Core Data
                    self.saveBudgetPreferencesToCoreData(budgetPreferenceViewModels, userId: userId)
                }
            case .failure(let error):
                print("Failed to fetch budget preferences from server: \(error)")
            }
        }
    }

    
    // Update budget preferences on server
    func updateBudgetPreferencesOnServer(userId: Int64) {
        let keychain = Keychain(service: "robharrell.Flex")
        let sessionToken = keychain["sessionToken"] ?? ""
        let budgetPreferencesForServer = self.budgetPreferences.compactMap { budgetPreference -> [String: Any]? in
            var keyValuePairs: [(String, Any)] = [
                ("category", budgetPreference.category),
                ("sub_category", budgetPreference.subCategory),
                ("product_category", budgetPreference.productCategory),
                ("budget_category", budgetPreference.budgetCategory)
            ]
            
            if let id = budgetPreference.id {
                keyValuePairs.append(("id", id))
            }
            
            if let fixedAmount = budgetPreference.fixedAmount {
                keyValuePairs.append(("fixed_amount", fixedAmount))
            }
            
            return Dictionary(uniqueKeysWithValues: keyValuePairs)
        }

        ServerCommunicator.shared.callMyServer(
            path: "/budget/update_budget_preferences_for_user",
            httpMethod: .post,
            params: ["id": userId, "budget_preferences": budgetPreferencesForServer],
            sessionToken: sessionToken
        ) { (result: Result<UpdateBudgetPreferencesResponse, ServerCommunicator.Error>) in
            switch result {
            case .success:
                print("Successfully updated budget preferences on server")
            case .failure(let error):
                print("Failed to update budget preferences on server: \(error)")
            }
        }
    }
    
    //Mark business logic
    func calculateSelectedMonthBudgetMetrics(for month: Date, monthlyIncome: Double, monthlyFixedSpend: Double) {
        self.isCalculatingMetrics = true
        
        // Create a date range for the given month
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        // Fetch transactions from Core Data for the given month
        self.selectedMonthTransactions = self.fetchTransactionsFromCoreData(from: startOfMonth, to: endOfMonth)

        // Group transactions by date
        let groupedTransactionsByDay = Dictionary(grouping: self.selectedMonthTransactions, by: { $0.date })

        // Calculate total fixed and flexible spending and income per day
        self.selectedMonthFixedSpendPerDay = [:]
        self.selectedMonthFlexSpendPerDay = [:]
        self.selectedMonthIncomePerDay = [:]

        for (date, transactions) in groupedTransactionsByDay {
            var totalFixedSpend = 0.0
            var totalFlexSpend = 0.0
            var totalIncome = 0.0

            for transaction in transactions {
                switch transaction.budgetCategory {
                case "Fixed":
                    totalFixedSpend += transaction.amount
                case "Flex":
                    totalFlexSpend += transaction.amount
                case "Income":
                    totalIncome += transaction.amount
                default:
                    break
                }
            }

            self.selectedMonthFixedSpendPerDay[date] = totalFixedSpend
            self.selectedMonthFlexSpendPerDay[date] = totalFlexSpend
            self.selectedMonthIncomePerDay[date] = totalIncome
        }

        // Calculate total fixed and flexible spending and income for the month
        self.selectedMonthFlexSpend = self.selectedMonthFlexSpendPerDay.values.reduce(0, +)
        
        let currentMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!

        //Calculate fixed and income based on arguments if current month
        if Calendar.current.isDate(month, equalTo: currentMonth, toGranularity: .month) {
            self.selectedMonthFixedSpend = monthlyFixedSpend
            self.selectedMonthIncome = monthlyIncome
        } else {
            self.selectedMonthFixedSpend = self.selectedMonthFixedSpendPerDay.values.reduce(0, +)
            self.selectedMonthIncome = self.selectedMonthIncomePerDay.values.reduce(0, +)
        }

        // Calculate savings for the month
        self.selectedMonthSavings = selectedMonthIncome - selectedMonthFixedSpend - selectedMonthFlexSpend
       
        self.isCalculatingMetrics = false
    }
    
    func calculateRecentIncomeStats() {
        // Create a date range for the past two complete months
        let calendar = Calendar.current
        let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let startOfPreviousMonth = calendar.date(byAdding: .month, value: -1, to: startOfCurrentMonth)!
        let startOfTwoMonthsAgo = calendar.date(byAdding: .month, value: -1, to: startOfPreviousMonth)!
        let endOfPreviousMonth = calendar.date(byAdding: .day, value: -1, to: startOfCurrentMonth)!

        // Fetch transactions from Core Data for the past two complete months
        let transactions = self.fetchTransactionsFromCoreData(from: startOfTwoMonthsAgo, to: endOfPreviousMonth)

        // Group transactions by month
        let groupedTransactionsByMonth = Dictionary(grouping: transactions, by: { Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: $0.date))! })

        // Calculate total fixed and flexible spending and income per month
        self.workMonthlyIncome = [:]
        self.benefitsMonthlyIncome = [:]
        self.accrualsMonthlyIncome = [:]
        self.pensionMonthlyIncome = [:]

        for (month, transactions) in groupedTransactionsByMonth {
            var totalFixedSpend = 0.0
            var totalFlexSpend = 0.0
            var totalIncome = 0.0
            var totalWorkIncome = 0.0
            var totalBenefitsIncome = 0.0
            var totalAccrualsIncome = 0.0
            var totalPensionIncome = 0.0

            for transaction in transactions {
                switch transaction.budgetCategory {
                case "Fixed":
                    totalFixedSpend += transaction.amount
                case "Flex":
                    totalFlexSpend += transaction.amount
                case "Income":
                    totalIncome += transaction.amount
                default:
                    break
                }

                switch transaction.productCategory {
                case "Paycheck":
                    totalWorkIncome += transaction.amount
                case "Benefits":
                    totalBenefitsIncome += transaction.amount
                case "Dividends & Interest":
                    totalAccrualsIncome += transaction.amount
                case "Pension":
                    totalPensionIncome += transaction.amount
                default:
                    break
                }
            }
            self.workMonthlyIncome[month] = totalWorkIncome
            self.benefitsMonthlyIncome[month] = totalBenefitsIncome
            self.accrualsMonthlyIncome[month] = totalAccrualsIncome
            self.pensionMonthlyIncome[month] = totalPensionIncome
        }

        // Calculate averages
        let sortedWorkIncome = self.workMonthlyIncome.sorted(by: { $0.key < $1.key })
        let sortedBenefitsIncome = self.benefitsMonthlyIncome.sorted(by: { $0.key < $1.key })
        let sortedAccrualsIncome = self.accrualsMonthlyIncome.sorted(by: { $0.key < $1.key })
        let sortedPensionsIncome = self.pensionMonthlyIncome.sorted(by: { $0.key < $1.key })

        let recentWorkIncome = Array(sortedWorkIncome.dropLast().suffix(2))
        self.avgRecentWorkIncome = recentWorkIncome.reduce(0, { $0 + $1.value }) / Double(recentWorkIncome.count)

        let recentBenefitsIncome = Array(sortedBenefitsIncome.dropLast().suffix(2))
        self.avgRecentBenefitsIncome = recentBenefitsIncome.reduce(0, { $0 + $1.value }) / Double(recentBenefitsIncome.count)

        let recentAccrualsIncome = Array(sortedAccrualsIncome.dropLast().suffix(2))
        self.avgRecentAccrualsIncome = recentAccrualsIncome.reduce(0, { $0 + $1.value }) / Double(recentAccrualsIncome.count)
        
        let recentPensionIncome = Array(sortedPensionsIncome.dropLast().suffix(2))
        self.avgRecentPensionIncome = recentPensionIncome.reduce(0, { $0 + $1.value })

        self.avgTotalRecentIncome = (self.avgRecentWorkIncome + self.avgRecentBenefitsIncome + self.avgRecentAccrualsIncome + self.avgRecentPensionIncome)
    }
    
    func calculateFixedSpendBreakdown() {
        
    }
}
