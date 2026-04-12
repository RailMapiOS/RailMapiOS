//
//  SignInFeature.swift
//  RailMapiOS
//

import ComposableArchitecture
import CloudKit
import Contacts
import Foundation

@Reducer
struct SignInFeature {
    @ObservableState
    struct State: Equatable {
        var isSignedInToiCloud = false
        var errorMessage: String?
        var user: User?
    }

    enum Action {
        case requestPermissionTapped
        case iCloudStatusChecked(Bool)
        case iCloudError(String)
        case userDiscovered(User)
        case contactInfoFetched(Data?)
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case signedIn(User)
        }
    }

    @Dependency(\.userStorageClient) var userStorage

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .requestPermissionTapped:
                return .run { send in
                    do {
                        let status = try await CKContainer.default().accountStatus()
                        switch status {
                        case .available:
                            await send(.iCloudStatusChecked(true))
                        case .noAccount:
                            await send(.iCloudError("Compte iCloud non trouvé"))
                        case .couldNotDetermine:
                            await send(.iCloudError("Statut du compte iCloud indéterminé"))
                        case .restricted:
                            await send(.iCloudError("Compte iCloud restreint"))
                        default:
                            await send(.iCloudError("Erreur inconnue avec le compte iCloud"))
                        }
                    } catch {
                        await send(.iCloudError(error.localizedDescription))
                    }
                }

            case .iCloudStatusChecked(let available):
                state.isSignedInToiCloud = available
                guard available else { return .none }
                return .run { send in
                    do {
                        let recordID = try await CKContainer.default().userRecordID()
                        let participant = try await CKContainer.default().shareParticipant(forUserRecordID: recordID)

                        if let nameComponents = participant.userIdentity.nameComponents,
                           let givenName = nameComponents.givenName,
                           let familyName = nameComponents.familyName {
                            let user = User(
                                userId: participant.participantID.description,
                                firstName: givenName,
                                lastName: familyName,
                                email: participant.userIdentity.lookupInfo?.emailAddress,
                                profileImageData: nil
                            )
                            await send(.userDiscovered(user))
                        }
                    } catch {
                        await send(.iCloudError(error.localizedDescription))
                    }
                }

            case .iCloudError(let message):
                state.errorMessage = message
                return .none

            case .userDiscovered(let user):
                state.user = user
                return .run { [user] send in
                    let imageData = await Self.fetchContactImage(for: user)
                    await send(.contactInfoFetched(imageData))
                }

            case .contactInfoFetched(let imageData):
                state.user?.profileImage = imageData
                if let user = state.user {
                    userStorage.saveUser(user)
                    return .send(.delegate(.signedIn(user)))
                }
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Contact Fetching (isolated helper)

    private static func fetchContactImage(for user: User) async -> Data? {
        await withCheckedContinuation { continuation in
            let store = CNContactStore()
            store.requestAccess(for: .contacts) { granted, _ in
                guard granted else {
                    continuation.resume(returning: nil)
                    return
                }

                let predicate = CNContact.predicateForContacts(matchingName: "\(user.firstName) \(user.lastName)")
                let keysToFetch: [CNKeyDescriptor] = [CNContactThumbnailImageDataKey as CNKeyDescriptor]
                let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
                fetchRequest.predicate = predicate

                var imageData: Data?
                do {
                    try store.enumerateContacts(with: fetchRequest) { contact, stop in
                        if let data = contact.thumbnailImageData {
                            imageData = data
                            stop.pointee = true
                        }
                    }
                } catch {}
                continuation.resume(returning: imageData)
            }
        }
    }
}
