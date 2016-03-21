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
    
//    let locationManager:CLLocationManager = CLLocationManager()
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    let defaults = NSUserDefaults .standardUserDefaults()
    
    static let identifier = "SignUpVerifyPhoneViewController"
    var verificationCode = ""
    
    
    @IBOutlet weak var countryTextField: UITextField!
    
    @IBOutlet weak var mobileNumberTextField: UITextField!
    
    @IBOutlet weak var continueBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var countryPicker: CountryPicker!
    
    @IBOutlet var countrySelectionButton: UIButton!
    @IBAction func selectCountryCode(sender: AnyObject) {
        self.countryPicker.hidden = false
        countryCodeTextField.resignFirstResponder()
        mobileNumberTextField.resignFirstResponder()
        verificationCodeTextField.resignFirstResponder()
    }
   
    @IBOutlet weak var topConstaintDescriptionLabel: NSLayoutConstraint!
  
    @IBOutlet var countryCodeTextField: UITextField!
    
    @IBOutlet weak var verificationCodeTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
//        setUpLocationManager()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
        checkVerificationCodeVisiblty()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
//    func setUpLocationManager()
//    {
//        self.locationManager.requestWhenInUseAuthorization()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
//        locationManager.startUpdatingLocation()
//    }
//    
//    
//    // authorization status
//    func locationManager(manager: CLLocationManager,
//        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
//            var shouldIAllow = false
//            var locationStatus = ""
//            switch status {
//            case CLAuthorizationStatus.Restricted:
//                locationStatus = "Restricted Access to location"
//            case CLAuthorizationStatus.Denied:
//                locationStatus = "User denied access to location"
//            case CLAuthorizationStatus.NotDetermined:
//                locationStatus = "Status not determined"
//            default:
//                locationStatus = "Allowed to location Access"
//                shouldIAllow = true
//            }
//            NSNotificationCenter.defaultCenter().postNotificationName("LabelHasbeenUpdated", object: nil)
//            if (shouldIAllow == true) {
//                NSLog("Location to Allowed")
//                // Start location services
//                locationManager.startUpdatingLocation()
//            } else {
//                NSLog("Denied access: \(locationStatus)")
//            }
//    }
//    

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
        countryCodeTextField.userInteractionEnabled = true
        mobileNumberTextField.delegate = self
        countryCodeTextField.delegate = self
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
            countryCodeTextField.enablesReturnKeyAutomatically = false
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
                    let deviceToken = defaults.valueForKey("deviceToken") as! String
            let gcmRegId = "ios".stringByAppendingString(deviceToken)
                    print(gcmRegId)
                    
                    validateVerificationCode(userName, action: "codeValidation" , verificationCode: verificationCodeTextField.text! , gcmRegId: gcmRegId)
                }
            }
            else{
                generateWaytoSendAlert()
            }
        }
    }
    
    func ltzAbbrev() -> String
    {
        return NSTimeZone.localTimeZone().abbreviation ?? ""
    }
    
    func generateWaytoSendAlert()
    {
        let alert = UIAlertController(title: "We will send a verification code to" + self.countryCodeTextField.text! + self.mobileNumberTextField.text!, message: "Enter the verification code to finish", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Send to SMS", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.generateVerificationCode(self.userName, location: self.countryName, mobileNumber: self.countryCodeTextField.text! + self.mobileNumberTextField.text!, action: "codeGeneration", verificationMethod: "sms")
            }))
        alert.addAction(UIAlertAction(title: "Send to Email", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
              self.generateVerificationCode(self.userName, location: self.countryName, mobileNumber: self.countryCodeTextField.text! + self.mobileNumberTextField.text!, action: "codeGeneration", verificationMethod: "email")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //extra wrk
    func generateVerificationCode(userName: String, location: String, mobileNumber: String, action: String, verificationMethod: String)
    {
        //authenticate through authenticationManager
        showOverlay()
        
        let timeZoneOffsetInGMT : String = ltzAbbrev()
        let timeZoneOffsetInUTC = (timeZoneOffsetInGMT as NSString).stringByReplacingOccurrencesOfString("GMT", withString: "UTC")
        
        authenticationManager.generateVerificationCodes(userName, location: location, mobileNumber: mobileNumber, action: action, verificationMethod: verificationMethod, offset: timeZoneOffsetInUTC, success: { (response) -> () in
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
    
    func validateVerificationCode(userName: String, action: String, verificationCode: String, gcmRegId: String)
    {
        //authenticate through authenticationManager
        showOverlay()
        authenticationManager.validateVerificationCode(userName, action: action, verificationCode: verificationCode, gcmRegId: gcmRegId, success: { (response) -> () in
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
                if let tocken = json["token"]
                {
                    defaults.setValue(tocken, forKey: userAccessTockenKey)
                }
                if let bucketName = json["BucketName"]
                {
                    defaults.setValue(bucketName, forKey: userBucketName)
                }
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

//extension SignUpVerifyPhoneViewController:CLLocationManagerDelegate
//{
//    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        
//        let location = locations.last! as CLLocation
//        
//        print("didUpdateLocations:  \(location.coordinate.latitude), \(location.coordinate.longitude)")
//        
//        let geocoder = CLGeocoder()
//        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, e) -> Void in
//            if let _ = e {
//                print("Error:  \(e!.localizedDescription)")
//            } else {
//                let placemark = placemarks!.last! as CLPlacemark
//                
//                let userInfo = [
//                    "city":     placemark.locality,
//                    "state":    placemark.administrativeArea,
//                    "country":  placemark.country,
//                    "code":placemark.ISOcountryCode
//                ]
//                
////                let phoneNumberUtil = NBPhoneNumberUtil.sharedInstance()
////                let phoneCode: String? = "+\(phoneNumberUtil.getCountryCodeForRegion(userInfo["code"]!))"
////              
////                self.countryCodeTextField.text = phoneCode
//                print("Location:  \(userInfo)")
//                
//            }
//        })
//    }
//    
//    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
//        locationManager.stopUpdatingLocation()
//        print(error)
//    }
//}
//
//
