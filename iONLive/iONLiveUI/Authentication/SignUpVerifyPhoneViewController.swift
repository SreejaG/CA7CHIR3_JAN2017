//
//  SignUpVerifyPhoneViewController.swift
//  iONLive
//
//  Created by Gadgeon on 1/4/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit
//import Foundation
//import CoreLocation


class SignUpVerifyPhoneViewController: UIViewController {
    
    static let identifier = "SignUpVerifyPhoneViewController"
    var verificationCode = ""
   // let locationManager:CLLocationManager = CLLocationManager()

    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var mobileNumberTextField: UITextField!
    @IBOutlet weak var continueBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var topConstaintDescriptionLabel: NSLayoutConstraint!
    @IBOutlet weak var verificationCodeTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
        //setUpLocationManager()
    }
    
//    func setUpLocationManager()
//    {
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
//        locationManager.startUpdatingLocation()
//    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
        self.countryTextField.becomeFirstResponder()
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
        countryTextField.delegate = self
        mobileNumberTextField.delegate = self
        addObserver()
    }
    
    func checkVerificationCodeVisiblty()
    {
        if verificationCode != ""
        {
            verificationCodeTextField.hidden = false
            verificationCodeTextField.text = verificationCode
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
            // appearing verification code here for testing only 
            verificationCode = "1555HFH2"
            checkVerificationCodeVisiblty()
        }
    }
    
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
//                    "country":  placemark.country
//                ]
//                
//                print("Location:  \(userInfo)")
//                
//            }
//        })
//    }
//}


