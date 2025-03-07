//
//  SignInViewModel.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 21/02/2025.
//

import SwiftUI
import CloudKit
import Contacts

@MainActor
class SignInViewModel: ObservableObject {
    @Published var isSignedInToiCloud = false
    @Published var errorMessage: String? = nil
    
    private var user: User? = nil
    private let userStorage: UserStorage
    
    init(userStorage: UserStorage) {
        self.userStorage = userStorage
    }
    
    private func getiCloudStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available:
                DispatchQueue.main.async { [weak self] in
                    self?.isSignedInToiCloud = true
                }
                await fetchiCloudRecordID()
            default:
                break
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Erreur lors de la vérification du statut iCloud : \(error.localizedDescription)"
            }
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
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Erreur lors de la récupération de l'ID d'enregistrement : \(error.localizedDescription)"
            }
        }
    }
    
    func requestPermissionAndSignIn() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available:
                DispatchQueue.main.async { [weak self] in
                    self?.isSignedInToiCloud = true
                }
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
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Erreur lors de la vérification du statut iCloud : \(error.localizedDescription)"
            }
        }
    }
    
    private func discoveriCloudUser(id: CKRecord.ID) async {
        do {
            let participant = try await CKContainer.default().shareParticipant(forUserRecordID: id)
            
            if let nameComponents = participant.userIdentity.nameComponents,
               let givenName = nameComponents.givenName,
               let familyName = nameComponents.familyName {
                DispatchQueue.main.async { [weak self] in
                    self?.user = User(userId: participant.participantID.description, firstName: givenName, lastName: familyName, email: participant.userIdentity.lookupInfo?.emailAddress , profileImage: nil)
                }
            }
            
            await fetchUserContactInfo(with: participant.userIdentity)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Erreur lors de la découverte de l'utilisateur : \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchUserContactInfo(with userIdentity: CKUserIdentity) async {
        print("Fetch the user's phone number and email if available")

        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            guard granted else {
                self?.errorMessage = "Accès aux contacts refusé."
                return
            }
            
            let predicate: NSPredicate?
            
            if let phoneNumberString = userIdentity.lookupInfo?.phoneNumber {
                print("Predicate uses phone number")
                predicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: phoneNumberString))
            } else if let givenName = userIdentity.nameComponents?.givenName,
                      let familyName = userIdentity.nameComponents?.familyName {
                print("Predicate uses name")
                predicate = CNContact.predicateForContacts(matchingName: "\(givenName) \(familyName)")
            } else {
                return
            }
            
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactThumbnailImageDataKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor
            ]
            
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
            fetchRequest.predicate = predicate
            
            do {
                try store.enumerateContacts(with: fetchRequest) { [weak self] contact, stop in
                    if let imageData = contact.thumbnailImageData {
                        print("User info founded: \(self?.user)")

                        self?.user?.profileImage = imageData
                            if let user = self?.user {
                                print("user info saved")
                                self?.userStorage.saveUser(user)
                        }
                    }
                    stop.pointee = true
                }
            } catch {
                self?.errorMessage = "Erreur lors de la récupération des informations de contact : \(error.localizedDescription)"
            }
        }
    }
}
