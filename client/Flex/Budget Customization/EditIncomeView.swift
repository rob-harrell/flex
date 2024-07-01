//
//  IncomeConfirmationView.swift
//  Flex
//
//  Created by Rob Harrell on 4/27/24.
//

import SwiftUI
import LinkKit

struct EditIncomeView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var dateViewModel: DateViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var plaidLinkViewModel: PlaidLinkViewModel
    @State private var manualIncomeString: String = ""
    @State private var removedIncomes: [String: Bool] = ["work": false, "accruals": false, "benefits": false, "pension": false]
    @State private var isPresentingLink = false
    @State private var linkController: LinkController?
    @FocusState private var isFocused: Bool
    let nextAction: () -> Void
    let backAction: () -> Void

    var body: some View {
        let incomeSources: [(name: String, income: Double, imageName: String)] = [
            ("work", budgetViewModel.recentWorkIncome, "workImage"),
            ("accruals", budgetViewModel.recentAccrualsIncome, "accrualsImage"),
            ("benefits", budgetViewModel.recentBenefitsIncome, "benefitsImage"),
            ("pension", budgetViewModel.recentPensionIncome, "pensionImage")
        ]
        
        ZStack {
            HStack {
                Spacer()
                Text("Confirm monthly income")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            HStack {
                Button(action: {
                    self.backAction()
                }) {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .frame(width: 12, height: 21)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.bottom, 8)
        
        ScrollView {
            VStack (alignment: .leading) {
                Rectangle()
                    .fill(Color.emerald300)
                    .frame(height: 48)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.emerald600, lineWidth: 0.5)
                    )
                HStack {
                    Text("+$\(Int(userViewModel.monthlyIncome))")
                        .foregroundColor(Color.emerald500)
                        .padding(.horizontal, -2)
                        .padding(.trailing, -2)
                    Text("income expected")
                    Spacer()
                }
                .font(.system(size: 16))
                .fontWeight(.medium)
                .padding(.top, 4)
                
                
                Divider()
                    .foregroundColor(.slate)
                    .padding(.vertical)
                
                HStack {
                    VStack (alignment: .leading) {
                        Text("Income sources")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.bottom, 4)
                        let filteredAccounts = userViewModel.bankAccounts.filter { $0.subType == "checking" || $0.subType == "savings" }
                        ForEach(Array(filteredAccounts.enumerated()), id: \.element.id) { index, account in
                            Text("\(account.bankName) \(account.maskedAccountNumber)\(index < filteredAccounts.count - 1 ? "," : "")")
                                .font(.system(size: 14))
                                .foregroundColor(Color.slate500)
                        }
                    }
                    Spacer()
                    Button(action: {
                        plaidLinkViewModel.fetchLinkToken (userId: userViewModel.id, sessionToken: userViewModel.sessionToken) {
                            isPresentingLink = true
                        }
                    }) {
                        Image(.addButton)
                    }
                }
                .padding(.bottom, 12)
                
                if userViewModel.hasCheckingOrSavings {
                    ForEach(incomeSources, id: \.name) { source in
                        if source.income > 0 {
                            HStack {
                                Image(source.imageName)
                                    .resizable()
                                    .frame(width: 64, height: 64)
                                VStack (alignment: .leading) {
                                    Text(source.name.capitalized)
                                        .font(.system(size: 14))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.slate500)
                                    Text("\(formatBudgetNumber(source.income))")
                                        .fontWeight(.medium)
                                }
                                Spacer()
                                if removedIncomes[source.name] ?? false {
                                    Button(action: {
                                        userViewModel.monthlyIncome += source.income
                                        removedIncomes[source.name] = false
                                    }) {
                                        Text("+ Add")
                                            .font(.system(size: 14))
                                            .fontWeight(.medium)
                                            .padding(8)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                            .cornerRadius(16)
                                    }
                                } else {
                                    Button(action: {
                                        userViewModel.monthlyIncome -= source.income
                                        removedIncomes[source.name] = true
                                    }) {
                                        Text("Remove")
                                            .font(.system(size: 14))
                                            .fontWeight(.medium)
                                            .padding(8)
                                            .background(Color.slate100)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.bottom, 12)
                        }
                    }
                }
                
                HStack {
                    Image(.pen)
                        .resizable()
                        .frame(width: 64, height: 64)
                    VStack (alignment: .leading, spacing: 0) {
                        Text("Manual income")
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(Color.slate500)
                        HStack (spacing: 0) {
                            Text("$")
                                .foregroundColor(manualIncomeString.isEmpty ? .slate500 : .black)
                            ZStack(alignment: .leading) {
                                if manualIncomeString.isEmpty && !isFocused {
                                    Text("0")
                                        .foregroundColor(.slate500)
                                }
                                TextField("", text: $manualIncomeString, onEditingChanged: { editing in
                                    self.isFocused = editing
                                })
                                .keyboardType(.decimalPad)
                                .focused($isFocused)
                            }
                        }
                        .fontWeight(.medium)
                    }
                    if isFocused {
                        Button(action: {
                            if let value = Double(manualIncomeString), value > 0 {
                                userViewModel.monthlyIncome = budgetViewModel.totalRecentIncome + value
                                print(userViewModel.monthlyIncome)
                                isFocused = false
                            } else {
                                // Handle invalid manual income
                            }
                        }) {
                            Text("Done")
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                        .disabled(!(Double(manualIncomeString) != nil && Double(manualIncomeString)! > 0))
                    }
                }
                
                Divider()
                    .foregroundColor(.slate)
                    .padding(.vertical)
                
                Text("Cash-outs from Zelle, Venmo, Cash App, and other payment apps will appear in your actual income to offset reimbursements. Bank transfers will not be included.")
                    .font(.system(size: 14))
                    .foregroundColor(Color.slate500)
                    .padding(.bottom, 16)
                    .lineSpacing(4.0)
            }
        }
        .sheet(
            isPresented: $isPresentingLink,
            onDismiss: {
                isPresentingLink = false
            },
            content: {
                let createResult = createHandler()
                switch createResult {
                case .failure(let createError):
                    Text("Link Creation Error: \(createError.localizedDescription)")
                        .font(.title2)
                case .success(let handler):
                    LinkController(handler: handler)
                }
            }
        )
        Button(action: {
            nextAction()
            userViewModel.updateUserOnServer()
        }) {
            Text("Next")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(12)
        }
        .padding(.top)
    }
    
    private func createHandler() -> Result<Handler, Error> {
        guard let linkToken = plaidLinkViewModel.linkToken else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Link token is not set"])
            return .failure(error)
        }
        let configuration = plaidLinkViewModel.createLinkConfiguration(linkToken: linkToken, userId: userViewModel.id, sessionToken: userViewModel.sessionToken) {
            userViewModel.fetchBankAccountsFromServer() { success in
                if success {
                    print("Successfully fetched bank accounts for user \(self.userViewModel.id)")
                    budgetViewModel.fetchNewTransactionsFromServer(userId: self.userViewModel.id) { success in
                        if success {
                            print("Successfully fetched new transactions for user \(self.userViewModel.id)")
                            dateViewModel.updateAllTransactionDates()
                            budgetViewModel.calculateSelectedMonthBudgetMetrics(for: dateViewModel.selectedMonth, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
                            budgetViewModel.calculateRecentBudgetStats()
                            userViewModel.monthlyIncome = budgetViewModel.totalRecentIncome
                        } else {
                            print("Failed to fetch new transactions for user \(self.userViewModel.id)")
                        }
                    }
                } else {
                    print("Failed to fetch bank accounts for user \(self.userViewModel.id)")
                }
            }
        }

        // This only results in an error if the token is malformed.
        return Plaid.create(configuration).mapError { $0 as Error }
    }
}

#Preview {
    EditIncomeView(nextAction: {}, backAction: {})
}
