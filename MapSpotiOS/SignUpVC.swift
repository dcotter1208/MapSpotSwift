//
//  SignUpVC.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/11/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import Cloudinary

class SignUpVC: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLUploaderDelegate {
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!

    let imagePicker = UIImagePickerController()
    var keys = NSDictionary()
    var profileImage: UIImage?
    var profileImageChanged: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        profileImageChanged = false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        guard let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        profileImageChanged = true
        profileImageView.image = pickedImage
        profileImage = pickedImage
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //displays action sheet for the camera or photo gallery
    func displayCameraActionSheet() {
        let imagePicker = ImagePicker()
        imagePicker.imagePicker.delegate = self
        let actionsheet = UIAlertController(title: "Choose an option", message: nil, preferredStyle: .ActionSheet)
        let camera = UIAlertAction(title: "Camera", style: .Default) { (action) in
            imagePicker.configureImagePicker(.Camera)
            imagePicker.presentCameraSource(self)
        }
        let photoGallery = UIAlertAction(title: "Photo Gallery", style: .Default) { (action) in
            imagePicker.configureImagePicker(.PhotoLibrary)
            imagePicker.presentCameraSource(self)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        actionsheet.addAction(camera)
        actionsheet.addAction(photoGallery)
        actionsheet.addAction(cancel)
        self.presentViewController(actionsheet, animated: true, completion: nil)
    }
    
/*
     Creates a user profile on Firebase.
     If there is a profile photo picked then the profile saved on Firebase has a profilePhotoURL
     Else it doesn't have a profile photoURL and the default_user photo will be used
     wherever their profile photo is supposed to be.
 */
    func createUserProfile(name: String, email: String, userID: String, profilePhotoURL: String?) {
        let firebaseOp = FirebaseOperation()
        
        guard profileImageChanged == true else {
            let userProfile = ["name": name, "email": email, "userID": userID]
            firebaseOp.setValueForChild("users", value: userProfile)
            return
        }
        
        guard let profilePhotoURL = profilePhotoURL else {
            return
        }
        
        let userProfile = ["name": name, "email": email, "userID": userID, "profilePhotoURL": profilePhotoURL]
        firebaseOp.setValueForChild("users", value: userProfile)
    }
    
/*
     Uploads the profile image to cloudinary. If the upload is successful
     then the completion handler receives the download URL.
 */
    func uploadProfileImageToCloudinary(image:UIImage, completion:(photoURL: String)-> Void) {
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        keys = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Keys", ofType: "plist")!)!
        let cloudinary = CLCloudinary(url: "cloudinary://\(keys["cloudinaryAPIKey"] as! String):\(keys["cloudinaryAPISecret"] as! String)@mapspot")
        let mobileUploader = CLUploader(cloudinary, delegate: self)
        mobileUploader.delegate = self
        
        mobileUploader.upload(imageData, options: nil, withCompletion: {
            (successResult, error, code, context) in
            
            guard let photoURL = successResult["secure_url"] else {
                return
            }
            
            completion(photoURL: photoURL as! String)

            }) { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite, context) in
                
        }
    }

/*
     Signs up a user with Firebase using email Auth.
     if a profile photo was selected from the gallery or camera then
     the photo is saved to Cloudinary upon successful sign up. Once the
     URL for the photo comes back then the profile is saved in Firebase with a profile URL.
     If there is no profile photo selected then a user profile is created without a
     profile photo URL.
     
*/
    func signUpUserWithFirebase() {
        let name = nameTF.text
        let email = emailTF.text
        let password = passwordTF.text
        
        guard let userEmail = email, userPassword = password else {
            return
        }
        
        FIRAuth.auth()?.createUserWithEmail(userEmail, password: userPassword, completion: { (user, error) in
            guard error == nil else {
                print("Error: \(error?.description)")
                return
            }
            
            guard let user = user, name = name else {
                return
            }
            
            guard self.profileImageChanged == true else {
                self.createUserProfile(name, email: userEmail, userID: user.uid, profilePhotoURL: nil)
                return
            }
            
            guard let profileImage = self.profileImage else {
                return
            }
            
            self.uploadProfileImageToCloudinary(profileImage, completion: { (photoURL) in
                print("(5)")
                self.createUserProfile(name, email: userEmail, userID: user.uid, profilePhotoURL: photoURL)
            })
        })
    }


    
    @IBAction func profilePhotoSelected(sender: AnyObject) {
        displayCameraActionSheet()
    }
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func signUp(sender: AnyObject) {
        signUpUserWithFirebase()
    }


    
}
