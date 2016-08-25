//
//  UserProfileVC.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/21/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import Alamofire
import AlamofireImage

class UserProfileVC: UIViewController, UpdateCurrentUserDelegate {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    var anonymouslyLoggedIn: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUserProfile()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func setEditProfileTVCDelegate() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let editProfileTVC = storyboard.instantiateViewControllerWithIdentifier("EditProfileTVC") as! EditProfileTVC
        editProfileTVC.delegate = self
    }
    
    func updateCurrentUserSingleton(photoURL: String, name: String, location: String, profileImage: UIImage?) {
        self.name.text = name
        self.locationLabel.text = location
        guard profileImage != nil else {
            return
        }
        self.profileImage.image = profileImage
    }

    func setUserProfile() {
        name.text = CurrentUser.sharedInstance.name
        locationLabel.text = CurrentUser.sharedInstance.location
        guard CurrentUser.sharedInstance.profileImage != nil else {
            profileImage.image = UIImage(named: "default_user")
            return
        }
        profileImage.image = CurrentUser.sharedInstance.profileImage
    }

    /*
     Logs a user in anonymously. Called in queryCurrentUserFromFirebase func
     if a user isn't already logged into their own account.
     */
    func loginWithAnonymousUser(completion:(anonymousUserID: String)-> Void) {
        FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (user, error) in
            if error != nil {
                print(error)
            } else {
                guard let userID = FIRAuth.auth()?.currentUser?.uid else {
                    return
                }
                completion(anonymousUserID: userID)
            }
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editProfileSegue" {
            let destinationVC = segue.destinationViewController as! EditProfileTVC
            destinationVC.delegate = self
        }
    }

    @IBAction func signOut(sender: AnyObject) {
        do {
            try FIRAuth.auth()?.signOut()
            loginWithAnonymousUser({
                (anonymousUserID) in
                self.performSegueWithIdentifier("unwindToMapSegue", sender: self)
            })
        } catch {
            print(error)
        }
    }


}
