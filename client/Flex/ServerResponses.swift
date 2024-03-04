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

struct UserInfoResponse: Codable {
    let id: Int
    let username: String
    let firstname: String
    let lastname: String
    let email: String
    let phone: String
    let monthly_income: Double
    let monthly_fixed_spend: Double
}

struct BankConnection: Codable, Identifiable {
    let id: Int
    let account_id: String
    let item_id: String
    let name: String
    let masked_account_number: String
    let created: Date
    let updated: Date
    let bank_name: String
    let is_active: Bool
}

struct UserStatusResponse: Codable {
    let userStatus: UserConnectionStatus
    let userId: String
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
