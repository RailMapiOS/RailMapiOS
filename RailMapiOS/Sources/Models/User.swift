//
//  User.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 15/02/2025.
//

import AuthenticationServices
import SwiftUI

struct User {
    var userId: String
    var firstName: String
    var lastName: String
    var email: String
    var profileImage: UIImage?
    
    init?(credentials: ASAuthorizationAppleIDCredential) {
        guard
            let emailAddress = credentials.email,
        let firstName = credentials.fullName?.givenName,
        let lastName = credentials.fullName?.familyName
        else { return nil }
        
        self.userId = credentials.user
        self.firstName = firstName
        self.lastName = lastName
        self.email = emailAddress
        self.profileImage = nil
    }
    
    public init(userId: String, firstName: String, lastName: String, email: String, profileImage: UIImage?) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.profileImage = profileImage
    }
}
