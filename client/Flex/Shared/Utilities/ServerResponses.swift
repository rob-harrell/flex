//
//  ServerResponses.swift
//  Flex
//
//  Created by Rob Harrell on 2/25/24.
//

import Foundation

typealias BankAccountsResponse = [BankAccountResponse]

struct OTPResponse: Decodable {
    let message: String?
    let error: String?
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

struct BankAccountResponse: Codable, Identifiable {
    let id: Int64
    let accountId: String
    let itemId: String
    let name: String
    let maskedAccountNumber: String
    let friendlyAccountName: String
    let bankName: String
    let isActive: Bool
    let logoPath: String
    let type: String
    let subType: String

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case accountId = "account_id"
        case itemId = "item_id"
        case maskedAccountNumber = "masked_account_number"
        case friendlyAccountName = "friendly_account_name"
        case bankName = "bank_name"
        case isActive = "is_active"
        case logoPath = "logo_path"
        case subType = "sub_type"
    }
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
