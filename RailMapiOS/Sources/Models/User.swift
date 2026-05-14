//
//  User.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 15/02/2025.
//

import SwiftUI

public struct User: Codable, Equatable {
    var userId: String
    var firstName: String
    var lastName: String
    var email: String?
    var profileImage: Data?
    
    public init(userId: String, firstName: String, lastName: String, email: String?, profileImage: UIImage?) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email

        if let image = profileImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            self.profileImage = imageData
        } else {
            self.profileImage = nil
        }
    }

    public init(userId: String, firstName: String, lastName: String, email: String?, profileImageData: Data?) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.profileImage = profileImageData
    }
}
