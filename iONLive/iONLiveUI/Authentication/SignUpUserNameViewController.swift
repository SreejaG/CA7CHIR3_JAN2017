//
//  SignUpUserNameViewController.swift
//  iONLive
//
//  Created by Gadgeon on 1/4/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class SignUpUserNameViewController: UIViewController {
    
    var email: String!
    var password: String!
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    var loadingOverlay: UIView?
    
    static let identifier = "SignUpUserNameViewController"
    @IBOutlet weak var userNameTextfield: UITextField!
    @IBOutlet weak var continueBottomConstraint: NSLayoutConstraint!
   
    
      override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
//        self.userNameTextfield.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "USERNAME"
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        
        userNameTextfield.attributedPlaceholder = NSAttributedString(string: "Username",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        userNameTextfield.autocorrectionType = UITextAutocorrectionType.No
        userNameTextfield.delegate = self
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
        if continueBottomConstraint.constant == 0
        {
            UIView.animateWithDuration(1.0) { () -> Void in
                self.continueBottomConstraint.constant += keyboardFrame.size.height
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func KeyboardDidHide(notification: NSNotification)
    {
        self.view.layoutIfNeeded()
        if continueBottomConstraint.constant != 0
        {
            UIView.animateWithDuration(1.0) { () -> Void in
                self.continueBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    //PRAGMA MARK:- IBActions
    
    @IBAction func tapGestureRecognized(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func userNameContinueButtonClicked(sender: AnyObject)
    {
        if userNameTextfield.text!.isEmpty
        {
            ErrorManager.sharedInstance.signUpNoEmailEnteredError()
        }
        else
        {
            signUpUser(email, password: password, userName: self.userNameTextfield.text!)
        }
    }
    
    func loadVerifyPhoneView()
    {
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let verifyPhoneVC = storyboard.instantiateViewControllerWithIdentifier(SignUpVerifyPhoneViewController.identifier) as! SignUpVerifyPhoneViewController
        verifyPhoneVC.email = email
        verifyPhoneVC.userName = self.userNameTextfield.text
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        verifyPhoneVC.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(verifyPhoneVC, animated: false)
    }
    
    //extra wrk
    func signUpUser(email: String, password: String, userName: String)
    {
        //authenticate through authenticationManager
        showOverlay()
        authenticationManager.signUp(email: email, password: password, userName: self.userNameTextfield.text!, success: { (response) -> () in
                self.authenticationSuccessHandler(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                return
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let defaults = NSUserDefaults .standardUserDefaults()
            print(json["status"],json["user"])
            if let userId = json["user"]
            {
                defaults.setValue(userId, forKey: userLoginIdKey)
            }
            loadVerifyPhoneView()
        }
        else
        {
            ErrorManager.sharedInstance.signUpError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
        }
        else{
            ErrorManager.sharedInstance.signUpError()
        }
    }
    
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = self.view.bounds
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    //end
}

extension SignUpUserNameViewController:UITextFieldDelegate{
    
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

