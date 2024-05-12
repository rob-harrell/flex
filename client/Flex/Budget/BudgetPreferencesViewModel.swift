//
//  BudgetPreferencesViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 5/12/24.
//
/*:

import Foundation
import CoreData

struct BudgetPreferenceViewModel: Decodable {
 
 @Published var budgetPreferences: [BudgetPreferenceViewModel] = []
 
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

//within maintabview
private func loadBudgetPreferences() {
    let fetchRequest: NSFetchRequest<BudgetPreference> = BudgetPreference.fetchRequest()
    do {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let budgetPreferences = try context.fetch(fetchRequest)
        if budgetPreferences.isEmpty {
            // If the user has not edited budget preferences, load from the default CSV file
            if !userViewModel.hasEditedBudgetPreferences {
                if let defaultBudgetPreferences = budgetViewModel.loadDefaultBudgetPreferencesFromJSON() {
                    budgetViewModel.budgetPreferences = defaultBudgetPreferences
                    budgetViewModel.saveBudgetPreferencesToCoreData(defaultBudgetPreferences, userId: userViewModel.id) // Save to Core Data
                }
            } else {
                // Otherwise, fetch from the server
                budgetViewModel.fetchBudgetPreferencesFromServer(userId: userViewModel.id)
            }
        } else {
            // If budget preferences exist in Core Data, hydrate state with them
            budgetViewModel.budgetPreferences = budgetPreferences.map { BudgetViewModel.BudgetPreferenceViewModel(from: $0) }
        }
    } catch {
        print("Failed to fetch BudgetPreference: \(error)")
    }
}

 //within budgetviewmodel
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
 
 //within budgetviewmodel

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
 
*/
