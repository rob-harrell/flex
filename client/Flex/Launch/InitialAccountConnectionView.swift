//
//  InitialAccountConnectionView.swift
//  Flex
//
//  Created by Rob Harrell on 3/24/24.
//

import SwiftUI

struct InitialAccountConnectionView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var showAdditionalAccountConnectionView: Bool
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    InitialAccountConnectionView(showAdditionalAccountConnectionView: .constant(false))
}
