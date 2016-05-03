//
//  EditProfPersonalInfoCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/21/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class EditProfPersonalInfoCell: UITableViewCell,UITextFieldDelegate /*,UINavigationControllerDelegate,UIImagePickerControllerDelegate */ {
    
   static let identifier = "EditProfPersonalInfoCell"

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var displayNameTextField: UITextField!
  //  let imagePicker = UIImagePickerController()
    
    @IBAction func didTapEditProfileButton(sender: AnyObject) {
//        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum){
//            print("Button capture")
//            imagePicker.delegate = self
//            imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum;
//            imagePicker.allowsEditing = false
//            
//            self.presentViewController(imagePicker, animated: true, completion: nil)
//        }
    }
    
//    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
//        self.dismissViewControllerAnimated(true, completion: { () -> Void in
//            
//        })
//        
//        imageView.image = image
//        
//    }

    override func awakeFromNib() {
        super.awakeFromNib()
        userNameTextField.delegate = self
        displayNameTextField.delegate = self
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
       textField.layoutIfNeeded()
    }
    
    func textFieldDidEndEditing(textField: UITextField)
    {
        textField.layoutIfNeeded()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
}
