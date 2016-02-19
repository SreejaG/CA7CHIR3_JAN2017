//
//  SignUpViewController.swift
//  iONLive
//
//  Created by Gadgeon on 11/30/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwdTextField: UITextField!
    @IBOutlet weak var signUpBottomConstraint: NSLayoutConstraint!

    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
        self.emailTextfield.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "SIGN UP"
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        
        emailTextfield.attributedPlaceholder = NSAttributedString(string: "Email address",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        passwdTextField.attributedPlaceholder = NSAttributedString(string: "New Password",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor() ,NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        emailTextfield.autocorrectionType = UITextAutocorrectionType.No
        passwdTextField.autocorrectionType = UITextAutocorrectionType.No
        passwdTextField.secureTextEntry = true
        emailTextfield.delegate = self
        passwdTextField.delegate = self
        addObserver()
    }
  
    func addObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name:UIKeyboardWillShowNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "KeyboardDidHide:", name:UIKeyboardWillHideNotification , object: nil)
    }
    
    //PRAGMA MARK:- keyboard notification handler
    
    func keyboardDidShow(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        self.view.layoutIfNeeded()
        if signUpBottomConstraint.constant == 0
        {
            UIView.animateWithDuration(1.0) { () -> Void in
                self.signUpBottomConstraint.constant += keyboardFrame.size.height
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func KeyboardDidHide(notification: NSNotification)
    {
        self.view.layoutIfNeeded()
        if signUpBottomConstraint.constant != 0
        {
            UIView.animateWithDuration(1.0) { () -> Void in
                self.signUpBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    //PRAGMA MARK:- IBActions
    
    @IBAction func tapGestureRecognized(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func signUpClicked(sender: AnyObject)
    {
        if emailTextfield.text!.isEmpty
        {
            ErrorManager.sharedInstance.signUpNoEmailEnteredError()
        }
        else if passwdTextField.text!.isEmpty
        {
            ErrorManager.sharedInstance.signUpNoPasswordEnteredError()
        }
        else
        {
            validateEmail()
        }
    }
   
    
    //extra wrk sreeja
    
    func validateEmail(){
        let isEmailValid = isEmail(self.emailTextfield.text!) as Bool!
        if isEmailValid == false
        {
            ErrorManager.sharedInstance.loginInvalidEmail()
            return
        }
        else
        {
             loadUserNameView()
        }
    }
    
    //end
    
    func loadUserNameView()
    {
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let userNameVC = storyboard.instantiateViewControllerWithIdentifier(SignUpUserNameViewController.identifier) as! SignUpUserNameViewController
        
        userNameVC.email = self.emailTextfield.text!
        userNameVC.password = self.passwdTextField.text!
        
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        userNameVC.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(userNameVC, animated: false)
    }
   
    //PRAGMA MARK:- Helper functions
    
    func isEmail(email:String) -> Bool {
        let regex = try? NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .CaseInsensitive)
        return regex?.firstMatchInString(email, options: [], range: NSMakeRange(0, email.characters.count)) != nil
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
//    func loadLiveStreamView()
//    {
//        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://192.168.42.1:554/live", parameters: nil , liveVideo: true) as! UIViewController
//        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
//        vc.navigationItem.backBarButtonItem = backItem
//        self.navigationController?.pushViewController(vc, animated: false)
//    }
}

extension SignUpViewController:UITextFieldDelegate{
    
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

