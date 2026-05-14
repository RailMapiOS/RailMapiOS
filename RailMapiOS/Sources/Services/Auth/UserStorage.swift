//
//  UserStorage.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 15/02/2025.
//

import Foundation
import Security
import SwiftUI
import Combine

/// Gestionnaire de stockage et d'authentification des utilisateurs
///
/// Cette classe gère la persistance des données utilisateur et l'état d'authentification
/// en utilisant `UserDefaults` pour le stockage local.
public final class UserStorage: ObservableObject, @unchecked Sendable {
    /// Instance partagée pour accéder au stockage utilisateur dans toute l'application
    public static let shared = UserStorage()
    
    private let userDefaultsKey = "currentUser"
    private let isLoggedInKey = "isLoggedIn"
    
    /// L'utilisateur actuellement connecté, ou `nil` si aucun utilisateur n'est connecté
    @Published private(set) var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "com.railmap.userstorage", attributes: .concurrent)
    
    private init() {
        LogManager.info("Initialisation de UserStorage", category: "auth")
        loadUser()
    }
    
    
    /// Enregistre les données d'un utilisateur et définit l'état comme connecté
    ///
    /// Cette méthode encode l'objet utilisateur en JSON et le stocke dans UserDefaults.
    /// Elle met également à jour la propriété `currentUser`.
    ///
    /// - Parameter user: L'objet utilisateur à sauvegarder
    public func saveUser(_ user: User) {
        queue.async(flags: .barrier) { [self] in
            LogManager.info("Attempting to save user data", category: "auth")
            if let encoded = try? JSONEncoder().encode(user) {
                userDefaults.set(encoded, forKey: userDefaultsKey)
                userDefaults.set(true, forKey: isLoggedInKey)
                LogManager.info("User data saved successfully", category: "auth")

                self.currentUser = user
                LogManager.debug("currentUser state updated", category: "auth")
            } else {
                LogManager.error("Failed to encode user data", category: "auth_error")
            }
        }
    }
    
    /// Charge les données utilisateur depuis le stockage local
    ///
    /// Cette méthode tente de récupérer et décoder les données utilisateur stockées.
    /// Si les données sont trouvées, la propriété `currentUser` est mise à jour.
    ///
    /// - Returns: L'objet utilisateur chargé, ou `nil` si aucune donnée n'est trouvée ou si le décodage échoue
    @discardableResult
    public func loadUser() -> User? {
        var result: User?
        
        queue.sync {
            LogManager.info("Attempting to load user data", category: "auth")

            if let data = userDefaults.data(forKey: userDefaultsKey) {
                do {
                    let user = try JSONDecoder().decode(User.self, from: data)
                    LogManager.info("User data loaded successfully", category: "auth")

                    self.currentUser = user
                    result = user
                    LogManager.debug("currentUser state updated", category: "auth")
                } catch {
                    LogManager.error("Failed to decode user data: \(error.localizedDescription)", category: "auth_error")
                }
            } else {
                LogManager.info("No user data found in storage", category: "auth")
            }
        }
        
        return result
    }
    
    /// Supprime les données utilisateur et définit l'état comme déconnecté
    ///
    /// Cette méthode efface les données utilisateur de UserDefaults et réinitialise
    /// la propriété `currentUser` à `nil`.
    public func deleteUser() {
        queue.async(flags: .barrier) { [self] in
            LogManager.info("Deleting user data", category: "auth")
            userDefaults.removeObject(forKey: userDefaultsKey)
            userDefaults.set(false, forKey: isLoggedInKey)

            self.currentUser = nil
            LogManager.debug("currentUser state reset", category: "auth")
            LogManager.info("User data deleted successfully", category: "auth")
        }
    }
    
    /// Vérifie si un utilisateur est actuellement connecté
    ///
    /// Cette méthode consulte l'état d'authentification stocké et s'assure que
    /// la propriété `currentUser` est cohérente avec cet état.
    ///
    /// - Returns: `true` si un utilisateur est connecté, sinon `false`
    public func isLoggedIn() -> Bool {
        var loggedIn = false
        
        queue.sync {
            loggedIn = userDefaults.bool(forKey: isLoggedInKey)
            LogManager.debug("Checking sign-in state: \(loggedIn)", category: "auth")

            if !loggedIn {
                self.currentUser = nil
                LogManager.debug("currentUser state reset", category: "auth")
            }
        }
        
        return loggedIn
    }
}
