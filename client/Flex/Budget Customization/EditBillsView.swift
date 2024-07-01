//
//  FixedSpendConfigView.swift
//  Flex
//
//  Created by Rob Harrell on 5/15/24.
//

import SwiftUI

struct EditBillsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var selectedView: EditBudgetView.editBudgetSubView
    
    var body: some View {
        Text("Bills config view")
    }
}


