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
    @Published var bankConnections: [BankConnection] = []
    var isSignedIn: Bool {
        UserDefaults.standard.object(forKey: "currentUserId") != nil
    }

    struct BankConnection: Identifiable, Codable {
        var id: Int
        var name: String
        var maskedAccountNumber: String
        var friendlAccountName: String?
        var bankName: String
        var isActive: Bool
        var logoPath: String
    }

    // MARK: - Twilio
    func triggerTwilioOTP(phone: String) {
        // Implement the logic for sending a verification code via your server
        ServerCommunicator.shared.callMyServer(
            path: "/twilio/sendOTP",
            httpMethod: .post,
            params: ["phoneNumber": phone]
        ) { (result: Result<ServerCommunicator.DummyDecodable, ServerCommunicator.Error>) in
            switch result {
            case .success:
                print("Verification code sent successfully")
                // You can now ask the user to enter the verification code
            case .failure(let error):
                print("Failed to send verification code: \(error)")
            }
        }
    }

    func verifyTwilioOTP(code: String, forPhone phone: String, completion: @escaping (Bool) -> Void) {
        // Implement the logic for verifying the code via your server
        ServerCommunicator.shared.callMyServer(
            path: "/twilio/verifyOTP",
            httpMethod: .post,
            params: ["phoneNumber": phone, "code": code]
        ) { (result: Result<VerificationResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let data):
                print("Verification code verified successfully")
                // Save session token to keychain
                let keychain = Keychain(service: "com.yourapp.identifier")
                keychain["sessionToken"] = data.sessionToken
                // Save user id to UserDefaults
                UserDefaults.standard.set(data.userId, forKey: "currentUserId")
                // Update the context with the phone number
                self.phone = phone
                // Fetch the user data from Core Data or create a new user if not found
                self.fetchUserFromCoreDataOrCreateNew(userId: data.userId, phone: phone)
                // Call the completion handler with the isExistingUser value
                completion(data.isExistingUser)
            case .failure(let error):
                print("Failed to verify code: \(error)")
                completion(false)
            }
        }
    }

    // MARK: - Server
    func updateUser(user: User) {
        print("update user called on client")
        guard user.id != 0 else {
            print("User ID is not set")
            return
        }
        let path = "/user/\(user.id)"
        let params = ["userId": String(user.id), "firstName": user.firstName, "lastName": user.lastName, "phone": user.phone, "birthDate": user.birthDate, "monthlyIncome": user.monthlyIncome, "monthlyFixedSpend": user.monthlyFixedSpend] as [String : Any]
        ServerCommunicator.shared.callMyServer(path: path, httpMethod: .put, params: params) { (result: Result<UserInfoResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let userInfo):
                DispatchQueue.main.async {
                    self.updateUserInCoreData(user: user)
                    self.updateUser(user: user)
                }
            case .failure(let error):
                print("Failed to update user: \(error)")
            }
        }
    }

    // MARK: - Core Data
    func fetchUserFromCoreDataOrCreateNew(userId: Int64, phone: String? = nil) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", userId)

        do {
            let users = try context.fetch(fetchRequest)
            if let user = users.first {
                DispatchQueue.main.async {
                    self.updateUser(user: user)
                }
            } else {
                print("No user found in Core Data with ID \(userId), creating a new user")
                if let phone = phone {
                    self.createUserInCoreData(id: userId, phone: phone)
                } else {
                    print("Cannot create a new user without a phone number")
                }
            }
        } catch {
            print("Failed to fetch user from Core Data: \(error)")
        }
    }

    func createUserInCoreData(id: Int64, phone: String) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let newUser = User(context: context)
        newUser.id = id
        newUser.phone = phone

        do {
            try context.save()
        } catch {
            print("Failed to create user in Core Data: \(error)")
        }
    }

    func updateUserInCoreData(user: User) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", user.id)

        do {
            let users = try context.fetch(fetchRequest)
            if let existingUser = users.first {
                existingUser.firstName = user.firstName
                existingUser.lastName = user.lastName
                existingUser.phone = user.phone
                existingUser.birthDate = user.birthDate
                existingUser.monthlyIncome = user.monthlyIncome
                existingUser.monthlyFixedSpend = user.monthlyFixedSpend
                try context.save()
            } else {
                print("No user found in Core Data with ID \(user.id)")
            }
        } catch {
            print("Failed to update user in Core Data: \(error)")
        }
    }

    // MARK: - User Session
    func signOutUser() {
        // Clear session token from keychain
        let keychain = Keychain(service: "com.yourapp.identifier")
        try? keychain.remove("sessionToken")
        
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
        self.bankConnections = []
    }
    

    func fetchBankConnectionsFromServer() {
        guard id != 0 else {
            print("User ID is not set - fetchBankConnectionsFromServer")
            return
        }
        let path = "/accounts/get_bank_accounts?userId=\(self.id)"
        ServerCommunicator.shared.callMyServer(path: path, httpMethod: .get) { (result: Result<[BankConnection], ServerCommunicator.Error>) in
            switch result {
            case .success(let bankConnections):
                DispatchQueue.main.async {
                    self.bankConnections = bankConnections
                }
            case .failure(let error):
                print("Failed to fetch bank connections: \(error)")
            }
        }
    }  
}
