//
//  CurrentUser.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/19/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

/*
 
 
 1)  Create a class variable as a computed type property. The class variable, like class methods in Objective-C, is something you can call without having to instantiate the class CurrentUser.
 
 2)  Nested within the class variable is a struct called Singleton.
 
 3)  Singleton wraps a static constant variable named instance. Declaring a property as static means this property only exists once. Also note that static properties in Swift are implicitly lazy, which means that Instance is not created until it’s needed. Also note that since this is a constant property, once this instance is created, it’s not going to create it a second time. This is the essence of the Singleton design pattern. The initializer is never called again once it has been instantiated.
 
 4)  Returns the computed type property.

 
*/

import Foundation
import UIKit

class CurrentUser: NSObject {
    var name = ""
    var email = ""
    var photoURL = ""
    var userID = ""
    var snapshotKey = ""
    var location = ""
    var profileImage = UIImage()
    
    //1
    class var sharedInstance: CurrentUser {
        //2
        struct Singleton {
            //3
            static let instance = CurrentUser()
        }
        //4
        return Singleton.instance
    }

    private override init() {
        
    }
    
    func setCurrentUserProperties(name: String, email: String, photoURL: String, userID: String, snapshotKey: String) {
        self.name = name
        self.email = email
        self.photoURL = photoURL
        self.userID = userID
        self.snapshotKey = snapshotKey
    }

}