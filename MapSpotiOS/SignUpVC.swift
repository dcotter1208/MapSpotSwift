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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            profileImageView.image = pickedImage
            uploadImageToCloudinary(pickedImage)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
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
        
        actionsheet.addAction(camera)
        actionsheet.addAction(photoGallery)
        
        self.presentViewController(actionsheet, animated: true, completion: nil)
    }
    
    func createUserProfile(name: String, email: String, userID: String, profilePhotoURL: String) {
        let firebaseOp = FirebaseOperation()
        let userProfile = ["name": name, "email": email, "userID": userID, "profilePhotoURL": profilePhotoURL]
        
        firebaseOp.setValueForChild("users", value: userProfile)
    }
    
    func uploadImageToCloudinary(image:UIImage) {
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        keys = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Keys", ofType: "plist")!)!
        
        let APIKey = keys["cloudinaryAPIKey"] as! String
        let APISecret = keys["cloudinaryAPISecret"] as! String

        let cloudinary = CLCloudinary(url: "cloudinary://\(APIKey):\(APISecret)@mapspot")
        
        let mobileUploader = CLUploader(cloudinary, delegate: self)
        mobileUploader.delegate = self
        
        mobileUploader.upload(imageData, options: nil, withCompletion: {
            (successResult, error, code, context) in
            
            if successResult != nil {
                let publicID = successResult["public_id"]
                print("Upload Sucessful. Public ID = \(publicID), full result: \(successResult)")
            }
            
            }) { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite, context) in
                                
        }
        
    }
    
    //test cloudinary download
    func downloadFromCloudinary() {
        let cloudinary = CLCloudinary(url: "cloudinary://857777363657947:db4zcCyubIjqwItnGb1lQgwqjCg@mapspot")
        let url = cloudinary.url("sample.jpg")
        
        if let cloudURL = url {
            let photoURL = NSURL(string: cloudURL)
            if let photoURL = photoURL {
                let data = NSData(contentsOfURL: photoURL)
                if let data = data {
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.profileImageView.image = UIImage(data: data)

                    })
                }
            }
        }

    }
    
    func signUpUserWithFirebase() {
        let name = nameTF.text
        let email = emailTF.text
        let password = passwordTF.text
        
        if let email = email, password = password {
            FIRAuth.auth()?.createUserWithEmail(email, password: password, completion: { (user, error) in
                
                if (error != nil) {
                    print(error?.description)
                } else {
                    if let user = user, name = name {
                        self.createUserProfile(name, email: email, userID: user.uid, profilePhotoURL: "")
                    }
                }
            })
        }
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
