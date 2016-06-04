//
//  ForgotPasswordViewController.swift
//  iONLive
//
//  Created by Gadgeon on 11/30/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class ForgotPasswordViewController: UIViewController , UITextFieldDelegate{
    
    static let identifier = "ForgotPasswordViewController"

    @IBOutlet weak var resetPasswdBottomConstraint: NSLayoutConstraint!
    
    var verificationCode : String!
    var mobileNumber : String!
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    @IBOutlet var reEnterPwdText: UITextField!
    @IBOutlet var newPwdText: UITextField!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        print(verificationCode)
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "RESET PASSWORD"
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        newPwdText.attributedPlaceholder = NSAttributedString(string: "New Password",
                                                                  attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        newPwdText.autocorrectionType = UITextAutocorrectionType.No
        
        reEnterPwdText.attributedPlaceholder = NSAttributedString(string: "Re-enter Password",
                                                              attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        reEnterPwdText.autocorrectionType = UITextAutocorrectionType.No
        addObserver()
        newPwdText.becomeFirstResponder()
        newPwdText.secureTextEntry = true
        newPwdText.delegate = self
        reEnterPwdText.secureTextEntry = true
        reEnterPwdText.delegate = self
        print("\(mobileNumber)      \(verificationCode)")       
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
        if resetPasswdBottomConstraint.constant == 0
        {
            UIView.animateWithDuration(1.0, animations: { () -> Void in
                self.resetPasswdBottomConstraint.constant += keyboardFrame.size.height
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func KeyboardDidHide(notification: NSNotification)
    {
        self.view.layoutIfNeeded()
        if resetPasswdBottomConstraint.constant != 0
        {
            UIView.animateWithDuration(1.0, animations: { () -> Void in
                self.resetPasswdBottomConstraint.constant = 0
            })
        }
    }
    
    // PRAGMA MARK:- textField delegates
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    //PRAGMA MARK:- IBActions
    
    @IBAction func tapGestureRecognized(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func didTapResetButton(sender: AnyObject) {
        let newPaswrd = newPwdText.text
        let confirmPaswrd = reEnterPwdText.text
        if newPwdText.text!.isEmpty
        {
            ErrorManager.sharedInstance.newPaswrdEmpty()
        }
        else if reEnterPwdText.text!.isEmpty
        {
            ErrorManager.sharedInstance.confirmPaswrdEmpty()
        }
        else if(newPaswrd != confirmPaswrd){
            ErrorManager.sharedInstance.passwordMismatch()
        }
        else{
            let chrSet = NSCharacterSet.decimalDigitCharacterSet()
            if((newPaswrd?.characters.count < 8) || (newPaswrd?.characters.count > 20) || (confirmPaswrd?.characters.count < 8) || (confirmPaswrd?.characters.count > 20))
            {
                ErrorManager.sharedInstance.InvalidPwdEnteredError()
                return
            }
            else if((newPaswrd!.rangeOfCharacterFromSet(chrSet) == nil) || (confirmPaswrd!.rangeOfCharacterFromSet(chrSet) == nil)) {
                ErrorManager.sharedInstance.noNumberInPassword()
                return
            }
            else{
                showOverlay()
                authenticationManager.resetPassword(mobileNumber, newPassword: newPaswrd!, verificationCode: verificationCode, success: { (response) in
                        self.authenticationSuccessHandler(response)
                    }, failure: { (error, message) in
                        self.authenticationFailureHandler(error, code: message)
                        return
                })
            }
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                let alert = UIAlertController(title: "", message: "Your password has been changed", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Go To Login Screen", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                     self.loadInitialViewController()
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
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
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
     //   self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func  loadInitialViewController(){
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
        
        if(NSFileManager.defaultManager().fileExistsAtPath(documentsPath))
        {
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.removeItemAtPath(documentsPath)
            }
            catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
            FileManagerViewController.sharedInstance.createParentDirectory()
        }
        else{
            FileManagerViewController.sharedInstance.createParentDirectory()
        }
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let deviceToken = defaults.valueForKey("deviceToken") as! String
        defaults.removePersistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
        defaults.setValue(deviceToken, forKey: "deviceToken")
        defaults.setObject(1, forKey: "shutterActionMode");
        
        let sharingStoryboard = UIStoryboard(name:"Authentication", bundle: nil)
        let channelItemListVC = sharingStoryboard.instantiateViewControllerWithIdentifier("AuthenticateNavigationController") as! AuthenticateNavigationController
        channelItemListVC.navigationController?.navigationBarHidden = true
        self.navigationController?.presentViewController(channelItemListVC, animated: false, completion: nil)
    }
}
