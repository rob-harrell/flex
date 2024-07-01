//
//  EditBudgetView.swift
//  Flex
//
//  Created by Rob Harrell on 6/23/24.
//

import SwiftUI

struct EditBudgetView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var selectedView: editBudgetSubView = .defaultView
    @State private var localMonthlySavings: Double = 0.0
    @Binding var showingEditBudgetSheet: Bool
    
    var body: some View {        
        Group {
            switch selectedView {
            case .defaultView:
                VStack (alignment: .leading) {
                    ZStack {
                        HStack {
                            Spacer()
                            Text("Edit monthly budget")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Button(action: {
                                showingEditBudgetSheet = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14))
                                    .fontWeight(.heavy)
                                    .foregroundColor(Color("slate400"))
                            }
                        }
                    }
                    .padding(.top, 16)
                    
                    VStack (alignment: .leading, spacing: 4) {
                        Text("Starting budget")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                        Text("After bills and savings")
                            .font(.system(size: 16))
                            .foregroundColor(.slate500)
                    }
                    .padding(.vertical, 8)
                    
                    EditBudgetBar(selectedView: $selectedView, localMonthlySavings: $localMonthlySavings)
                        .frame(height: 48)
                        .padding(.bottom, 48)
                            
                    
                    Button(action: {
                        withAnimation {
                            selectedView = .income
                        }
                    }) {
                        HStack {
                            Image("accrualsImage")
                                .resizable()
                                .frame(width: 64, height: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Income")
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(.slate500)
                                Text("+$\(Int(userViewModel.monthlyIncome))")
                                    .font(.system(size: 20))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.emerald500)
                            }
                            Spacer()
                            Image("editicon")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 8)
                        }
                        .padding(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.slate200, lineWidth: 0.5)
                        )
                    }
                    .padding(.bottom, 4)
                    
                    Button(action: {
                        withAnimation {
                            selectedView = .bills
                        }
                    }) {
                        HStack {
                            Image("accrualsImage")
                                .resizable()
                                .frame(width: 64, height: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bills")
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(.slate500)
                                Text("$\(Int(userViewModel.monthlyFixedSpend))")
                                    .font(.system(size: 20))
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            Image("editicon")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 8)
                        }
                        .padding(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.slate200, lineWidth: 0.5)
                        )
                    }
                    .padding(.bottom, 4)
                    
                    VStack(alignment: .leading) {
                        VStack (alignment: .leading, spacing: 4) {
                            Text("Monthly Savings")
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.slate500)
                            HStack {
                                Text("$\(Int(localMonthlySavings))")
                                    .font(.system(size: 20))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.emerald500)
                                Spacer()
                                Text(localMonthlySavings > 0 ? String(format: "%.1f%% of income", (localMonthlySavings / userViewModel.monthlyIncome) * 100) : "")
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(.slate400)
                            }
                        }
                        .padding(.bottom, -2)
                        Slider(value: $localMonthlySavings, in: 0...Double(userViewModel.monthlyIncome - userViewModel.monthlyFixedSpend), step: 1) {
                            Text("Monthly Savings")
                        } 
                        .accentColor(Color("emerald500"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.slate200, lineWidth: 0.5)
                    )
                    
                    Spacer()
                }
            case .income:
                //EditIncomeView(selectedView: $selectedView)
                EditBillsView(selectedView: $selectedView)
                
            case .bills:
                EditBillsView(selectedView: $selectedView)
            }
        }
        .onAppear {
            localMonthlySavings = userViewModel.monthlySavings
        }
        .onDisappear {
            if localMonthlySavings != userViewModel.monthlySavings {
                userViewModel.monthlySavings = localMonthlySavings
                print(userViewModel.monthlySavings)
                userViewModel.updateUserOnServer()
            }
        }
    }
        
    enum editBudgetSubView {
        case defaultView
        case income
        case bills
    }
        
}

