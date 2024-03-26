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
                let keychain = Keychain(service: "robharrell.Flex")
                keychain["sessionToken"] = data.sessionToken
                // Save user id to UserDefaults
                UserDefaults.standard.set(data.userId, forKey: "currentUserId")
                // Update the context with the phone number and user id
                self.phone = phone
                self.id = data.userId
                // Fetch the user data from Core Data or create a new user if not found
                let context = CoreDataStack.shared.persistentContainer.viewContext
                let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %d", data.userId)
                do {
                    let users = try context.fetch(fetchRequest)
                    if data.isExistingUser {
                        if users.isEmpty {
                            // If the user exists on the server but not in Core Data on this device, fetch user's data from server
                            self.fetchUserInfoFromServer(userId: data.userId)
                        } else {
                            // If user exists in core data, load user data from core
                            self.fetchUserFromCoreData(userId: data.userId)
                        }
                    } else {
                        // If user is new, create a new user in core
                        self.createUserInCoreData(id: data.userId, phone: phone )
                    }
                } catch {
                    print("Failed to fetch user from Core Data: \(error)")
                }
                // Call the completion handler with the isExistingUser value
                completion(data.isExistingUser)
            case .failure(let error):
                print("Failed to verify code: \(error)")
                completion(false)
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
                }
            case .failure(let error):
                print("Failed to fetch user data from server: \(error)")
            }
        }
    }
    
    func updateUser() {
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

    func fetchBankConnectionsFromServer() {
        // Get session token from keychain
        let keychain = Keychain(service: "robharrell.Flex")
        guard let sessionToken = keychain["sessionToken"] else {
            print("Session token not found in keychain")
            return
        }
        guard id != 0 else {
            print("User ID is not set - fetchBankConnectionsFromServer")
            return
        }
        let path = "/accounts/get_bank_accounts?userId=\(self.id)"
        ServerCommunicator.shared.callMyServer(path: path, httpMethod: .get, sessionToken: sessionToken) { (result: Result<[BankConnection], ServerCommunicator.Error>) in
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

        do {
            let users = try context.fetch(fetchRequest)
            if let user = users.first {
                DispatchQueue.main.async {
                    self.firstName = user.firstName ?? ""
                    self.lastName = user.lastName ?? ""
                    self.monthlyIncome = user.monthlyIncome
                    self.monthlyFixedSpend = user.monthlyFixedSpend
                    self.birthDate = user.birthDate ?? ""
                }
            } else {
                print("No user found in Core Data with ID \(userId)")
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
        if let sessionToken = keychain["sessionToken"] {
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
        self.bankConnections = []
    }
}
