//
//  RealmDBManager.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/25/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import Foundation
import RealmSwift

class RLMDBManager {
    
    var realm: Realm?
    
    init() {
        do {
            realm = try Realm()
        } catch let error as NSError {
            print(error)
        }

    }
    
    
//    func writeObject(object:Object) {
////        realm.addOrUpdateObject(object)
//    }
    
}
