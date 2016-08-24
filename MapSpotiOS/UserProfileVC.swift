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

    func updateCurrentUserSingleton(photoURL: String, name: String, location: String, profileImage: UIImage?) {
        self.name.text = name
        guard profileImage != nil else {
            return
        }
        self.profileImage.image = profileImage
    }

    func setUserProfile() {
        guard FIRAuth.auth()?.currentUser?.anonymous == false else {
            name.text = "Anonymous"
            anonymouslyLoggedIn = true
            profileImage.image = UIImage(named: "default_user")
        return
        }
        
        name.text = CurrentUser.sharedInstance.name
        guard CurrentUser.sharedInstance.photoURL != "" else {
            profileImage.image = UIImage(named: "default_user")
            return
        }
        
        guard CurrentUser.sharedInstance.profileImage != nil else {
            downloadProfileImageWithAlamoFire(CurrentUser.sharedInstance.photoURL, completion: { (image) in
                self.profileImage.image = image
                CurrentUser.sharedInstance.profileImage = image
            })
            return
        }
        profileImage.image = CurrentUser.sharedInstance.profileImage
    }
    
    func downloadProfileImageWithAlamoFire(photoURL: String, completion:(image:UIImage) -> Void) {
        Alamofire.request(.GET, photoURL)
            .responseImage { response in
            if let image = response.result.value {
                completion(image: image)
            }
        }
    }
    
    /*
     Logs a user in anonymously. Called in queryCurrentUserFromFirebase func
     if a user isn't already logged into their own account.
     */
    func loginWithAnonymousUser() {
        FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (user, error) in
            if error != nil {
                print(error)
            } else {
                print(FIRAuth.auth()?.currentUser?.uid)
            }
        })
    }

    @IBAction func signOut(sender: AnyObject) {
        do {
            try FIRAuth.auth()?.signOut()
            loginWithAnonymousUser()
            self.dismissViewControllerAnimated(false, completion: nil)
        } catch {
            print(error)
        }
    }


}
