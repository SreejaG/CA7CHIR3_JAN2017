//
//  SignUpVerifyPhoneViewController.swift
//  iONLive
//
//  Created by Gadgeon on 1/4/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class SignUpVerifyPhoneViewController: UIViewController
{
    var email: String!
    var userName: String!
    var countryName: String!
    
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    static let identifier = "SignUpVerifyPhoneViewController"
    var verificationCode = ""
    
    
    @IBOutlet weak var countryTextField: UITextField!
    
    @IBOutlet weak var mobileNumberTextField: UITextField!
    
    @IBOutlet weak var continueBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var countryPicker: CountryPicker!
    
    @IBOutlet var countrySelectionButton: UIButton!
    @IBAction func selectCountryCode(sender: AnyObject) {
        self.countryPicker.hidden = false
        mobileNumberTextField.resignFirstResponder()
        verificationCodeTextField.resignFirstResponder()
    }
   
    @IBOutlet weak var topConstaintDescriptionLabel: NSLayoutConstraint!
  
    @IBOutlet var countryCodeTextField: UITextField!
    
    @IBOutlet weak var verificationCodeTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
        self.countryCodeTextField.becomeFirstResponder()
        checkVerificationCodeVisiblty()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "VERIFY PHONE #"
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        
        countryTextField.attributedPlaceholder = NSAttributedString(string: "Country",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        mobileNumberTextField.attributedPlaceholder = NSAttributedString(string: "Mobile Number",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        countryCodeTextField.attributedPlaceholder = NSAttributedString(string: "Code",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        verificationCodeTextField.attributedPlaceholder = NSAttributedString(string: "Verification Code",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
    
        countryPicker.countryPhoneCodeDelegate = self
        countryTextField.userInteractionEnabled = false
        countryCodeTextField.userInteractionEnabled = false
        mobileNumberTextField.delegate = self
        self.countryPicker.hidden = true
        addObserver()
        
    }
    
    func checkVerificationCodeVisiblty()
    {
        if verificationCode != ""
        {
            countryPicker.hidden = true
            countryTextField.enabled = false
            mobileNumberTextField.enabled = false
            countrySelectionButton.enabled = false
            verificationCodeTextField.hidden = false
            mobileNumberTextField.resignFirstResponder()
            verificationCodeTextField.becomeFirstResponder()
            topConstaintDescriptionLabel.constant = 67
           
        }
        else
        {
            verificationCodeTextField.hidden = true
            topConstaintDescriptionLabel.constant = 1
        }
        
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
    
    @IBAction func verifyPhoneContinueButtonClicked(sender: AnyObject)
    {
        if countryTextField.text!.isEmpty
        {
            ErrorManager.sharedInstance.signUpNoEmailEnteredError()
        }
        else if countryTextField.text!.isEmpty
        {
            ErrorManager.sharedInstance.signUpNoEmailEnteredError()
        }
        else
        {
            if(verificationCode != ""){
                if verificationCodeTextField.text!.isEmpty
                {
                    ErrorManager.sharedInstance.signUpNoCodeEnteredError()
                }
                else
                {
                    validateVerificationCode(userName, action: "codeValidation" , verificationCode: verificationCodeTextField.text!, gcmRegistrationId: "eJL-i5TYbHE:APA91bEIOJzuL4eVeGOG8ZyTVda8PLc-taes1vaV8_U7nUEQPXSPjZyf8i90Eob5T56wgmSQH7et8QXLDcqhhPOme9r75zICqPji-xei-c7l3oIEZJt4NrCmNfxgWFsTML_US_4ZMxHs")
                }
            }
            else{
                generateWaytoSendAlert()
            }
        }
    }
    
    
    
    func generateWaytoSendAlert()
    {
        let alert = UIAlertController(title: "We will send a verification code to" + self.countryCodeTextField.text! + self.mobileNumberTextField.text!, message: "Enter the verification code to finish", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Send to SMS", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.generateVerificationCode(self.userName, location: self.countryName, mobileNumber: self.countryCodeTextField.text! + self.mobileNumberTextField.text!, email: self.email, action: "codeGeneration", verificationMethod: "sms")
            }))
        alert.addAction(UIAlertAction(title: "Send to Email", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
              self.generateVerificationCode(self.userName, location: self.countryName, mobileNumber: self.countryCodeTextField.text! + self.mobileNumberTextField.text!, email: self.email, action: "codeGeneration", verificationMethod: "email")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //extra wrk
    func generateVerificationCode(userName: String, location: String, mobileNumber: String, email: String, action: String, verificationMethod: String)
    {
        //authenticate through authenticationManager
        showOverlay()
        authenticationManager.generateVerificationCodes(userName, location: location, mobileNumber: mobileNumber, email: email, action: action, verificationMethod: verificationMethod, success: { (response) -> () in
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
            var status: Int!
            status = json["status"] as! Int
            if(status >= 1)
            {
                verificationCode = "1555HFH2"
                checkVerificationCodeVisiblty()
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
    
    func validateVerificationCode(userName: String, action: String, verificationCode: String, gcmRegistrationId: String)
    {
        //authenticate through authenticationManager
        showOverlay()
        authenticationManager.validateVerificationCode(userName, action: action, verificationCode: verificationCode, gcmRegistrationId: gcmRegistrationId, success: { (response) -> () in
            self.authenticationSuccessHandlerVerification(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                return
        }
    }

    func authenticationSuccessHandlerVerification(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            var status: Int!
            status = json["status"] as! Int
            if(status >= 1)
            {
                verificationCode = ""
                loadFindFriendsView()
            }
        }
        else
        {
            ErrorManager.sharedInstance.loginError()
        }
    }
 
    func loadFindFriendsView()
    {
        
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let findFriendsVC = storyboard.instantiateViewControllerWithIdentifier(SignUpFindFriendsViewController.identifier) as! SignUpFindFriendsViewController
        findFriendsVC.navigationItem.hidesBackButton = true
        self.navigationController?.pushViewController(findFriendsVC, animated: false)
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
    
    
    func loadUserNameView()
    {
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let userNameVC = storyboard.instantiateViewControllerWithIdentifier(SignUpUserNameViewController.identifier)
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        userNameVC.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(userNameVC, animated: false)
    }
}

extension SignUpVerifyPhoneViewController:UITextFieldDelegate{
    
    func textFieldDidEndEditing(textField: UITextField)
    {
         textField.layoutIfNeeded()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        self.countryPicker.hidden = true
        return true
    }
}

extension SignUpVerifyPhoneViewController:CountryPhoneCodePickerDelegate{
    func countryPhoneCodePicker(picker: CountryPicker, didSelectCountryCountryWithName name: String, countryCode: String, phoneCode: String) {
        countryName = name
        self.countryTextField.text = countryCode + " - " + name
        self.countryCodeTextField.text = phoneCode
    }

}

