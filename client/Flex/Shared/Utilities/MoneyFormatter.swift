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
    var divisor: Double = 1
    var format: String = "%.0f"

    switch absN {
    case 1_000_000...:
        suffix = "m"
        divisor = pow(10, 6)
        format = "%.1f"
    case 1_000...:
        suffix = "k"
        divisor = pow(10, 3)
        format = "%.1f"
    case 100...:
        return String(format: "$%.0f", round(n / 10) * 10)
    default:
        return String(format: "$%.0f", n)
    }

    let number = n / divisor
    let formattedNumber = String(format: format, number)
    let finalNumber = formattedNumber.hasSuffix(".0") ? String(formattedNumber.dropLast(2)) : formattedNumber

    return "$\(finalNumber)\(suffix)"
}
