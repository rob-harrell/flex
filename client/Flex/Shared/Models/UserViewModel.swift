//
//  UserViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 3/3/24.
//

import Foundation
import CoreData
import KeychainAccess

class UserViewModel: ObservableObject {
    @Published var id: Int64 = 0
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phone: String = ""
    @Published var monthlyIncome: Double = 0.0
    @Published var monthlyFixedSpend: Double = 0.0
    @Published var birthDate: String = ""
    @Published var sessionToken: String = ""
    @Published var bankAccounts: [BankAccount] = []
    @Published var hasEnteredUserDetails: Bool = false
    @Published var canCompleteAccountCreation: Bool = false
    @Published var hasCompletedAccountCreation: Bool = false
    @Published var hasCompletedNotificationSelection: Bool = false
    @Published var pushNotificationsEnabled: Bool = false
    @Published var smsNotificationsEnabled: Bool = false
    @Published var hasEditedBudgetPreferences: Bool = false
    @Published var hasCompletedBudgetCustomization: Bool = false
    var isSignedIn: Bool {
        UserDefaults.standard.object(forKey: "currentUserId") != nil
    }

    struct BankAccount: Identifiable, Codable {
        var id: Int64
        var name: String
        var maskedAccountNumber: String
        var friendlyAccountName: String?
        var bankName: String
        var isActive: Bool
        var logoPath: String
        var type: String
        var subType: String
    }

    init() {
        if let userId = UserDefaults.standard.object(forKey: "currentUserId") as? Int64 {
            self.id = userId
            fetchUserFromCoreData(userId: userId)
        }
        let keychain = Keychain(service: "robharrell.Flex")
        self.sessionToken = keychain["sessionToken"] ?? ""
    }

    // MARK: - Twilio
    func triggerTwilioOTP(phone: String) {
        ServerCommunicator.shared.callMyServer(
            path: "/twilio/sendOTP",
            httpMethod: .post,
            params: ["phone": phone]
        ) { (result: Result<OTPResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let response):
                if let message = response.message {
                    print("OTP sent successfully: \(message)")
                } else if let error = response.error {
                    print("Failed to send OTP: \(error)")
                }
            case .failure(let error):
                print("Failed to send OTP: \(error)")
            }
        }
    }

    func verifyTwilioOTP(code: String, phone: String, completion: @escaping (Result<VerificationResponse, ServerCommunicator.Error>) -> Void) {
        print("verifyTwilioOTP called with phone \(phone)")
        ServerCommunicator.shared.callMyServer(
            path: "/twilio/verifyOTP",
            httpMethod: .post,
            params: ["phone": phone, "code": code]
        ) { (result: Result<VerificationResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let data):
                print("Verification code verified successfully")
                // Save session token to keychain
                let keychain = Keychain(service: "robharrell.Flex")
                keychain["sessionToken"] = data.sessionToken
                self.sessionToken = data.sessionToken
                // Save user id to UserDefaults
                UserDefaults.standard.set(data.userId, forKey: "currentUserId")
                // Update the context the user id
                self.id = data.userId
                // Fetch the user data from Core Data or create a new user if not found
                let context = CoreDataStack.shared.persistentContainer.viewContext
                let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %d", data.userId)
                do {
                    let users = try context.fetch(fetchRequest)
                    if !users.isEmpty{
                        if data.isExistingUser {
                            // If the user exists on the server but not in Core Data on this device, fetch user's data from server
                            self.fetchUserInfoFromServer(userId: data.userId)
                            self.fetchBankAccountsFromServer()
                        } else {
                            //if it's an existing user on this device but the user hasn't yet finished signup, show user details or account connection
                            // If user exists in core data, load user data from core
                            self.fetchUserFromCoreData(userId: data.userId)
                        }
                    } else {
                        // If user is entirely new, create a new user in core
                        self.createUserInCoreData()
                    }
                } catch {
                    print("Failed to fetch user from Core Data: \(error)")
                }
                // Call the completion handler with the success result
                completion(.success(data))
            case .failure(let error):
                print("Failed to verify code: \(error)")
                // Call the completion handler with the failure result
                completion(.failure(error))
            }
        }
    }

    // MARK: - Server
    func fetchUserInfoFromServer(userId: Int64) {
        // Fetch user info
        ServerCommunicator.shared.callMyServer(
            path: "/user/get_user_data",
            httpMethod: .get,
            params: ["id": userId],
            sessionToken: self.sessionToken
        ) { (result: Result<UserInfoResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    self.firstName = data.firstName
                    self.lastName = data.lastName
                    self.phone = data.phone
                    self.monthlyIncome = data.monthlyIncome
                    self.monthlyFixedSpend = data.monthlyFixedSpend
                    self.birthDate = data.birthDate
                    self.hasEnteredUserDetails = data.hasEnteredUserDetails
                    self.hasCompletedAccountCreation = data.hasCompletedAccountCreation
                    self.hasCompletedNotificationSelection = data.hasCompletedNotificationSelection
                    self.pushNotificationsEnabled = data.pushNotificationsEnabled
                    self.smsNotificationsEnabled = data.smsNotificationsEnabled
                    self.hasEditedBudgetPreferences = data.hasEditedBudgetPreferences
                    self.hasCompletedBudgetCustomization = data.hasCompletedBudgetCustomization
                
                    // If user has entered details, update user in CoreData
                    // Otherwise, create user in CoreData
                    if self.hasEnteredUserDetails {
                        self.createUserInCoreData()
                        self.updateUserInCoreData()
                    } else {
                        self.createUserInCoreData()
                    }
                }
            case .failure(let error):
                print("Failed to fetch user data from server: \(error)")
            }
        }
    }
    
    func updateUserOnServer() {
        guard self.id != 0 else {
            print("User ID is not set")
            return
        }
        let path = "/user/\(self.id)"
        let params = ["id": String(self.id), "firstname": self.firstName, "lastname": self.lastName, "phone": self.phone, "birth_date": self.birthDate, "monthly_income": self.monthlyIncome, "monthly_fixed_spend": self.monthlyFixedSpend, "has_entered_user_details": self.hasEnteredUserDetails, "has_completed_account_creation": self.hasCompletedAccountCreation, "has_completed_notification_selection": self.hasCompletedNotificationSelection, "push_notifications_enabled": self.pushNotificationsEnabled, "sms_notifications_enabled": self.smsNotificationsEnabled, "has_edited_budget_preferences": self.hasEditedBudgetPreferences, "has_completed_budget_customization": self.hasCompletedBudgetCustomization] as [String : Any]
        ServerCommunicator.shared.callMyServer(path: path, httpMethod: .put, params: params, sessionToken: self.sessionToken) { (result: Result<UserInfoResponse, ServerCommunicator.Error>) in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.updateUserInCoreData()
                }
            case .failure(let error):
                print("Failed to update user: \(error)")
            }
        }
    }

    func fetchBankAccountsFromServer() {
        // Fetch bank connections
        print("fetchBankAccountsFromServer called with id: \(self.id)")
        ServerCommunicator.shared.callMyServer(
            path: "/accounts/get_bank_accounts",
            httpMethod: .get,
            params: ["id": self.id],
            sessionToken: self.sessionToken
        ) { (result: Result<BankAccountsResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let data):
                print("successfully received account data")
                DispatchQueue.main.async {
                    let accountsToSave = data.filter { $0.subType == "checking" || $0.subType == "credit card" || $0.subType == "savings" }
                    self.upsertFetchedAccountsInCoreData(data: accountsToSave)
                }
            case .failure(let error):
                print("Failed to fetch bank connections from server: \(error)")
            }
        }
    }

    func invalidateSessionToken(completion: @escaping (Bool) -> Void) {
        ServerCommunicator.shared.callMyServer(
            path: "/user/invalidate_session_token",
            httpMethod: .post,
            params: ["session_token": self.sessionToken]
        ) { (result: Result<ServerCommunicator.DummyDecodable, ServerCommunicator.Error>) in
            switch result {
            case .success:
                print("Session token invalidated successfully")
                completion(true)
            case .failure(let error):
                print("Failed to invalidate session token: \(error)")
                completion(false)
            }
        }
    }

    // MARK: - Core Data
    func fetchUserFromCoreData(userId: Int64) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", userId)
        fetchRequest.relationshipKeyPathsForPrefetching = ["accounts"] // Prefetch accounts

        do {
            let users = try context.fetch(fetchRequest)
            if let user = users.first {
                DispatchQueue.main.async {
                    self.id = user.id
                    self.firstName = user.firstName ?? ""
                    self.lastName = user.lastName ?? ""
                    self.phone = user.phone ?? ""
                    self.monthlyIncome = user.monthlyIncome
                    self.monthlyFixedSpend = user.monthlyFixedSpend
                    self.birthDate = user.birthDate ?? ""
                    self.hasEnteredUserDetails = user.hasEnteredUserDetails
                    self.hasCompletedAccountCreation = user.hasCompletedAccountCreation
                    self.hasCompletedNotificationSelection = user.hasCompletedNotificationSelection
                    self.pushNotificationsEnabled = user.pushNotificationsEnabled
                    self.smsNotificationsEnabled = user.smsNotificationsEnabled
                    self.hasEditedBudgetPreferences = user.hasEditedBudgetPreferences
                    self.hasCompletedBudgetCustomization = user.hasCompletedBudgetCustomization

                    // Fetch accounts and populate bankAccounts array
                    if let accounts = user.accounts as? Set<Account> {
                        self.bankAccounts = accounts.map { account in
                            BankAccount(
                                id: account.id,
                                name: account.name ?? "",
                                maskedAccountNumber: account.maskedAccountNumber ?? "",
                                friendlyAccountName: account.friendlyAccountName ?? "",
                                bankName: account.bankName ?? "",
                                isActive: account.isActive,
                                logoPath: account.logoPath ?? "",
                                type: account.type ?? "",
                                subType: account.subType ?? ""
                            )
                        }
                        
                        let hasCheckingOrSavings = self.bankAccounts.contains { $0.subType == "checking" || $0.subType == "savings" }
                        let hasCreditCard = self.bankAccounts.contains { $0.subType == "credit card" }
                        self.canCompleteAccountCreation = hasCheckingOrSavings
                    }
                }
            } else {
                print("No user found in Core Data with ID \(userId)")
            }
        } catch {
            print("Failed to fetch user from Core Data: \(error)")
        }
    }

    func createUserInCoreData() {
        print("calling create user in core data with id: \(self.id) and phone: \(self.phone)")
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let newUser = User(context: context)
        newUser.id = self.id
        newUser.phone = self.phone

        do {
            try context.save()
        } catch {
            print("Failed to create user in Core Data: \(error)")
        }
    }

    func updateUserInCoreData() {
        print("calling update user in core data")
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", self.id)

        do {
            let users = try context.fetch(fetchRequest)
            if let existingUser = users.first {
                existingUser.firstName = self.firstName
                existingUser.lastName = self.lastName
                existingUser.phone = self.phone
                existingUser.birthDate = self.birthDate
                existingUser.monthlyIncome = self.monthlyIncome
                existingUser.monthlyFixedSpend = self.monthlyFixedSpend
                existingUser.hasEnteredUserDetails = self.hasEnteredUserDetails
                existingUser.hasCompletedAccountCreation = self.hasCompletedAccountCreation
                existingUser.hasCompletedNotificationSelection = self.hasCompletedNotificationSelection
                existingUser.pushNotificationsEnabled = self.pushNotificationsEnabled
                existingUser.smsNotificationsEnabled = self.smsNotificationsEnabled
                existingUser.hasEditedBudgetPreferences = self.hasEditedBudgetPreferences
                existingUser.hasCompletedBudgetCustomization = self.hasCompletedBudgetCustomization
                try context.save()
            } else {
                print("No user found in Core Data with ID \(self.id)")
            }
        } catch {
            print("Failed to update user in Core Data: \(error)")
        }
    }
    
    func upsertFetchedAccountsInCoreData(data: [BankAccountResponse]) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let userFetchRequest: NSFetchRequest<User> = User.fetchRequest()
        userFetchRequest.predicate = NSPredicate(format: "id == %d", self.id)

        do {
            let fetchedUsers = try context.fetch(userFetchRequest)
            guard let user = fetchedUsers.first else {
                print("No User entity found in Core Data with id: \(self.id)")
                return
            }

            for bankAccountResponse in data {
                let accountFetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
                accountFetchRequest.predicate = NSPredicate(format: "id == %d", bankAccountResponse.id)

                let fetchedAccounts = try context.fetch(accountFetchRequest)

                if let existingAccount = fetchedAccounts.first {
                    // If the account exists, update it
                    existingAccount.name = bankAccountResponse.name
                    existingAccount.maskedAccountNumber = bankAccountResponse.maskedAccountNumber
                    existingAccount.friendlyAccountName = bankAccountResponse.friendlyAccountName
                    existingAccount.bankName = bankAccountResponse.bankName
                    existingAccount.isActive = bankAccountResponse.isActive
                    existingAccount.logoPath = bankAccountResponse.logoPath
                    existingAccount.type = bankAccountResponse.type
                    existingAccount.subType = bankAccountResponse.subType
                } else {
                    // If the account doesn't exist, create a new one
                    let newAccountViewModel = UserViewModel.BankAccount(
                        id: bankAccountResponse.id,
                        name: bankAccountResponse.name,
                        maskedAccountNumber: bankAccountResponse.maskedAccountNumber,
                        friendlyAccountName: bankAccountResponse.friendlyAccountName,
                        bankName: bankAccountResponse.bankName,
                        isActive: bankAccountResponse.isActive,
                        logoPath: bankAccountResponse.logoPath,
                        type: bankAccountResponse.type,
                        subType: bankAccountResponse.subType
                    )
                    self.bankAccounts.append(newAccountViewModel)

                    let hasCheckingOrSavings = self.bankAccounts.contains { $0.subType == "checking" || $0.subType == "savings" }
                    let hasCreditCard = self.bankAccounts.contains { $0.subType == "credit card" }

                    self.canCompleteAccountCreation = hasCheckingOrSavings

                    let newAccount = Account(context: context)
                    newAccount.id = Int64(bankAccountResponse.id)
                    newAccount.name = bankAccountResponse.name
                    newAccount.maskedAccountNumber = bankAccountResponse.maskedAccountNumber
                    newAccount.friendlyAccountName = bankAccountResponse.friendlyAccountName
                    newAccount.bankName = bankAccountResponse.bankName
                    newAccount.isActive = bankAccountResponse.isActive
                    newAccount.logoPath = bankAccountResponse.logoPath
                    newAccount.type = bankAccountResponse.type
                    newAccount.subType = bankAccountResponse.subType

                    // Associate the new account with the user
                    user.addToAccounts(newAccount)
                }

                // Save changes to CoreData
                try context.save()
            }
        } catch {
            print("Failed to fetch or save account: \(error)")
        }
        
        // Fetch all accounts from CoreData and print them
        let allAccountsFetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        do {
            let allAccounts = try context.fetch(allAccountsFetchRequest)
            print("Accounts in CoreData after upsert: \(allAccounts)")
        } catch {
            print("Failed to fetch accounts from CoreData: \(error)")
        }
    }

    // MARK: - User Session
    func signOutUser() {
        // Clear session token from keychain
        let keychain = Keychain(service: "robharrell.Flex")
        if keychain["sessionToken"] != nil {
            // Invalidate the session token on the server
            invalidateSessionToken { success in
                if success {
                    print("Session token invalidated successfully on the server")
                } else {
                    print("Failed to invalidate session token on the server")
                }
            }
            // Remove session token from keychain
            try? keychain.remove("sessionToken")
        }
        
        // Remove user id from UserDefaults
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        
        // Clean up the state
        self.id = 0
        self.firstName = ""
        self.lastName = ""
        self.phone = ""
        self.monthlyIncome = 0
        self.monthlyFixedSpend = 0
        self.birthDate = ""
        self.sessionToken = ""
        self.hasEnteredUserDetails = false
        self.hasCompletedAccountCreation = false
        self.hasCompletedNotificationSelection = false
        self.pushNotificationsEnabled = false
        self.smsNotificationsEnabled = false
        self.hasEditedBudgetPreferences = false
        self.hasCompletedBudgetCustomization = false
        self.bankAccounts = []
    }
}
