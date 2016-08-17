//
//  ImagePicker.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/11/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit

class ImagePicker: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    
    func configureImagePicker(sourceType: UIImagePickerControllerSourceType) {
        imagePicker.sourceType = sourceType
    }
    
    func presentCameraSource(presenter: UIViewController) {
        presenter.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
}
