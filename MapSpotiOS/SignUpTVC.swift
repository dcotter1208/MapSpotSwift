//
//  SignUpTVC.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/19/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import Cloudinary

class SignUpTVC: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLUploaderDelegate {
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    
    let imagePicker = UIImagePickerController()
    var keys = NSDictionary()
    var profileImage: UIImage?
    var profileImageChanged: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView(frame: CGRectZero)

    }
    
    override func viewWillDisappear(animated: Bool) {
        profileImageChanged = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func removeWhiteSpace(string:String?, removeAllWhiteSpace:Bool) -> String {
        
        guard let string = string else {
            return "nil"
        }
        
        guard removeAllWhiteSpace == false else {
            let newString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).stringByReplacingOccurrencesOfString(" ", withString: "")
            return newString
        }
        
        let newString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        return newString
    }
    
    func handleFirebaseErrorCode(error: NSError?) {
        if let errorCode = FIRAuthErrorCode(rawValue: error!.code) {
            switch errorCode {
            case .ErrorCodeInvalidEmail:
                self.displayAlert("Whoops!", message: "Invalid Email")
            case .ErrorCodeEmailAlreadyInUse:
                self.displayAlert("Whoops!", message: "Email is already in use.")
            case .ErrorCodeWeakPassword:
                self.displayAlert("Whoops!", message: "Please pick a stronger password.")
            case .ErrorCodeNetworkError:
                self.displayAlert("Sign Up Failed.", message: "Please check your connection.")
            default:
                self.displayAlert("Something went wrong.", message: "Please try again.")
            }
        }
    }
    
    //MARK: Camera Methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        guard let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        profileImageChanged = true
        profileImageView.image = pickedImage
        profileImage = pickedImage
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Alert used for failed signup
    func displayAlert(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
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
    
    //MARK: Firebase Methods
    
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
    func signUpUserWithFirebase(email: String, password: String, name: String) {
        
        FIRAuth.auth()?.createUserWithEmail(email, password: password, completion: { (user, error) in
            guard error == nil else {
                self.handleFirebaseErrorCode(error)
                return
            }
            
            guard let user = user else {
                return
            }
            
            guard self.profileImageChanged == true else {
                self.createUserProfile(name, email: email, userID: user.uid, profilePhotoURL: nil)
                self.dismissViewControllerAnimated(true, completion: nil)
                return
            }
            
            guard let profileImage = self.profileImage else {
                return
            }
            
            self.uploadProfileImageToCloudinary(profileImage, completion: { (photoURL) in
                self.createUserProfile(name, email: email, userID: user.uid, profilePhotoURL: photoURL)
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        })
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        nameTF.resignFirstResponder()
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()

    }
    
    //MARK: IBActions
    
    @IBAction func profilePhotoSelected(sender: AnyObject) {
        displayCameraActionSheet()
    }
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func signUp(sender: AnyObject) {
        
        let name = removeWhiteSpace(nameTF.text, removeAllWhiteSpace: false)
        let email = removeWhiteSpace(emailTF.text, removeAllWhiteSpace: true)
        let password = removeWhiteSpace(passwordTF.text, removeAllWhiteSpace: true)
        
        guard name.characters.count > 2 else {
            displayAlert("Whoops!", message: "Your name must be longer than 2 characters")
            return
        }
        signUpUserWithFirebase(email, password: password, name: name)
    }

    
}

