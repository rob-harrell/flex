//
//  MoneyFormatter.swift
//  Flex
//
//  Created by Rob Harrell on 4/12/24.
//

import Foundation

func formatBudgetNumber(_ n: Double) -> String {
    let absN = abs(n)
    let suffix: String

    switch absN {
    case 1_000_000...:
        suffix = "m"
    case 1_000...:
        suffix = "k"
    default:
        return String(format: "$%.0f", round(n / 10) * 10)
    }

    let number = n / pow(10, (suffix == "m") ? 6 : 3)
    let formattedNumber = String(format: "%.1f", number)
    let finalNumber = formattedNumber.hasSuffix(".0") ? String(formattedNumber.dropLast(2)) : formattedNumber

    return "$\(finalNumber)\(suffix)"
}
