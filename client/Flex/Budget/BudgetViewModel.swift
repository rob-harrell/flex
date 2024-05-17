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
    @Published var selectedMonthTransactions: [TransactionViewModel] = []
    @Published var selectedMonthFixedSpendPerDay: [Date: Double] = [:]
    @Published var selectedMonthFlexSpendPerDay: [Date: Double] = [:]
    @Published var selectedMonthIncomePerDay: [Date: Double] = [:]
    @Published var selectedMonthFixedSpend: Double = 0.0
    @Published var selectedMonthFlexSpend: Double = 0.0
    @Published var selectedMonthIncome: Double = 0.0
    @Published var selectedMonthSavings: Double = 0.0

    //Income breakdown metrics
    @Published var avgRecentWorkIncome: Double = 0
    @Published var avgRecentBenefitsIncome: Double = 0
    @Published var avgRecentAccrualsIncome: Double = 0
    @Published var avgRecentPensionIncome: Double = 0
    @Published var avgTotalRecentIncome: Double = 0
    
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
    @Published var avgTotalRecentFixedSpend: Double = 0
    
    
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
            return transactionViewModels
        } catch {
            print("Failed to fetch transactions from Core Data: \(error)")
            return []
        }
    }
    
    func saveTransactionsToCoreData(_ transactions: [TransactionResponse], userId: Int64) {
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
            transaction.productCategory = transactionResponse.productCategory
            transaction.budgetCategory = transactionResponse.budgetCategory
            
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
                transaction.productCategory = transactionResponse.productCategory
                transaction.budgetCategory = transactionResponse.budgetCategory
                
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
    
    //Call every time user opens app
    func fetchNewTransactionsFromServer(userId: Int64, completion: @escaping (Bool) -> Void) {
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
                print("Failed to fetch transactions from Core Data: \(error)")
            }
        }
        dispatchGroup.notify(queue: .main) {
            UserDefaults.standard.set(true, forKey: "hasFetchedFullTransactionHistory")
            completion(true)
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
                    totalIncome += abs(transaction.amount)
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
    
    func calculateRecentBudgetStats() {
        // Create a date range for the past two complete months
        let calendar = Calendar.current
        let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let startOfPreviousMonth = calendar.date(byAdding: .month, value: -1, to: startOfCurrentMonth)!
        let startOfTwoMonthsAgo = calendar.date(byAdding: .month, value: -1, to: startOfPreviousMonth)!
        let endOfPreviousMonth = calendar.date(byAdding: .day, value: -1, to: startOfCurrentMonth)!

        // Fetch transactions from Core Data for the past two complete months
        let recentTransactions = self.fetchTransactionsFromCoreData(from: startOfTwoMonthsAgo, to: endOfPreviousMonth)

        // Define income and fixed spend sources to show
        var recentWorkIncome = 0.0
        var recentBenefitsIncome = 0.0
        var recentAccrualsIncome = 0.0
        var recentPensionIncome = 0.0
        var recentHousingCosts = 0.0
        var recentStudentLoans = 0.0
        var recentOtherLoans = 0.0
        var recentCarPayment = 0.0
        var recentGasAndElectrical = 0.0
        var recentInternetAndCable = 0.0
        var recentSewageAndWaste = 0.0
        var recentPhoneBill = 0.0
        var recentWaterBill = 0.0
        var recentOtherUtilities = 0.0
        var recentStorageCosts = 0.0
        var recentNursingCosts = 0.0

        for transaction in recentTransactions {
            switch transaction.productCategory {
            case "Paycheck":
                recentWorkIncome += transaction.amount
            case "Benefits":
                recentBenefitsIncome += transaction.amount
            case "Dividends & Interest":
                recentAccrualsIncome += transaction.amount
            case "Pension":
                recentPensionIncome += transaction.amount
            case "Housing":
                recentHousingCosts += transaction.amount
            case "Insurance":
                recentInsuranceCosts += transaction.amount
            case "Sudent Loan":
                recentStudentLoans += transaction.amount
            case "Other Loans":
                recentOtherLoans += transaction.amount
            case "Auto Loan":
                recentCarPayment += transaction.amount
            case "Gas & Electricity":
                recentGasAndElectrical += transaction.amount
            case "Internet & Cable":
                recentInternetAndCable += transaction.amount
            case "Sewage & Waste Management":
                recentSewageAndWaste += transaction.amount
            case "Phone Bill":
                recentPhoneBill += transaction.amount
            case "Water Bill":
                recentWaterBill += transaction.amount
            case "Other Utilities":
                recentOtherUtilities += transaction.amount
            case "Storage":
                recentStorageCosts += transaction.amount
            case "Nursing Care":
                recentNursingCosts += transaction.amount
                
            default:
                break
            }
        }

        // Calculate recent income averages
        self.avgRecentWorkIncome = recentWorkIncome / 2
        self.avgRecentBenefitsIncome = recentBenefitsIncome / 2
        self.avgRecentAccrualsIncome = recentAccrualsIncome / 2
        self.avgRecentPensionIncome = recentPensionIncome / 2
        self.avgTotalRecentIncome = abs(self.avgRecentWorkIncome + self.avgRecentBenefitsIncome + self.avgRecentAccrualsIncome + self.avgRecentPensionIncome)

        //Calculate recent fixed spend averages
        self.recentHousingCosts = recentHousingCosts / 2
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
        self.avgTotalRecentFixedSpend = (self.recentHousingCosts + self.recentInsuranceCosts + self.recentStudentLoans + self.recentOtherLoans + self.recentCarPayment + self.recentGasAndElectrical + self.recentInternetAndCable + self.recentSewageAndWaste + self.recentPhoneBill + self.recentWaterBill + self.recentOtherUtilities + self.recentStorageCosts + self.recentNursingCosts)

    }
    
}
