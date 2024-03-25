//
//  AdditionalAccountConnectionView.swift
//  Flex
//
//  Created by Rob Harrell on 3/24/24.
//

import SwiftUI

struct AdditionalAccountConnectionView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var showMainTabView: Bool
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    AdditionalAccountConnectionView(showMainTabView: .constant(false))
}
