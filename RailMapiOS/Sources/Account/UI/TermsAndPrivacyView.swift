//
//  TermsAndPrivacyView.swift
//  RailMapiOS
//
//  Legal copy. Strings flow through the catalog so each language gets a
//  proper localized version. The English text here is the source of truth;
//  fr/en-GB/es/ca/de/it translations are filled in via Xcode's catalog editor.
//

import SwiftUI

struct TermsAndPrivacyView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("TERMS OF USE AND PRIVACY POLICY")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)

                    Group {
                        Text("TERMS OF USE")
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("1. Acceptance of terms")
                            .fontWeight(.bold)
                        Text("By downloading and using the RailMap app for iOS, you agree to be bound by these terms of use. If you do not accept these terms, please do not use our app.")

                        Text("2. Use of the app")
                            .fontWeight(.bold)
                        Text("RailMap is provided for your personal, non-commercial use. You agree not to modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell any information obtained from the app.")

                        Text("3. Intellectual property")
                            .fontWeight(.bold)
                        Text("All intellectual property rights relating to the RailMap app and its content belong to their respective owners and are protected by applicable laws.")

                        Text("4. Limitation of liability")
                            .fontWeight(.bold)
                        Text("The RailMap app is provided \"as is\" without warranty of any kind. We do not guarantee that the app will be error-free or continuously available.")
                    }

                    Group {
                        Text("PRIVACY POLICY")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.top, 20)

                        Text("1. Information collection")
                            .fontWeight(.bold)
                        Text("Our RailMap app does not collect any personal information from users. We neither store nor process any user data on our backend servers.")

                        Text("2. Location data")
                            .fontWeight(.bold)
                        Text("If you grant access to your location, this data is used only locally on your device to improve your navigation experience and is never transmitted to our servers.")

                        Text("3. Device information")
                            .fontWeight(.bold)
                        Text("Certain non-personal technical information (such as device model and iOS version) may be collected automatically to ensure app compatibility, but this data is not associated with your identity.")

                        Text("4. Security")
                            .fontWeight(.bold)
                        Text("Although we do not collect any personal data, we take the security of our app seriously and implement appropriate measures to protect your user experience.")

                        Text("5. Policy changes")
                            .fontWeight(.bold)
                        Text("We reserve the right to modify this privacy policy at any time. Changes will be published in the app and take effect immediately.")

                        Text("6. Contact")
                            .fontWeight(.bold)
                        Text("For any questions regarding this privacy policy, please contact us at: contact@railmap-app.com")
                    }

                    Text("Last updated: February 28, 2025")
                        .italic()
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarTitle("Legal", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct TermsAndPrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        TermsAndPrivacyView()
    }
}
