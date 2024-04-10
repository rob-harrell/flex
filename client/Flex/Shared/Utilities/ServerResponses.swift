//
//  ServerResponses.swift
//  Flex
//
//  Created by Rob Harrell on 2/25/24.
//

import Foundation

typealias BankAccountsResponse = [BankAccountResponse]
typealias BudgetPreferencesResponse = [BudgetPreferenceResponse]
struct TransactionsResponse: Codable {
    let added: [TransactionResponse]
    let modified: [TransactionResponse]
    let removed: [TransactionResponse]
}

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
    let hasEnteredUserDetails: Bool
    let hasCompletedAccountCreation: Bool
    let hasCompletedNotificationSelection: Bool
    let pushNotificationsEnabled: Bool
    let smsNotificationsEnabled: Bool
    let hasEditedBudgetPreferences: Bool
    let hasCompletedBudgetCustomization: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, phone
        case monthlyIncome = "monthly_income"
        case monthlyFixedSpend = "monthly_fixed_spend"
        case birthDate = "birth_date"
        case firstName = "firstname"
        case lastName = "lastname"
        case hasEnteredUserDetails = "has_entered_user_details"
        case hasCompletedAccountCreation = "has_completed_account_creation"
        case hasCompletedNotificationSelection = "has_completed_notification_selection"
        case pushNotificationsEnabled = "push_notifications_enabled"
        case smsNotificationsEnabled = "sms_notifications_enabled"
        case hasEditedBudgetPreferences = "has_edited_budget_preferences"
        case hasCompletedBudgetCustomization = "has_completed_budget_customization"
    }
}

struct BankAccountResponse: Codable, Identifiable {
    let id: Int64
    let name: String
    let maskedAccountNumber: String
    let friendlyAccountName: String?
    let bankName: String
    let isActive: Bool
    let logoPath: String
    let type: String
    let subType: String

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case maskedAccountNumber = "masked_account_number"
        case friendlyAccountName = "friendly_account_name"
        case bankName = "bank_name"
        case isActive = "is_active"
        case logoPath = "logo_path"
        case subType = "sub_type"
    }
}

struct TransactionResponse: Codable, Identifiable {
    let amount: Double
    let authorizedDate: String?
    let category: String
    let subCategory: String
    let currencyCode: String
    let date: String
    let id: Int64
    let isRemoved: Bool
    let name: String
    let pending: Bool
    let accountId: Int64
    let merchantName: String

    enum CodingKeys: String, CodingKey {
        case amount
        case authorizedDate = "authorized_date"
        case category
        case subCategory = "sub_category"
        case currencyCode = "currency_code"
        case date
        case id
        case isRemoved = "is_removed"
        case name
        case pending
        case accountId = "account_id"
        case merchantName = "merchant_name"
    }
}

struct BudgetPreferenceResponse: Codable, Identifiable {
    let id: Int64?
    let userId: Int64
    let category: String
    let subCategory: String
    let productCategory: String
    let budgetCategory: String
    let fixedAmount: Int16?
    
    enum CodingKeys: String, CodingKey {
        case id, category
        case userId = "user_id"
        case subCategory = "sub_category"
        case productCategory = "product_category"
        case budgetCategory = "budget_category"
        case fixedAmount = "fixed_amount"
    }
}

struct UpdateBudgetPreferencesResponse: Decodable {
    let success: Bool
}

 struct LinkTokenCreateResponse: Codable {
    let linkToken: String
    let expiration: String
}
 
struct SwapPublicTokenResponse: Codable {
    let success: Bool
}

