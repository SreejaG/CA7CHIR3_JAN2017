
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
    
    
    @IBOutlet var continuButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        continuButton.hidden = true
        initialise()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
        userNameTextfield.becomeFirstResponder()
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
        userNameTextfield.keyboardType = .NamePhonePad
        
        userNameTextfield.addTarget(self, action: #selector(self.textFieldDidChange), forControlEvents: .EditingChanged)
        
        addObserver()
    }
    
    func addObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignUpUserNameViewController.keyboardDidShow(_:)), name:UIKeyboardWillShowNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignUpUserNameViewController.KeyboardDidHide(_:)), name:UIKeyboardWillHideNotification , object: nil)
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
    
    func textFieldDidChange(textField: UITextField)
    {
        if( userNameTextfield.text!.isEmpty)
        {
            continuButton.hidden = true
        }
        else{
            let whiteChrSet = NSCharacterSet.whitespaceCharacterSet()
            if((userNameTextfield.text?.characters.count < 5) || (userNameTextfield.text?.characters.count > 15))
            {
                continuButton.hidden = true
            }
            else if userNameTextfield.text!.rangeOfCharacterFromSet(whiteChrSet) != nil {
                continuButton.hidden = true
            }
            else{
                continuButton.hidden = false
            }
        }
    }
    
    //PRAGMA MARK:- IBActions
    
    @IBAction func tapGestureRecognized(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func userNameContinueButtonClicked(sender: AnyObject)
    {
        //        if userNameTextfield.text!.isEmpty
        //        {
        //            ErrorManager.sharedInstance.signUpNoUsernameEnteredError()
        //        }
        //        else
        //        {
        //            let text = userNameTextfield.text
        //            let chrSet = NSCharacterSet.whitespaceCharacterSet()
        //            if((text?.characters.count < 5) || (text?.characters.count > 15))
        //            {
        //                ErrorManager.sharedInstance.InvalidUsernameEnteredError()
        //                userNameTextfield.text = ""
        //                userNameTextfield.becomeFirstResponder()
        //                return
        //            }
        //            else if text!.rangeOfCharacterFromSet(chrSet) != nil {
        //                ErrorManager.sharedInstance.noSpaceInUsername()
        //                userNameTextfield.text = ""
        //                userNameTextfield.becomeFirstResponder()
        //                return
        //            }
        //            else{
        signUpUser(email, password: password, userName: self.userNameTextfield.text!)
        //            }
        //        }
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
    
    func signUpUser(email: String, password: String, userName: String)
    {
        showOverlay()
        authenticationManager.signUp(email: email, password: password, userName: self.userNameTextfield.text!, success: { (response) -> () in
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
            let defaults = NSUserDefaults .standardUserDefaults()
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
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
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

