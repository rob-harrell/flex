//
//  UserViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 3/3/24.
//

import Foundation

class UserViewModel: ObservableObject {
    @Published var id: Int = 0
    @Published var username: String = ""
    @Published var firstname: String = ""
    @Published var lastname: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var created: Date = Date()
    @Published var updated: Date = Date()
    @Published var monthly_income: Double = 0.0
    @Published var monthly_fixed_spend: Double = 0.0
    @Published var bankConnections: [BankConnection] = []

    struct BankConnection: Identifiable, Codable {
        var id: Int
        var account_id: String
        var item_id: String
        var name: String
        var masked_account_number: String
        var created: Date
        var updated: Date
        var bank_name: String
        var is_active: Bool
    }
    
    func fetchUserInfo() {
        ServerCommunicator.shared.callMyServer(path: "/path/to/user/info", httpMethod: .get) { (result: Result<UserInfoResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let userInfo):
                DispatchQueue.main.async {
                    self.id = userInfo.id
                    self.username = userInfo.username
                    self.firstname = userInfo.firstname
                    self.lastname = userInfo.lastname
                    self.email = userInfo.email
                    self.phone = userInfo.phone
                    self.monthly_income = userInfo.monthly_income
                    self.monthly_fixed_spend = userInfo.monthly_fixed_spend
                }
            case .failure(let error):
                print("Failed to fetch user info: \(error)")
            }
        }
    }
    
    func fetchBankConnections() {
        ServerCommunicator.shared.callMyServer(path: "/path/to/bank/connections", httpMethod: .get) { (result: Result<[BankConnection], ServerCommunicator.Error>) in
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
