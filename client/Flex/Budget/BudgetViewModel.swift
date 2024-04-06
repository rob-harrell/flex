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

class BudgetViewModel: ObservableObject {
    @Published var spendingData: [Date: Double] = [:]
    @Published var monthlyIncome: Double = 5000.0 // User-set monthly income
    @Published var transactions: [TransactionViewModel] = []
    @Published var budgetPreferences: [BudgetPreferenceViewModel] = []
    var userViewModel: UserViewModel
    var sharedViewModel: DateViewModel
    
    struct TransactionViewModel {
        var id: Int64
        var amount: Double
        var authorizedDate: String
        var budgetCategory: String
        var category: String
        var subCategory: String
        var currencyCode: String
        var date: String
        var isRemoved: Bool
        var name: String
        var pending: Bool
        var productCategory: String
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

    init(sharedViewModel: DateViewModel, userViewModel: UserViewModel) {
        self.sharedViewModel = sharedViewModel
        self.userViewModel = userViewModel

        // Check if budget preferences exist in Core Data
        let fetchRequest: NSFetchRequest<BudgetPreference> = BudgetPreference.fetchRequest()
        do {
            let context = CoreDataStack.shared.persistentContainer.viewContext
            let budgetPreferences = try context.fetch(fetchRequest)
            if budgetPreferences.isEmpty {
                // If the user has not edited budget preferences, load from the default CSV file
                if !userViewModel.hasEditedBudgetPreferences {
                    if let defaultBudgetPreferences = loadDefaultBudgetPreferencesFromJSON() {
                        self.budgetPreferences = defaultBudgetPreferences
                        saveBudgetPreferencesToCoreData(defaultBudgetPreferences) // Save to Core Data
                    }
                } else {
                    // Otherwise, fetch from the server
                    fetchBudgetPreferencesFromServer()
                }
            } else {
                // If budget preferences exist in Core Data, hydrate state with them
                self.budgetPreferences = budgetPreferences.map { BudgetPreferenceViewModel(from: $0) }
            }
        } catch {
            print("Failed to fetch BudgetPreference: \(error)")
        }

        generateSpendingData()
    }
    
    // Computed properties to calculate total expenses
    var totalExpensesPerDay: [Date: Double] {
        var expenses: [Date: Double] = [:]
        for (date, spending) in spendingData {
            expenses[date] = spending
        }
        return expenses
    }

    var totalExpensesPerMonth: [Date: Double] {
        var expenses: [Date: Double] = [:]
        for monthDates in sharedViewModel.dates {
            let totalSpending = monthDates.compactMap { spendingData[$0] }.reduce(0, +)
            expenses[monthDates.first!] = totalSpending
        }
        return expenses
    }

    var expensesMonthToDate: Double {
        let now = Date()
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now))!
        let range = startOfMonth...now
        let totalSpending = spendingData.filter { range.contains($0.key) }.values.reduce(0, +)
        return totalSpending
    }

    var monthlySavings: [Date: Double] {
        var savings: [Date: Double] = [:]
        for (date, totalExpenses) in totalExpensesPerMonth {
            savings[date] = monthlyIncome - totalExpenses
        }
        return savings
    }

    var currentMonthSavings: Double {
        return monthlyIncome - expensesMonthToDate
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
    func fetchTransactionsFromCoreData() {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        do {
            let fetchedTransactions = try context.fetch(fetchRequest)
            transactions = fetchedTransactions.map { transaction in
                TransactionViewModel(id: transaction.id, amount: transaction.amount, authorizedDate: transaction.authorizedDate!, budgetCategory: transaction.budgetCategory!, category: transaction.category!, subCategory: transaction.subCategory!, currencyCode: transaction.currencyCode!, date: transaction.date!, isRemoved: transaction.isRemoved, name: transaction.name!, pending: transaction.pending, productCategory: transaction.productCategory!)
            }
            print("fetched transactions from core data")
        } catch {
            print("Failed to fetch transactions from Core Data: \(error)")
        }
    }
    
    func saveTransactionsToCoreData(_ transactions: TransactionsResponse) {
        let context = CoreDataStack.shared.persistentContainer.viewContext

        for transactionResponse in transactions {
            let transaction = Transaction(context: context)
            transaction.id = transactionResponse.id
            transaction.amount = transactionResponse.amount
            transaction.authorizedDate = transactionResponse.authorizedDate
            transaction.budgetCategory = transactionResponse.budgetCategory
            transaction.category = transactionResponse.category
            transaction.subCategory = transactionResponse.subCategory
            transaction.currencyCode = transactionResponse.currencyCode
            transaction.date = transactionResponse.date
            transaction.isRemoved = transactionResponse.isRemoved
            transaction.name = transactionResponse.name
            transaction.pending = transactionResponse.pending
            transaction.productCategory = transactionResponse.productCategory

            // Get the User from userViewModel.id
            let userFetchRequest: NSFetchRequest<User> = User.fetchRequest()
            userFetchRequest.predicate = NSPredicate(format: "id == %@", userViewModel.id)

            do {
                let users = try context.fetch(userFetchRequest)
                if let user = users.first {
                    transaction.user = user
                }
            } catch {
                print("Failed to fetch user from Core Data: \(error)")
            }

            // Get the Account from the account ID in the TransactionResponse
            let accountFetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
            accountFetchRequest.predicate = NSPredicate(format: "id == %d", transactionResponse.accountId)

            do {
                let accounts = try context.fetch(accountFetchRequest)
                if let account = accounts.first {
                    transaction.account = account
                }
            } catch {
                print("Failed to fetch account from Core Data: \(error)")
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save transactions to Core Data: \(error)")
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
    
    func saveBudgetPreferencesToCoreData(_ budgetPreferences: [BudgetPreferenceViewModel]) {
        let context = CoreDataStack.shared.persistentContainer.viewContext

        // Fetch the User from Core Data
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", userViewModel.id)

        do {
            let users = try context.fetch(fetchRequest)

            // If the User exists, create the BudgetPreference entities and establish the relationship
            if let user = users.first {
                for budgetPreferenceResponse in budgetPreferences {
                    let budgetPreference = BudgetPreference(context: context)
                    budgetPreference.id = budgetPreferenceResponse.id
                    budgetPreference.category = budgetPreferenceResponse.category
                    budgetPreference.subCategory = budgetPreferenceResponse.subCategory
                    budgetPreference.budgetCategory = budgetPreferenceResponse.budgetCategory
                    budgetPreference.user = user
                    budgetPreference.productCategory = budgetPreferenceResponse.productCategory
                    budgetPreference.fixedAmount = budgetPreferenceResponse.fixedAmount
                }

                try context.save()
            }
        } catch {
            print("Failed to fetch User from Core Data or save BudgetPreference to Core Data: \(error)")
        }
    }
    
    
    //MARK server
    func fetchTransactionsFromServer() {
        ServerCommunicator.shared.callMyServer(
            path: "/budget/get_transactions_for_user_accounts",
            httpMethod: .get,
            params: ["id": userViewModel.id],
            sessionToken: userViewModel.sessionToken
        ) { (result: Result<TransactionsResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let transactions):
                DispatchQueue.main.async {
                    self.saveTransactionsToCoreData(transactions)
                }
            case .failure(let error):
                print("Failed to fetch user data from server: \(error)")
            }
        }
    }
    
    // Fetch budget preferences from server
    func fetchBudgetPreferencesFromServer() {
        ServerCommunicator.shared.callMyServer(
            path: "/budget/get_budget_preferences",
            httpMethod: .get,
            params: ["id": userViewModel.id],
            sessionToken: userViewModel.sessionToken
        ) { (result: Result<BudgetPreferencesResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let budgetPreferences):
                DispatchQueue.main.async {
                    self.saveBudgetPreferencesToCoreData(budgetPreferences)
                }
            case .failure(let error):
                print("Failed to fetch budget preferences from server: \(error)")
            }
        }
    }

    
    // Update budget preferences on server
    func updateBudgetPreferencesOnServer() {
        let budgetPreferences = loadBudgetPreferencesFromCoreData()

        ServerCommunicator.shared.callMyServer(
            path: "/budget/update_budget_preferences",
            httpMethod: .post,
            params: ["id": userViewModel.id, "budgetPreferences": budgetPreferences],
            sessionToken: userViewModel.sessionToken
        ) { (result: Result<UpdateBudgetPreferencesResponse, ServerCommunicator.Error>) in
            switch result {
            case .success:
                print("Successfully updated budget preferences on server")
            case .failure(let error):
                print("Failed to update budget preferences on server: \(error)")
            }
        }
    }
    
    
    //Mark placeholder
    // Function to generate dummy spending data for the past 12 months
    private func generateSpendingData() {
        for monthDates in sharedViewModel.dates {
            for date in monthDates {
                // Generate and store dummy spending data for the date
                let randomSpending = Double.random(in: 1...100)
                spendingData[date] = randomSpending
            }
        }
    }
    
    // Function to return spending amount for a given date as a string
    func spendingStringForDate(_ date: Date) -> String {
        if let spending = spendingData[date] {
            return "$\(Int(round(spending)))"
        } else {
            return "$0"
        }
    }
}
