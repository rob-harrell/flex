//
//  UserViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 3/3/24.
//

import Foundation
import CoreData

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

    struct BankConnection: Identifiable, Codable {
        var id: Int
        var name: String
        var maskedAccountNumber: String
        var friendlAccountName: String?
        var bankName: String
        var isActive: Bool
        var logoPath: String
    }

    func createUser(firstName: String, lastName: String, phone: String, birthDate: String, sessionToken: String, monthlyIncome: Double, monthlyFixedSpend: Double) {
        print("create user called on client")
        let path = "/user/"
        let params = ["firstName": firstName, "lastName": lastName, "phone": phone, "birthDate": birthDate, "sessionToken": sessionToken, "monthlyIncome": monthlyIncome, "monthlyFixedSpend": monthlyFixedSpend] as [String : Any]
        ServerCommunicator.shared.callMyServer(path: path, httpMethod: .post, params: params) { (result: Result<UserInfoResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let userInfo):
                DispatchQueue.main.async {
                    print("attempting to save user to core data")
                    self.saveUserToCoreData(userInfo: userInfo)
                    print("saved user to core data")
                    self.fetchUserInfoFromCoreData()
                    print("updated context with core data")
                }
            case .failure(let error):
                print("Failed to create user: \(error)")
            }
        }
    }

    func updateUser(firstName: String, lastName: String, phone: String, birthDate: String, monthlyIncome: Double, monthlyFixedSpend: Double) {
        print("update user called on client")
        guard id != 0 else {
            print("User ID is not set")
            return
        }
        let path = "/user/\(self.id)"
        let params = ["userId": String(self.id), "firstName": firstName, "lastName": lastName, "phone": phone, "birthDate": birthDate, "monthlyIncome": monthlyIncome, "monthlyFixedSpend": monthlyFixedSpend] as [String : Any]
        ServerCommunicator.shared.callMyServer(path: path, httpMethod: .put, params: params) { (result: Result<UserInfoResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let userInfo):
                DispatchQueue.main.async {
                    self.saveUserToCoreData(userInfo: userInfo)
                    self.fetchUserInfoFromCoreData()
                }
            case .failure(let error):
                print("Failed to update user: \(error)")
            }
        }
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

    func fetchUserInfoFromCoreData() {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        request.predicate = NSPredicate(format: "id = %@", String(self.id))
        do {
            let result = try context.fetch(request)
            if let user = result.first as? User {
                DispatchQueue.main.async {
                    self.id = user.id
                    self.firstName = user.firstName ?? ""
                    self.lastName = user.lastName ?? ""
                    self.phone = user.phone ?? ""
                    self.monthlyIncome = user.monthlyIncome
                    self.birthDate = user.birthDate ?? ""
                    self.monthlyFixedSpend = user.monthlyFixedSpend
                    self.sessionToken = user.sessionToken ?? ""
                }
            }
        } catch {
            print("Failed to fetch user from Core Data: \(error)")
        }
    }

    func saveUserToCoreData(userInfo: UserInfoResponse) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        print("Context obtained")
        
        let user = User(context: context)
        print("User created")
        user.id = userInfo.id
        user.firstName = userInfo.firstName
        user.lastName = userInfo.lastName
        user.phone = userInfo.phone
        user.monthlyIncome = userInfo.monthlyIncome
        user.birthDate = userInfo.birthDate
        user.monthlyFixedSpend = userInfo.monthlyFixedSpend
        user.sessionToken = self.sessionToken
        print("User properties set")

        do {
            try context.save()
            print("Context saved")
        } catch {
            print("Failed to save user to Core Data: \(error)")
        }
    }
}
