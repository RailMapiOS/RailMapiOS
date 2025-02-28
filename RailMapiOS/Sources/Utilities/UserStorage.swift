//
//  UserStorage.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 15/02/2025.
//

import Foundation
import Security


public class UserStorage: ObservableObject {
    private let userDefaultsKey = "currentUser"
    private let isLoggedInKey = "isLoggedIn"
    
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    
    public func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: userDefaultsKey)
            userDefaults.set(true, forKey: isLoggedInKey)
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = user
            }
        }
    }
    
    public func loadUser() -> User? {
        if let data = userDefaults.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = user
            }
            return user
        }
        return nil
    }
    
    public func deleteUser() {
        userDefaults.removeObject(forKey: userDefaultsKey)
        userDefaults.set(false, forKey: isLoggedInKey)
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = nil
        }
    }
    
    public func isLoggedIn() -> Bool {
        if !userDefaults.bool(forKey: isLoggedInKey) {
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = nil
            }
            return false
        } else {
            return true
        }
    }
}

