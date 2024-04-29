//
//  FinalConfirmationView.swift
//  Flex
//
//  Created by Rob Harrell on 4/27/24.
//

import SwiftUI

struct FinalConfirmationView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel

    let doneAction: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("First, set your average monthly income")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            Text("See if this monthly average looks right, or edit later. Past months will show actual income.")
                .font(.body)
                .foregroundColor(Color.slate500)
                .padding(.bottom, 20)

            Spacer()

            Button(action: {
                doneAction()
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    FinalConfirmationView(doneAction: {})
        .environmentObject(BudgetViewModel())
}
