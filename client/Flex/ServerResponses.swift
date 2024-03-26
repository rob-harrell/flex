//
//  ServerResponses.swift
//  Flex
//
//  Created by Rob Harrell on 2/25/24.
//

import Foundation

enum UserConnectionStatus: String, Codable {
    case connected
    case disconnected
}

struct VerificationResponse: Decodable {
    let userId: Int64
    let sessionToken: String
    let isExistingUser: Bool
}

struct UserInfoResponse: Codable {
    let id: Int64
    let firstName: String
    let lastName: String
    let phone: String
    let monthlyIncome: Double
    let monthlyFixedSpend: Double
    let birthDate: String
    
    enum CodingKeys: String, CodingKey {
        case id, phone
        case monthlyIncome = "monthly_income"
        case monthlyFixedSpend = "monthly_fixed_spend"
        case birthDate = "birth_date"
        case firstName = "firstname"
        case lastName = "lastname"
    }
}

struct BankConnection: Codable, Identifiable {
    let id: Int64
    let account_id: String
    let item_id: String
    let name: String
    let masked_account_number: String
    let friendly_acount_name: String
    let bank_name: String
    let is_active: Bool
    let logo_path: String
}

 struct LinkTokenCreateResponse: Codable {
    let linkToken: String
    let expiration: String
}
 
struct SwapPublicTokenResponse: Codable {
    let success: Bool
}

struct SimpleAuthResponse: Codable{
    let accountName: String
    let accountMask: String
    let routingNumber: String
}
