//
//  AccountFeature.swift
//  RailMapiOS
//

import ComposableArchitecture
import Foundation

@Reducer
struct AccountFeature {
    @ObservableState
    struct State: Equatable {
        var user: User?
    }

    enum Action {
        case onAppear
        case signOutTapped
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case signedOut
        }
    }

    @Dependency(\.userStorageClient) var userStorage

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.user = userStorage.loadUser()
                return .none

            case .signOutTapped:
                userStorage.deleteUser()
                state.user = nil
                return .send(.delegate(.signedOut))

            case .delegate:
                return .none
            }
        }
    }
}
