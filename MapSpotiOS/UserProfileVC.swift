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

class UserProfileVC: UIViewController {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var name: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkForCurrentlyLoggedInUser()
        setUserProfile()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUserProfile() {
        
        guard FIRAuth.auth()?.currentUser != nil else {
        return
        }
        
        name.text = CurrentUser.sharedInstance.name
        
        guard CurrentUser.sharedInstance.photoURL != "" else {
            profileImage.image = UIImage(named: "default_user")
            return
        }
        profileImage.image = CurrentUser.sharedInstance.profileImage
    }
    
    func downloadProgileImageWithAlamoFire(photoURL: String, completion:(image:UIImage) -> Void) {
        Alamofire.request(.GET, photoURL)
            .responseImage { response in
            if let image = response.result.value {
                completion(image: image)
            }
        }
    }
    
    func checkForCurrentlyLoggedInUser() {
        guard FIRAuth.auth()?.currentUser == nil else {
            return
        }
        presentLoginSignUpOption("Login", message: "Don't have an account? Sign Up")
    }

    
    func presentLoginSignUpOption(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        alertController.addTextFieldWithConfigurationHandler { (emailTF) in
            emailTF.placeholder = "email"
        }
        
        alertController.addTextFieldWithConfigurationHandler { (passwordTF) in
            passwordTF.placeholder = "password"
        }
        
        let login = UIAlertAction(title: "Login", style: .Default) {
            (action) in
            let emailTF = alertController.textFields![0] as UITextField
            let passwordTF = alertController.textFields![1] as UITextField
            
            FIRAuth.auth()?.signInWithEmail(emailTF.text!, password: passwordTF.text!, completion: { (user, error) in
                guard error == nil else {
                    self.presentLoginSignUpOption("Login Failed", message: "Please check your email & password and try again.")
                    print(error?.description)
                    return
                }
                print(user)
            })
        }
        
        let signup = UIAlertAction(title: "Sign Up", style: .Default) {
            (action) in
            self.istantiateUserSignUpEditTVC()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        alertController.addAction(login)
        alertController.addAction(signup)
        alertController.addAction(cancel)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func istantiateUserSignUpEditTVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let SignUpVC = storyboard.instantiateViewControllerWithIdentifier("SignUpEditNavController")
        self.presentViewController(SignUpVC, animated: true, completion: nil)
    }
    
}
