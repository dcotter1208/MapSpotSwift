//
//  FirebaseOperation.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/4/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Firebase


//SetValueForChild
//DeleteChildValue
//UpdateChildValue
//QueryWithoutConstraints
//QueryWithConstraints
//ListenForChangesToChildNode

class FirebaseOperation: NSObject {
    
    let firebaseDatabaseRef = FIRDatabase.database().reference()

    func getSnapshotKeyFromRef(firebaseChildRef: FIRDatabaseReference) -> String {
        let snapshotKey = "\(firebaseChildRef)".stringByReplacingOccurrencesOfString("https://mapspotswift.firebaseio.com/users/", withString: "")
        return snapshotKey
    }
    
    func createUserProfileWithFirebase(usersRef: FIRDatabaseReference, userProfile: [String: String]) {
            print(usersRef)
            usersRef.setValue(userProfile)
    }
    
    //Creates a new value for a specified child
    func setValueForChild(child: String, value: [String: AnyObject]) {
        let childRef = firebaseDatabaseRef.child(child).childByAutoId()
        childRef.setValue(value)
    }
    
    //Deletes a value for a specified child.
    func deleteValueForChild(child: String, childKey: String) {
        let childToRemove = firebaseDatabaseRef.child(child).child(childKey)
        childToRemove.removeValue()
    }
    
    //Updates a specified child node
    func updateChildValue(child: String, childKey:String, nodeToUpdate: [String: AnyObject]) {
        let childRef = firebaseDatabaseRef.child(child)
        let childUpdates = [childKey:nodeToUpdate]
        childRef.updateChildValues(childUpdates)
    }
    
    func queryFirebaseForChildWithoutConstrints(child: String, firebaseDataEventType: FIRDataEventType, completion: (result: FIRDataSnapshot) -> Void) {
        let childRef = firebaseDatabaseRef.child(child)
        childRef.observeEventType(firebaseDataEventType) {
            (snapshot) in
            completion(result: snapshot)
        }
    }

    //Accepts a query to listen for a change.
    func listenForChildNodeChanges(query: FIRDatabaseQuery, completion:(result:FIRDataSnapshot)-> Void) {
        query.observeEventType(FIRDataEventType.ChildChanged) {
            (snapshot) in
            completion(result: snapshot)
        }
    }
    
    //Accepts a query with contraints to query Firebase
    func queryFirebaseForChildWithConstrtaints(query:FIRDatabaseQuery, firebaseDataEventType: FIRDataEventType, observeSingleEventType: Bool, completion:(result: FIRDataSnapshot) -> Void) {
        if observeSingleEventType {
            query.observeSingleEventOfType(firebaseDataEventType, withBlock: { (snapshot) in
                completion(result: snapshot)
            })
        } else {
            query.observeEventType(firebaseDataEventType, withBlock: { (snapshot) in
                completion(result: snapshot)
            })
        }
    }
    
    //END
}
