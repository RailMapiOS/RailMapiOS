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
    @EnvironmentObject var router: Router
    @ObservedObject var viewModel: SignInViewModel
    
    public init(userStorage: UserStorage = UserStorage.shared) {
        self.viewModel = SignInViewModel(userStorage: userStorage)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Spacer()
                
                VStack(spacing: 10) {
                    
                    if let errorMessage = viewModel.errorMessage {
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
                        if viewModel.isSignedInToiCloud {
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
                        
                        Text("Fast and secure access")
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
                        Text("Sync across all your devices")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Share your trips with your friends")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Fast and secure access")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Personalize your experience")
                    }
                }
                .font(.headline)
                .padding(.horizontal)
                
                Spacer()
                
                if viewModel.isSignedInToiCloud {
                    Text("You are signed in to iCloud.")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    Button {
                        Task {
                            await viewModel.requestPermissionAndSignIn()
                        }
                    } label: {
                        Text("Sign in to iCloud")
                            .fontWeight(.bold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 30)
                }
                
                TermsAndPrivacyTextView()

                 Spacer()
            }
            .padding()
            .presentationDetents([.large])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        router.dismissSheet()
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


