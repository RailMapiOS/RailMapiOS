//
//  UserStorage.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 15/02/2025.
//

import Foundation
import Security

/// Gestionnaire de stockage et d'authentification des utilisateurs
///
/// Cette classe gère la persistance des données utilisateur et l'état d'authentification
/// en utilisant `UserDefaults` pour le stockage local.
///
/// ## Fonctionnalités
/// - Sauvegarde et chargement du profil utilisateur
/// - Gestion de l'état d'authentification
/// - Notification des changements via le pattern `ObservableObject`
///
/// ## Exemple d'utilisation
/// ```
/// // Récupérer l'instance partagée
/// let storage = UserStorage.shared
///
/// // Vérifier si un utilisateur est connecté
/// if storage.isLoggedIn() {
///     // Accéder aux données utilisateur
///     let username = storage.currentUser?.username
/// }
/// ```
public class UserStorage: ObservableObject {
    /// Instance partagée pour accéder au stockage utilisateur dans toute l'application
    public static let shared = UserStorage()
    
    private let userDefaultsKey = "currentUser"
    private let isLoggedInKey = "isLoggedIn"
    
    /// L'utilisateur actuellement connecté, ou `nil` si aucun utilisateur n'est connecté
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        LogManager.info("Initialisation de UserStorage", category: "auth")
        loadUser()
    }
    
    /// Enregistre les données d'un utilisateur et définit l'état comme connecté
    ///
    /// Cette méthode encode l'objet utilisateur en JSON et le stocke dans UserDefaults.
    /// Elle met également à jour la propriété `currentUser` publiée.
    ///
    /// - Parameter user: L'objet utilisateur à sauvegarder
    public func saveUser(_ user: User) {
        LogManager.info("Tentative de sauvegarde des données utilisateur", category: "auth")
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: userDefaultsKey)
            userDefaults.set(true, forKey: isLoggedInKey)
            LogManager.info("Données utilisateur sauvegardées avec succès", category: "auth")
            
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = user
                LogManager.debug("État currentUser mis à jour sur le thread principal", category: "auth")
            }
        } else {
            LogManager.error("Échec de l'encodage des données utilisateur", category: "auth_error")
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
        LogManager.info("Tentative de chargement des données utilisateur", category: "auth")
        
        if let data = userDefaults.data(forKey: userDefaultsKey) {
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                LogManager.info("Données utilisateur chargées avec succès", category: "auth")
                
                DispatchQueue.main.async { [weak self] in
                    self?.currentUser = user
                    LogManager.debug("État currentUser mis à jour sur le thread principal", category: "auth")
                }
                return user
            } catch {
                LogManager.error("Échec du décodage des données utilisateur: \(error.localizedDescription)", category: "auth_error")
            }
        } else {
            LogManager.info("Aucune donnée utilisateur trouvée dans le stockage", category: "auth")
        }
        return nil
    }
    
    /// Supprime les données utilisateur et définit l'état comme déconnecté
    ///
    /// Cette méthode efface les données utilisateur de UserDefaults et réinitialise
    /// la propriété `currentUser` à `nil`.
    public func deleteUser() {
        LogManager.info("Suppression des données utilisateur", category: "auth")
        userDefaults.removeObject(forKey: userDefaultsKey)
        userDefaults.set(false, forKey: isLoggedInKey)
        
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = nil
            LogManager.debug("État currentUser réinitialisé sur le thread principal", category: "auth")
        }
        LogManager.info("Données utilisateur supprimées avec succès", category: "auth")
    }
    
    /// Vérifie si un utilisateur est actuellement connecté
    ///
    /// Cette méthode consulte l'état d'authentification stocké et s'assure que
    /// la propriété `currentUser` est cohérente avec cet état.
    ///
    /// - Returns: `true` si un utilisateur est connecté, sinon `false`
    public func isLoggedIn() -> Bool {
        let loggedIn = userDefaults.bool(forKey: isLoggedInKey)
        LogManager.debug("Vérification de l'état de connexion: \(loggedIn)", category: "auth")
        
        if !loggedIn {
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = nil
                LogManager.debug("État currentUser réinitialisé sur le thread principal", category: "auth")
            }
            return false
        } else {
            return true
        }
    }
}
