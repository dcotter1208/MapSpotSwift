//
//  User.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/20/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import Foundation
import UIKit

class User {
    var name: String
    var email: String
    var photoURL: String?
    var profileImage = UIImage()
    
    init(name: String, email: String, photoURL: String?) {
        self.name = name
        self.email = email
        self.photoURL = photoURL
    }
    
}
