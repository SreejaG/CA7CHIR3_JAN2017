//
//  SignUpFindFriendsViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 24/02/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit
import AddressBook
import AddressBookUI

class SignUpFindFriendsViewController: UIViewController {
    
    static let identifier = "SignUpFindFriendsViewController"
    
    let requestManager = RequestManager.sharedInstance
    let contactManagers = contactManager.sharedInstance
    
    var phoneCode: String!
    var addressBookRef = ABAddressBook?()
    
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var contactPhoneNumbers: [String] = [String]()
    let nameKey = "user_name"
    let phoneKey = "mobile_no"
    let imageKey = "profile_image"
    
    var loadingOverlay: UIView?
    var contactExist: Bool = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "FIND FRIENDS"
        addressBookRef = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
    }
    
    
    @IBAction func continueButtonClicked(sender: AnyObject) {
        
        contactAuthorizationAlert()
    }
    
    func contactAuthorizationAlert()
    {
        let authorizationStatus = ABAddressBookGetAuthorizationStatus()
        
        switch authorizationStatus {
        case .Denied, .Restricted:
            print("Denied")
            generateContactSynchronizeAlert()
        case .Authorized:
            print("Authorized")
            displayContacts()
        case .NotDetermined:
            print("Not Determined")
            promptForAddressBookRequestAccess()
        }
        
    }
    
    func generateContactSynchronizeAlert()
    {
        let alert = UIAlertController(title: "\"Catch\" would like to access your contacts", message: "The contacts in your address book will be transmitted to Catch for you to decide who to add", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Don't Allow", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // self.loadLiveStreamView()
            self.loadCameraViewController()
        }))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.showEventsAcessDeniedAlert()
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func promptForAddressBookRequestAccess() {
        ABAddressBookRequestAccessWithCompletion(addressBookRef) {
            (granted: Bool, error: CFError!) in
            dispatch_async(dispatch_get_main_queue()) {
                if !granted {
                    print("Just denied")
                    self.generateContactSynchronizeAlert()
                } else {
                    print("Just authorized")
                    self.displayContacts()
                }
            }
        }
    }
    func displayContacts(){
        contactPhoneNumbers.removeAll()
        let allContacts = ABAddressBookCopyArrayOfAllPeople(addressBookRef).takeRetainedValue() as Array
        for record in allContacts {
            let currentContact: ABRecordRef = record
            
            let currentContactName = ABRecordCopyCompositeName(currentContact).takeRetainedValue() as String
            
            let currentContactImageData =  ABPersonCopyImageDataWithFormat(currentContact, kABPersonImageFormatThumbnail)?.takeRetainedValue() as CFDataRef!
            
            let phones : ABMultiValueRef = ABRecordCopyValue(record,kABPersonPhoneProperty).takeUnretainedValue() as ABMultiValueRef
            var phoneNumber = String!()
            var appendPlus = String!()
            for(var numberIndex : CFIndex = 0; numberIndex < ABMultiValueGetCount(phones); numberIndex++)
            {
                let phoneUnmaganed = ABMultiValueCopyValueAtIndex(phones, numberIndex)
                let phoneNumberStr = phoneUnmaganed.takeUnretainedValue() as! String
                let phoneNumberWithCode: String!
                
                if phoneNumberStr.containsString("+"){
                    phoneNumberWithCode = phoneNumberStr
                }
                else{
                    phoneNumberWithCode = phoneCode.stringByAppendingString(phoneNumberStr)
                }
                
                if phoneNumberWithCode.containsString("+")
                {
                    appendPlus = "+"
                }
                else{
                    appendPlus = ""
                }
               
                
                let phoneNumberStringArray = phoneNumberWithCode.componentsSeparatedByCharactersInSet(
                    NSCharacterSet.decimalDigitCharacterSet().invertedSet)
                phoneNumber = appendPlus.stringByAppendingString(NSArray(array: phoneNumberStringArray).componentsJoinedByString("")) as String
                
            }
            
            var currentContactImage : UIImage = UIImage()
            if currentContactImageData != nil
            {
                currentContactImage = UIImage(data: currentContactImageData!)!
            }
            contactPhoneNumbers.append(phoneNumber)
            self.dataSource.append([self.nameKey: currentContactName, self.phoneKey: phoneNumber, self.imageKey: currentContactImage])
        }
        print(contactPhoneNumbers)
        print(dataSource)
       addContactDetails(contactPhoneNumbers) 
      
    }
    
    func showEventsAcessDeniedAlert() {
        let alertController = UIAlertController(title: "Permission Denied!",
            message: "The contact permission was not authorized. Please enable it in Settings to continue.",
            preferredStyle: .Alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .Default) { (alertAction) in
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appSettings)
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    func addContactDetails(contactPhoneNumbers: NSArray)
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        print(contactPhoneNumbers)
        
        contactManagers.addContactDetails(userId, accessToken: accessToken, userContacts: contactPhoneNumbers, success:  { (response) -> () in
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
                contactExist = true
                loadContactViewController()
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
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
            if code == "CONTACT002" {
                contactExist = false
                loadContactViewController()
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
                if code == "CONTACT001"{
                    contactExist = false
                    loadContactViewController()
                }
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
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

    
    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://192.168.42.1:554/live", parameters: nil , liveVideo: true) as! UIViewController
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        vc.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    func loadCameraViewController()
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraViewController.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraViewController, animated: true)
    }
    
    func loadContactViewController()
    {

        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let contactDetailsViewController = storyboard.instantiateViewControllerWithIdentifier("ContactDetailsViewController") as! ContactDetailsViewController
        contactDetailsViewController.contactDataSource = dataSource
        contactDetailsViewController.contactExistChk = contactExist
        contactDetailsViewController.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(contactDetailsViewController, animated: true)
    }
}
