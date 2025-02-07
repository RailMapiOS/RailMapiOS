//
//  SignInView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 07/02/2025.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 20) {
                
                Spacer()
                
                VStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.blue)
                    
                    Text("Un accès plus simple et sécurisé")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                    .frame(maxHeight: 10)
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Synchronisation sur tous vos appareils")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Partagez vos voyages avec vos amis")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Accès rapide et sécurisé")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Personnalisation de votre expérience")
                    }
                }
                .font(.headline)
                .padding(.horizontal)
                
                Spacer()
                
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            print("Authorization successful: \(authResults)")
                        case .failure(let error):
                            print("Authorization failed: \(error.localizedDescription)")
                        }
                    }
                )
                .frame(height: 50)
                .signInWithAppleButtonStyle(.black)
                .cornerRadius(10)
                .padding(.horizontal, 30)
                
                Text("En vous inscrivant, vous acceptez nos [Conditions d'utilisation](https://example.com) et notre [Politique de confidentialité](https://example.com).")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Spacer()
            }
            .padding()
            .presentationDetents([.large])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SignInView()
}
