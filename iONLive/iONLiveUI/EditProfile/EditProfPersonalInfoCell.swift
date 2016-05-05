//
//  EditProfPersonalInfoCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/21/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class EditProfPersonalInfoCell: UITableViewCell,UITextFieldDelegate {
    
   static let identifier = "EditProfPersonalInfoCell"

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var displayNameTextField: UITextField!
    
    @IBOutlet var editProfileImageButton: UIButton!
 
    override func awakeFromNib() {
        super.awakeFromNib()
        userNameTextField.delegate = self
        displayNameTextField.delegate = self
        userImage.layer.cornerRadius = userImage.frame.size.width/2
        userImage.layer.masksToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
       textField.layoutIfNeeded()
    }
    
//    func textFieldDidEndEditing(textField: UITextField)
//    {
//      //  textField.layoutIfNeeded()
//    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
}
