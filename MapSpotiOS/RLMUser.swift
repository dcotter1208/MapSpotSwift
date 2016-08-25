//
//  RLMUser.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/25/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import Foundation
import RealmSwift

class RLMUser: Object {
    dynamic var name = ""
    dynamic var email = ""
    dynamic var photoURL = ""
    dynamic var userID = ""
    dynamic var snapshotKey = ""
    dynamic var location = ""
    dynamic var profileImage: NSData? = nil

    override static func primaryKey() -> String? {
        return "userID"
    }
    
    func createUser(name: String, email: String, userID: String, snapshotKey: String, location: String) {
        self.name = name
        self.email = email
        self.userID = userID
        self.snapshotKey = snapshotKey
        self.location = location
    }
    
    func setRLMUserProfileImageAndURL(URL: String, image: NSData) {
        self.photoURL = URL
        self.profileImage = image
    }
    
}
