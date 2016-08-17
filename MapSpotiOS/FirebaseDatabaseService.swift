//
//  FirebaseDatabaseService.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/4/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit
import FirebaseDatabase


class FirebaseDatabaseService: NSObject {
    let databaseReference:FIRDatabaseReference
    
    init(ref:FIRDatabaseReference) {
        self.databaseReference = ref
    }
    
}
