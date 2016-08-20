//
//  CurrentUser.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/19/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import Foundation

class CurrentUser: NSObject {
    var name = ""
    var email = ""
    var photoURL = ""
    
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
    
    func setCurrentUserProperties(name: String, email: String, photoURL: String) {
        self.name = name
        self.email = email
        self.photoURL = photoURL
    }

}