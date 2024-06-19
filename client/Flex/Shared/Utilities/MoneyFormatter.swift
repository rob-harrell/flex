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
    let sign = n < 0 ? "-" : ""

    switch absN {
    case 10_000_000...:
        suffix = "m"
        divisor = pow(10, 6)
        format = "%.1f"
    case 1_000_000...9_999_999:
        suffix = "m"
        divisor = pow(10, 6)
        format = "%.2f"
    case 100_000...999_999:
        suffix = "k"
        divisor = pow(10, 3)
        format = "%.0f"
    case 10_000...99_999:
        suffix = "k"
        divisor = pow(10, 3)
        format = "%.1f"
    case 1_000...9_999:
        suffix = "k"
        divisor = pow(10, 3)
        format = "%.1f"
    case 0...999:
        return "\(sign)$\(String(format: "%.0f", absN))"
    default:
        return "\(sign)$\(String(format: "%.0f", absN))"
    }

    let number = absN / divisor
    let formattedNumber = String(format: format, number)
    let finalNumber = formattedNumber.hasSuffix(".0") ? String(formattedNumber.dropLast(2)) : formattedNumber

    return "\(sign)$\(finalNumber)\(suffix)"
}
