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
    @Published var hasCompletedAccountCreation: Bool = false
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

    // MARK: - Twilio
    func triggerTwilioOTP(phone: String) {
        ServerCommunicator.shared.callMyServer(
            path: "/twilio/sendOTP",
            httpMethod: .post,
            params: ["phoneNumber": phone]
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

    func verifyTwilioOTP(code: String, forPhone phone: String, completion: @escaping (Result<VerificationResponse, ServerCommunicator.Error>) -> Void) {
        ServerCommunicator.shared.callMyServer(
            path: "/twilio/verifyOTP",
            httpMethod: .post,
            params: ["phoneNumber": phone, "code": code]
        ) { (result: Result<VerificationResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let data):
                print("Verification code verified successfully")
                // Save session token to keychain
                let keychain = Keychain(service: "robharrell.Flex")
                keychain["sessionToken"] = data.sessionToken
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
                            self.fetchBankAccountsFromServer(userId: data.userId)
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
        // Get session token from keychain
        let keychain = Keychain(service: "robharrell.Flex")
        guard let sessionToken = keychain["sessionToken"] else {
            print("Session token not found in keychain")
            return
        }
        
        // Fetch user info
        ServerCommunicator.shared.callMyServer(
            path: "/user/get_user_data",
            httpMethod: .get,
            params: ["userId": userId],
            sessionToken: sessionToken
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
                    
                    // Check if user has entered details
                    self.hasEnteredUserDetails = !self.firstName.isEmpty && !self.lastName.isEmpty && !self.birthDate.isEmpty
                
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
        // Get session token from keychain
        let keychain = Keychain(service: "robharrell.Flex")
        guard let sessionToken = keychain["sessionToken"] else {
            print("Session token not found in keychain")
            return
        }
        print("update user called on client")
        guard self.id != 0 else {
            print("User ID is not set")
            return
        }
        let path = "/user/\(self.id)"
        let params = ["userId": String(self.id), "firstName": self.firstName, "lastName": self.lastName, "phone": self.phone, "birthDate": self.birthDate, "monthlyIncome": self.monthlyIncome, "monthlyFixedSpend": self.monthlyFixedSpend] as [String : Any]
        ServerCommunicator.shared.callMyServer(path: path, httpMethod: .put, params: params, sessionToken: sessionToken) { (result: Result<UserInfoResponse, ServerCommunicator.Error>) in
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

    func fetchBankAccountsFromServer(userId: Int64) {
        // Get session token from key
        let keychain = Keychain(service: "robharrell.Flex")
        guard let sessionToken = keychain["sessionToken"] else {
            print("Session token not found in keychain")
            return
        }
        
        // Fetch bank connections
        ServerCommunicator.shared.callMyServer(
            path: "/accounts/get_bank_accounts",
            httpMethod: .get,
            params: ["userId": userId],
            sessionToken: sessionToken
        ) { (result: Result<BankAccountsResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    let checkingAccounts = data.filter { $0.type == "checking" }
                    let creditAccounts = data.filter { $0.type == "credit" }
                    self.hasCompletedAccountCreation = !checkingAccounts.isEmpty && !creditAccounts.isEmpty
                    // Save bank accounts to UserViewModel.bankAccounts only if the user has completed account creation
                    if self.hasCompletedAccountCreation {
                        self.bankAccounts = data.map { bankAccountResponse in
                            // Convert each BankAccountResponse to a UserViewModel.BankAccount
                            UserViewModel.BankAccount(
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
                        }
                    }
                }
            case .failure(let error):
                print("Failed to fetch bank connections from server: \(error)")
            }
        }
    }

    func invalidateSessionToken(completion: @escaping (Bool) -> Void) {
        // Get session token from keychain
        let keychain = Keychain(service: "robharrell.Flex")
        guard let sessionToken = keychain["sessionToken"] else {
            print("Session token not found in keychain")
            return
        }
        ServerCommunicator.shared.callMyServer(
            path: "/user/invalidate_session_token",
            httpMethod: .post,
            params: ["sessionToken": sessionToken]
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
                    self.firstName = user.firstName ?? ""
                    self.lastName = user.lastName ?? ""
                    self.monthlyIncome = user.monthlyIncome
                    self.monthlyFixedSpend = user.monthlyFixedSpend
                    self.birthDate = user.birthDate ?? ""

                    // Set hasEnteredUserDetails to true if firstName is not nil and not an empty string
                    self.hasEnteredUserDetails = !(self.firstName.isEmpty)
                    
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
                        
                        let checkingAccounts = self.bankAccounts.filter { $0.subType == "checking" }
                        let creditAccounts = self.bankAccounts.filter { $0.subType == "credit" }
                        self.hasCompletedAccountCreation = !checkingAccounts.isEmpty && !creditAccounts.isEmpty
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
                try context.save()
            } else {
                print("No user found in Core Data with ID \(self.id)")
            }
        } catch {
            print("Failed to update user in Core Data: \(error)")
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
        self.bankAccounts = []
    }
}
