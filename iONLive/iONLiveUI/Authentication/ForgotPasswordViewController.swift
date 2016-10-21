
import UIKit

class ForgotPasswordViewController: UIViewController{
    
    static let identifier = "ForgotPasswordViewController"
    
    @IBOutlet weak var resetPasswdBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var resetButton: UIButton!
    
    var verificationCode : String!
    var mobileNumber : String!
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    @IBOutlet var reEnterPwdText: UITextField!
    @IBOutlet var newPwdText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetButton.hidden = true
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
        newPwdText.becomeFirstResponder()
        newPwdText.secureTextEntry = true
        newPwdText.delegate = self
        reEnterPwdText.secureTextEntry = true
        reEnterPwdText.delegate = self
        
        newPwdText.addTarget(self, action: #selector(self.textFieldDidChange), forControlEvents: .EditingChanged)
        reEnterPwdText.addTarget(self, action: #selector(self.textFieldDidChange), forControlEvents: .EditingChanged)
        
        addObserver()
    }
    
    func addObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ForgotPasswordViewController.keyboardDidShow(_:)), name:UIKeyboardWillShowNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ForgotPasswordViewController.KeyboardDidHide(_:)), name:UIKeyboardWillHideNotification , object: nil)
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
    
    func textFieldDidChange(textField: UITextField)
    {
        if(newPwdText.text!.isEmpty || reEnterPwdText.text!.isEmpty)
        {
            resetButton.hidden = true
        }
        else{
            let decimalChrSet = NSCharacterSet.decimalDigitCharacterSet()
            
            if((newPwdText.text?.characters.count < 8) || (newPwdText.text?.characters.count > 40))
            {
                resetButton.hidden = true
            }
            if((reEnterPwdText.text?.characters.count < 8) || (reEnterPwdText.text?.characters.count > 40))
            {
                resetButton.hidden = true
            }
            else if newPwdText.text!.rangeOfCharacterFromSet(decimalChrSet) == nil
            {
                resetButton.hidden = true
            }
            else if reEnterPwdText.text!.rangeOfCharacterFromSet(decimalChrSet) == nil
            {
                resetButton.hidden = true
            }
            else{
                resetButton.hidden = false
            }
        }
    }
    
    //PRAGMA MARK:- IBActions
    
    @IBAction func tapGestureRecognized(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func didTapResetButton(sender: AnyObject) {
        let newPaswrd = newPwdText.text
        let confirmPaswrd = reEnterPwdText.text
//        if newPwdText.text!.isEmpty
//        {
//            ErrorManager.sharedInstance.newPaswrdEmpty()
//        }
//        else if reEnterPwdText.text!.isEmpty
//        {
//            ErrorManager.sharedInstance.confirmPaswrdEmpty()
//        }
//        else
        if(newPaswrd != confirmPaswrd){
            ErrorManager.sharedInstance.passwordMismatch()
        }
//        else{
//            let chrSet = NSCharacterSet.decimalDigitCharacterSet()
//            if((newPaswrd?.characters.count < 8) || (newPaswrd?.characters.count > 40) || (confirmPaswrd?.characters.count < 8) || (confirmPaswrd?.characters.count > 40))
//            {
//                ErrorManager.sharedInstance.InvalidPwdEnteredError()
//                return
//            }
//            else if((newPaswrd!.rangeOfCharacterFromSet(chrSet) == nil) || (confirmPaswrd!.rangeOfCharacterFromSet(chrSet) == nil)) {
//                ErrorManager.sharedInstance.noNumberInPassword()
//                return
//            }
            else{
                showOverlay()
                authenticationManager.resetPassword(mobileNumber, newPassword: newPaswrd!, verificationCode: verificationCode, success: { (response) in
                    self.authenticationSuccessHandler(response)
                    }, failure: { (error, message) in
                        self.authenticationFailureHandler(error, code: message)
                        return
                })
            }
//        }
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
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func  loadInitialViewController(){
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
                
            }
        })
    }
}

extension ForgotPasswordViewController : UITextFieldDelegate{
    
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