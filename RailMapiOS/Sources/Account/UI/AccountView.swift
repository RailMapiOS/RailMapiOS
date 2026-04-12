//
//  AccountView.swift
//  RailMapiOS
//

import ComposableArchitecture
import SwiftUI

struct AccountView: View {
    let store: StoreOf<AccountFeature>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let user = store.user {
                    // Profile image
                    if let data = user.profileImage, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(.circle)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(user.firstName) \(user.lastName)")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let email = user.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(role: .destructive) {
                        store.send(.signOutTapped)
                        dismiss()
                    } label: {
                        Text("Se déconnecter")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                } else {
                    Text("Aucun compte")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 40)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
