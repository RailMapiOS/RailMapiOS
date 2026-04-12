//
//  UserStorageClient.swift
//  RailMapiOS
//
//  TCA Dependency wrapping UserStorage.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct UserStorageClient {
    var loadUser: @Sendable () -> User? = { nil }
    var saveUser: @Sendable (_ user: User) -> Void
    var deleteUser: @Sendable () -> Void
    var isLoggedIn: @Sendable () -> Bool = { false }
}

extension UserStorageClient: DependencyKey {
    static let liveValue = Self(
        loadUser: { UserStorage.shared.loadUser() },
        saveUser: { user in UserStorage.shared.saveUser(user) },
        deleteUser: { UserStorage.shared.deleteUser() },
        isLoggedIn: { UserStorage.shared.isLoggedIn() }
    )
}

extension DependencyValues {
    var userStorageClient: UserStorageClient {
        get { self[UserStorageClient.self] }
        set { self[UserStorageClient.self] = newValue }
    }
}
