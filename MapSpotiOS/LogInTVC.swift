//
//  LogInTVC.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/26/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import RealmSwift
import Alamofire
import AlamofireImage

class LogInTVC: UITableViewController {
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView(frame: CGRectZero)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Helper Methods
    
    func failedLogInAlert() {
        let alertController = UIAlertController(title: "Log In Failed",
                                                message: "Please check your email and password.",
                                                preferredStyle: .Alert)
        let ok = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alertController.addAction(ok)
        self.presentViewController(alertController, animated: false, completion: nil)
    }
    
    //MARK: AlamoFire Methods
    /*
     Downloads the profile image from Cloudinary with AlamoFire.
 */
    func downloadProfileImageWithAlamoFire(photoURL: String, completion:(image:UIImage) -> Void) {
        Alamofire.request(.GET, photoURL)
            .responseImage { response in
                if let image = response.result.value {
                    completion(image: image)
                }
            }
    }
    
    //MARK: Realm Methods
    func getCurrentUserProfileWithRealm(completion:(results: Results<RLMUser>) -> Void) {
        let realmManager = RLMDBManager()
        guard let userID = FIRAuth.auth()?.currentUser?.uid else {return}
        completion(results: realmManager.getCurrentUserFromRealm(userID))
    }
    
    func writeUserToRealm(user: Object) {
        let realmDBManager = RLMDBManager()
        realmDBManager.realm?.beginWrite()
        realmDBManager.realm?.add(user)
        
        do {
            try realmDBManager.realm?.commitWrite()
        } catch let error as NSError {
            print(error)
        }
    }
    
    //Takes results from Realm and sets the CurrentUser Singleton.
    func setCurrentUserProfileWithRealmResults(realmResults:Results<RLMUser>) {
        CurrentUser.sharedInstance.setCurrentUserProperties(realmResults[0].name,
                                                            location: realmResults[0].location,
                                                            email: realmResults[0].email,
                                                            photoURL: realmResults[0].photoURL,
                                                            userID: realmResults[0].userID,
                                                            snapshotKey: realmResults[0].snapshotKey)
        
        guard let profileImageData = realmResults[0].profileImage else {return}
        CurrentUser.sharedInstance.profileImage = UIImage(data: profileImageData)
    }
    
    func createRLMUser(name: String, email: String, userID: String, snapshotKey: String, location: String) -> RLMUser {
        let rlmUser = RLMUser()
        rlmUser.createUser(name, email: email, userID: userID, snapshotKey: snapshotKey, location: location)
        return rlmUser
    }
    
    //MARK: Firebase Methods
    
    //Queries Firebase for the current user's profile.
    func queryCurrentUserProfileFromFirebase() {
        let firebaseOp = FirebaseOperation()
        let query = firebaseOp.firebaseDatabaseRef.ref.child("users").queryOrderedByChild("userID").queryEqualToValue(FIRAuth.auth()?.currentUser?.uid)
        firebaseOp.queryFirebaseForChildWithConstrtaints(query, firebaseDataEventType: .Value, observeSingleEventType: true) {
            (result) in
            self.setCurrentUserProfileWithFirebaseSnapshot(result)
        }
    }
    
        /*
     Gets called if the profile isn't available in Realm. It sets the CurrentUser Singleton
     from a FIRDataSnapshot. It also uses that FIRDataSnapShot to write the userprofile to Realm.
 */
    func setCurrentUserProfileWithFirebaseSnapshot(snapshot: FIRDataSnapshot) {
        for child in snapshot.children {
            guard let
                name = child.value["name"] as? String,
                email = child.value["email"] as? String,
                photoURL = child.value["profilePhotoURL"] as? String,
                userID = child.value["userID"] as? String,
                location = child.value["location"] as? String else {
                    return
            }
            
            guard photoURL != "" else {
                //If the photoURL is only "" then set the CurrentUser Singleton accordingly.
                CurrentUser.sharedInstance.setCurrentUserProperties(name,
                                                                    location: location,
                                                                    email: email,
                                                                    photoURL: "",
                                                                    userID: userID,
                                                                    snapshotKey: child.key as String)
                let user = createRLMUser(name,
                                         email: email,
                                         userID: userID,
                                         snapshotKey: child.key as String,
                                         location: location)
                writeUserToRealm(user)
                self.dismissViewControllerAnimated(true, completion: nil)
                return
            }
            //If the photoURL is available then set the CurrentUser Singleton with it.
            CurrentUser.sharedInstance.setCurrentUserProperties(name,
                                                                location: location,
                                                                email: email,
                                                                photoURL: photoURL,
                                                                userID: userID,
                                                                snapshotKey: child.key)
            CurrentUser.sharedInstance.location = location
            
            downloadProfileImageWithAlamoFire(photoURL, completion: { (image) in
                CurrentUser.sharedInstance.profileImage = image
                let user = self.createRLMUser(name,
                    email: email,
                    userID: userID,
                    snapshotKey: child.key as String,
                    location: location)
                user.photoURL = photoURL
                user.profileImage = UIImageJPEGRepresentation(image, 1.0)
                self.writeUserToRealm(user)
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        }
    }
    
    @IBAction func logInPressed(sender: AnyObject) {
        guard let email = emailTF.text, password = passwordTF.text else {return}
        FIRAuth.auth()?.signInWithEmail(email, password: password, completion: { (firebaseUser, error) in
            guard error == nil else {
                self.failedLogInAlert()
                print(error?.code)
                return
            }
            self.getCurrentUserProfileWithRealm({
                (results) in
                guard results.isEmpty == false else {
                    self.queryCurrentUserProfileFromFirebase()
                    print("Got profile from Firebase")
                    return
                }
                self.setCurrentUserProfileWithRealmResults(results)
                print("Got profile from Realm")
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        })
    }

    @IBAction func signUpPressed(sender: AnyObject) {
        
    }

    @IBAction func continueAnonymously(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func cancelPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
