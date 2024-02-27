//
//  PlaidLinkViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 2/25/24.
//

import Foundation
import LinkKit

class PlaidLinkViewModel: ObservableObject {
    var communicator: ServerCommunicator
    var linkToken: String?
    var handler: Handler?
    @Published var isLinkActive = false
    @Published var userStatus: UserConnectionStatus = .disconnected
    @Published var userId: String = ""
    
    init(communicator: ServerCommunicator) {
            self.communicator = communicator
        }
    
    func fetchUserStatus() {
        self.communicator.callMyServer(path: "/server/get_user_info", httpMethod: .get) {
            (result: Result<UserStatusResponse, ServerCommunicator.Error>) in
            
            switch result {
            case .success(let serverResponse):
                self.userId = serverResponse.userId
                self.userStatus = serverResponse.userStatus
            case .failure(let error):
                print(error)
            }
        }
    }

    func fetchLinkToken(completion: @escaping () -> Void) {
        self.communicator.callMyServer(path: "/server/generate_link_token", httpMethod: .post) { (result: Result<LinkTokenCreateResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let response):
                self.linkToken = response.linkToken
                if let linkToken = self.linkToken {
                        print("Fetched link token: \(linkToken)")
                    }
                completion()
            case .failure(let error):
                print(error)
            }
        }
    }

    func startLink() {
        print("startLink called")
        guard let linkToken = linkToken else { return }
        let config = createLinkConfiguration(linkToken: linkToken)

        let creationResult = Plaid.create(config)
        switch creationResult {
        case .success(let handler):
            self.handler = handler
            self.isLinkActive = true
        case .failure(let error):
            print("Handler creation error \(error)")
        }
    }

    private func createLinkConfiguration(linkToken: String) -> LinkTokenConfiguration {
        var linkTokenConfig = LinkTokenConfiguration(token: linkToken) { success in
            print("Link was finished successfully! \(success)")
            self.exchangePublicTokenForAccessToken(success.publicToken)
        }
        linkTokenConfig.onExit = { linkEvent in
            print("User exited Link early \(linkEvent)")
        }
        linkTokenConfig.onEvent = { linkEvent in
            print("Hit an event \(linkEvent.eventName)")
        }
        return linkTokenConfig
    }

    private func exchangePublicTokenForAccessToken(_ publicToken: String) {
        self.communicator.callMyServer(path: "/server/swap_public_token", httpMethod: .post, params: ["public_token": publicToken]) { (result: Result<SwapPublicTokenResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let response):
                self.isLinkActive = false
            case .failure(let error):
                print("Got an error \(error)")
            }
        }
    }
}
