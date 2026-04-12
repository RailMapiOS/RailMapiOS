//
//  SignInView.swift
//  RailMapiOS
//

import ComposableArchitecture
import SwiftUI

struct SignInView: View {
    let store: StoreOf<SignInFeature>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "train.side.front.car")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 80)
                    .foregroundStyle(.tint)

                Text("Se connecter")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Connectez-vous avec iCloud pour synchroniser vos trajets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if let error = store.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Button {
                    store.send(.requestPermissionTapped)
                } label: {
                    Text("Se connecter avec iCloud")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
