
import UIKit
import Foundation
import CoreLocation

class SignUpVerifyPhoneViewController: UIViewController
{
    var email: String!
    var userName: String!
    var countryName: String!
    var CountryPhoneCode: String!
    
    var loadingOverlay: UIView?
    
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
        countryName = "United States"
        self.countryTextField.text = "US" + " - " + "United States"
        self.countryCodeTextField.text = "+1"
        CountryPhoneCode = "+1"
    }
    
    @IBOutlet weak var topConstaintDescriptionLabel: NSLayoutConstraint!
    
    @IBOutlet var countryCodeTextField: UITextField!
    
    @IBOutlet weak var verificationCodeTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        countryPicker.selectRow(230, inComponent: 0, animated: true)
        initialise()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
        checkVerificationCodeVisiblty()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        if((userName == "invalid") && (email == "invalid"))
        {
            self.title = ""
        }
        else{
            self.title = "VERIFY PHONE #"
        }
        
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
        verificationCodeTextField.keyboardType = .DecimalPad
        
        countryPicker.countryPhoneCodeDelegate = self
        countryTextField.userInteractionEnabled = false
        countryCodeTextField.userInteractionEnabled = true
        verificationCodeTextField.hidden = true
        verificationCode = ""
        mobileNumberTextField.delegate = self
        countryCodeTextField.delegate = self
        self.countryPicker.hidden = true
        addObserver()
        countryTextField.autocorrectionType = .No
        mobileNumberTextField.autocorrectionType = .No
        countryCodeTextField.autocorrectionType = .No
        verificationCodeTextField.autocorrectionType = .No
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignUpVerifyPhoneViewController.keyboardDidShow(_:)), name:UIKeyboardWillShowNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignUpVerifyPhoneViewController.KeyboardDidHide(_:)), name:UIKeyboardWillHideNotification , object: nil)
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
            ErrorManager.sharedInstance.emptyCountryError()
        }
        else if mobileNumberTextField.text!.isEmpty
        {
            ErrorManager.sharedInstance.emptyMobileError()
        }
        else if countryCodeTextField.text!.isEmpty
        {
            ErrorManager.sharedInstance.emptyCodeError()
        }
        else
        {
            if(verificationCode != ""){
                if verificationCodeTextField.text!.isEmpty
                {
                    ErrorManager.sharedInstance.signUpNoCodeEnteredError()
                }
                else if((userName == "invalid") && (email == "invalid"))
                {
                    loadForgotPasswordView()
                }
                else{
                    let deviceToken = defaults.valueForKey("deviceToken") as! String
                    let gcmRegId = "ios".stringByAppendingString(deviceToken)
                    validateVerificationCode(userName, action: "codeValidation" , verificationCode: verificationCodeTextField.text! , gcmRegId: gcmRegId)
                }
            }
            else{
                if((userName == "invalid") && (email == "invalid")){
                    generateWaytoSendAlertForResetPassword()
                }
                else{
                    generateWaytoSendAlert()
                }
            }
        }
    }
    
    func  loadForgotPasswordView(){
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let verifyPhoneVC = storyboard.instantiateViewControllerWithIdentifier(ForgotPasswordViewController.identifier) as! ForgotPasswordViewController
        verifyPhoneVC.verificationCode = verificationCodeTextField.text!
        verifyPhoneVC.mobileNumber = countryCodeTextField.text! + mobileNumberTextField.text!
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        verifyPhoneVC.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(verifyPhoneVC, animated: false)
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
    
    func generateWaytoSendAlertForResetPassword()
    {
        let alert = UIAlertController(title: "We will send a verification code to" + self.countryCodeTextField.text! + self.mobileNumberTextField.text!, message: "Enter the verification code to finish", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Send to SMS", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.generateVerificationCodeForResetPassword(self.countryCodeTextField.text! + self.mobileNumberTextField.text!)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func generateVerificationCodeForResetPassword(mobileNumber: String)
    {
        showOverlay()
        authenticationManager.generateVerificationCodeForResetPassword(mobileNumber, success: { (response) in
            self.authenticationSuccessHandler(response)
        }) { (error, message) in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func generateVerificationCode(userName: String, location: String, mobileNumber: String, action: String, verificationMethod: String)
    {
        showOverlay()
        let userCountryCode = self.countryCodeTextField.text
        let timeOffset = NSTimeZone.systemTimeZone().secondsFromGMT
        let timeOffsetStr = String(timeOffset)
        var timeZoneOffsetInUTC : String = String()
        if timeOffsetStr.hasPrefix("-")
        {
            timeZoneOffsetInUTC = timeOffsetStr
        }
        else
        {
            timeZoneOffsetInUTC = "+\(timeOffsetStr)"
        }
        
        authenticationManager.generateVerificationCodes(userName, location: location, mobileNumber: mobileNumber, action: action, verificationMethod: verificationMethod, offset: timeZoneOffsetInUTC, countryCode: userCountryCode!, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func  loadInitialViewController(code: String){
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
            
            if(NSFileManager.defaultManager().fileExistsAtPath(documentsPath))
            {
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtPath(documentsPath)
                }
                catch _ as NSError {
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
            self.presentViewController(channelItemListVC, animated: false) { () -> Void in
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        })
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
                verificationCode = "exist"
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
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false
        {
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.signUpError()
        }
    }
    
    func validateVerificationCode(userName: String, action: String, verificationCode: String, gcmRegId: String)
    {
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
                if let code = json["countryCode"]
                {
                    defaults.setValue(code, forKey: "countryCode")
                }
                if let code = json["archiveId"]
                {
                    defaults.setValue(code, forKey: archiveId)
                }
                if let code = json["totalMediaInArchive"]
                {
                    defaults.setValue(code, forKey:ArchiveCount)
                }
                loadFindFriendsView()
            }
        }
        else
        {
            removeOverlay()
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    func loadFindFriendsView()
    {
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let findFriendsVC = storyboard.instantiateViewControllerWithIdentifier(SignUpFindFriendsViewController.identifier) as! SignUpFindFriendsViewController
        findFriendsVC.phoneCode = CountryPhoneCode
        findFriendsVC.navigationItem.hidesBackButton = true
        self.navigationController?.pushViewController(findFriendsVC, animated: false)
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
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
        CountryPhoneCode = phoneCode
    }
}
