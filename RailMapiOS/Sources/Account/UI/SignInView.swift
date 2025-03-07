//
//  SignInView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 07/02/2025.
//

import SwiftUI
import CloudKit

struct SignInView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userStorage: UserStorage
    @ObservedObject var vm: SignInViewModel
    
    public init(userStorage: UserStorage) {
        self.vm = SignInViewModel(userStorage: userStorage)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Spacer()
                
                VStack(spacing: 10) {
                    
                    if let errorMessage = vm.errorMessage {
                        Image(systemName: "exclamationmark.icloud")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.primary)
                        
                        Text(errorMessage)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.red)
                        
                        Text("Check your device settings and try again")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                    } else {
                        if vm.isSignedInToiCloud {
                            Image(systemName: "checkmark.icloud")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary, Color.green)
                        } else {
                            Image(systemName: "person.icloud")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(.blue)
                        }
                        
                        Text("Un accès plus simple et sécurisé")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .frame(maxHeight: 100)
                    }
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
                
                if vm.isSignedInToiCloud {
                    Text("Vous êtes connecté à iCloud.")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        Task {
                            await vm.requestPermissionAndSignIn()
                        }
                    }) {
                        Text("Se connecter à iCloud")
                            .fontWeight(.bold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                    }
                }
                
                TermsAndPrivacyTextView()

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

struct TermsAndPrivacyTextView: View {
    @State private var showTermsAndPrivacyPolicy = false

    var body: some View {
        VStack {
            Text(termsText)
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showTermsAndPrivacyPolicy = true
        }
        .sheet(isPresented: $showTermsAndPrivacyPolicy) {
            TermsAndPrivacyView()
        }
    }
    
    private var termsText: AttributedString {
        var text = AttributedString("En vous inscrivant, vous acceptez nos ")
        
        var termsText = AttributedString("Conditions d'utilisation")
        termsText.foregroundColor = .blue
        termsText.underlineStyle = .single
        
        var andText = AttributedString(" et notre ")
        
        var privacyText = AttributedString("Politique de confidentialité")
        privacyText.foregroundColor = .blue
        privacyText.underlineStyle = .single
        
        var endText = AttributedString(".")
        
        text.append(termsText)
        text.append(andText)
        text.append(privacyText)
        text.append(endText)
        
        return text
    }
}


