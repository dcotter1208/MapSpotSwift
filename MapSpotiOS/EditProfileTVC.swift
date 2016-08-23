//
//  EditProfileTVC.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/22/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit
import FirebaseAuth
import Cloudinary

protocol UpdateCurrentUserDelegate {
    func updateCurrentUserSingleton(photoURL: String, name: String, location: String, profileImage: UIImage?) -> Void
}

class EditProfileTVC: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLUploaderDelegate {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var locationTF: UITextField!
    
    var profilePhotoChange: Bool?
    var pickedProfileImage = UIImage()
   var delegate: UpdateCurrentUserDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        displayCurrentUserProfile()

    }
    
    override func viewWillDisappear(animated: Bool) {
        profilePhotoChange = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    func updateCurrentUserSingleton(photoURL: String) {
        CurrentUser.sharedInstance.name = nameTF.text!
        CurrentUser.sharedInstance.location = locationTF.text!
        guard photoURL != "" || photoURL != CurrentUser.sharedInstance.photoURL else {
            return
        }
        CurrentUser.sharedInstance.photoURL = photoURL
        CurrentUser.sharedInstance.profileImage = pickedProfileImage
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

    func displayCurrentUserProfile() {
        nameTF.text = CurrentUser.sharedInstance.name
        locationTF.text = CurrentUser.sharedInstance.location
        guard CurrentUser.sharedInstance.photoURL != "" else {
            profileImage.image = UIImage(named: "default_user")
            return
        }
        profileImage.image = CurrentUser.sharedInstance.profileImage
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        guard let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        profilePhotoChange = true
        profileImage.image = pickedImage
        pickedProfileImage = pickedImage
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func uploadProfileImageToCloudinary(image:UIImage, completion:(photoURL: String)-> Void) {
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        let keys = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Keys", ofType: "plist")!)!
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

    func updateUserProfileOnFirebase(photoURL: String) {
        let firebaseOp = FirebaseOperation()
        
        guard nameTF.text?.characters.count > 2 else {
            return
        }

        let childToUpdate = ["name": removeWhiteSpace(nameTF.text!, removeAllWhiteSpace: false),
                             "profilePhotoURL": photoURL,
                             "email": CurrentUser.sharedInstance.email,
                             "location": removeWhiteSpace(locationTF.text!, removeAllWhiteSpace: false),
                             "userID": CurrentUser.sharedInstance.userID];
        
        firebaseOp.updateChildValue("users", childKey: CurrentUser.sharedInstance.snapshotKey, nodeToUpdate: childToUpdate)
    }

    //MARK: IBActions
    
    @IBAction func profilePhotoSelected(sender: AnyObject) {
        displayCameraActionSheet()
    }
    
    @IBAction func updateSelected(sender: AnyObject) {
        
        guard let name = nameTF.text, location = locationTF.text else {
            return
        }
        
        guard profilePhotoChange == true else {
            updateUserProfileOnFirebase(CurrentUser.sharedInstance.photoURL)
            self.delegate?.updateCurrentUserSingleton(CurrentUser.sharedInstance.photoURL, name: name, location: location, profileImage: nil)
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        uploadProfileImageToCloudinary(pickedProfileImage) { (photoURL) in
            self.updateUserProfileOnFirebase(photoURL)
            self.delegate?.updateCurrentUserSingleton(CurrentUser.sharedInstance.photoURL, name: name, location: location, profileImage: self.pickedProfileImage)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func cancelSelected(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

}
