//
//  SignInViewModel.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 21/02/2025.
//

import SwiftUI
import CloudKit

@MainActor
class SignInViewModel: ObservableObject {
    @Published var isSignedInToiCloud = false
    @Published var errorMessage: String? = nil
    @Published var name: String = ""
    @Published var status: Bool = false

    init() {
        Task {
            await getiCloudStatus()
//
//            await fetchiCloudRecordID()
        }
    }

    private func getiCloudStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available:
                isSignedInToiCloud = true
                await fetchiCloudRecordID()
            default:
                break
            }
        } catch {
            errorMessage = "Erreur lors de la vérification du statut iCloud : \(error.localizedDescription)"
        }
    }

    enum CloudKitError: String, LocalizedError {
        case iCloudAccountNotfound = "Compte iCloud non trouvé"
        case iCloudAccountNotDetermined = "Statut du compte iCloud indéterminé"
        case iCloudAccountRestricted = "Compte iCloud restreint"
        case iCloudAccountUnknown = "Erreur inconnue avec le compte iCloud"
    }

    func fetchiCloudRecordID() async {
        do {
            let id = try await CKContainer.default().userRecordID()
            await discoveriCloudUser(id: id)
        } catch {
            errorMessage = "Erreur lors de la récupération de l'ID d'enregistrement : \(error.localizedDescription)"
        }
    }
    
    func requestPermissionAndSignIn() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available:
                isSignedInToiCloud = true
                await fetchiCloudRecordID()
            case .noAccount:
                errorMessage = CloudKitError.iCloudAccountNotfound.rawValue
            case .couldNotDetermine:
                errorMessage = CloudKitError.iCloudAccountNotDetermined.rawValue
            case .restricted:
                errorMessage = CloudKitError.iCloudAccountRestricted.rawValue
            default:
                errorMessage = CloudKitError.iCloudAccountUnknown.rawValue
            }
        } catch {
            errorMessage = "Erreur lors de la vérification du statut iCloud : \(error.localizedDescription)"
        }
    }

    private func discoveriCloudUser(id: CKRecord.ID) async {
        do {
            let participant = try await CKContainer.default().shareParticipant(forUserRecordID: id)
            if let name = participant.userIdentity.nameComponents?.givenName {
                self.name = name
                print("Nom d'utilisateur : \(name)") // TODO: Enregistrer dans les informations utilisateur
            }
        } catch {
            errorMessage = "Erreur lors de la découverte de l'utilisateur : \(error.localizedDescription)"
        }
    }
}
