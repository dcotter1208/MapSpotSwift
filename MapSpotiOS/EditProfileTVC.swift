//
//  EditProfileTVC.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/22/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit

class EditProfileTVC: UITableViewController {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var locationTF: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        displayCurrentUserProfile()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    

    func updateUserProfileOnFirebase() {
        let firebaseOp = FirebaseOperation()
        
        guard nameTF.text?.characters.count > 2 else {
            return
        }
        
        let childToUpdate = ["name": removeWhiteSpace(nameTF.text!, removeAllWhiteSpace: false),
                             "profilePhotoURL": CurrentUser.sharedInstance.photoURL,
                             "email": CurrentUser.sharedInstance.email,
                             "location": removeWhiteSpace(locationTF.text!, removeAllWhiteSpace: false),
                             "userID": CurrentUser.sharedInstance.userID];
        
        firebaseOp.updateChildValue("users", childKey: CurrentUser.sharedInstance.snapshotKey, nodeToUpdate: childToUpdate)
    }

    @IBAction func updateSelected(sender: AnyObject) {
        updateUserProfileOnFirebase()
    }
    
    @IBAction func cancelSelected(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
