
import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userNameTextfield: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInBottomConstraint: NSLayoutConstraint!
    @IBOutlet var loginButton: UIButton!
    
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    let defaults = NSUserDefaults .standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.hidden = true
        initialise()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
        self.userNameTextfield.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "LOG IN"
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        
        userNameTextfield.attributedPlaceholder = NSAttributedString(string: "Username",
                                                                     attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                     attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor() ,NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        userNameTextfield.autocorrectionType = UITextAutocorrectionType.No
        passwordTextField.autocorrectionType = UITextAutocorrectionType.No
        passwordTextField.secureTextEntry = true
        userNameTextfield.delegate = self
        passwordTextField.delegate = self
        
        userNameTextfield.addTarget(self, action: #selector(self.textFieldDidChange), forControlEvents: .EditingChanged)
        passwordTextField.addTarget(self, action: #selector(self.textFieldDidChange), forControlEvents: .EditingChanged)
        
        addObserver()
    }
    
    func addObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardDidShow(_:)), name:UIKeyboardWillShowNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.KeyboardDidHide(_:)), name:UIKeyboardWillHideNotification , object: nil)
    }
    
    func textFieldDidChange(textField: UITextField)
    {
        if(userNameTextfield.text!.isEmpty || passwordTextField.text!.isEmpty)
        {
            loginButton.hidden = true
        }
        else{
            let whiteChrSet = NSCharacterSet.whitespaceCharacterSet()
            let decimalChrSet = NSCharacterSet.decimalDigitCharacterSet()
            
            if((userNameTextfield.text?.characters.count < 5) || (userNameTextfield.text?.characters.count > 15))
            {
                loginButton.hidden = true
            }
            else if userNameTextfield.text!.rangeOfCharacterFromSet(whiteChrSet) != nil {
                loginButton.hidden = true
            }
            else if((passwordTextField.text?.characters.count < 8) || (passwordTextField.text?.characters.count > 40))
            {
                loginButton.hidden = true
            }
            else if passwordTextField.text!.rangeOfCharacterFromSet(decimalChrSet) == nil
            {
                loginButton.hidden = true
            }
            else{
                loginButton.hidden = false
            }
        }
    }
    
    //PRAGMA MARK:- keyboard notification handler
    func keyboardDidShow(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        self.view.layoutIfNeeded()
        if logInBottomConstraint.constant == 0
        {
            UIView.animateWithDuration(1.0) { () -> Void in
                self.logInBottomConstraint.constant += keyboardFrame.size.height
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func KeyboardDidHide(notification: NSNotification)
    {
        self.view.layoutIfNeeded()
        if logInBottomConstraint.constant != 0
        {
            UIView.animateWithDuration(1.0) { () -> Void in
                self.logInBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    //PRAGMA MARK:- IBActions
    @IBAction func forgetPasswordClicked(sender: AnyObject)
    {
        loadVerifyPhoneView()
    }
    
    func loadVerifyPhoneView()
    {
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let verifyPhoneVC = storyboard.instantiateViewControllerWithIdentifier(SignUpVerifyPhoneViewController.identifier) as! SignUpVerifyPhoneViewController
        verifyPhoneVC.email = "invalid"
        verifyPhoneVC.userName = "invalid"
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        verifyPhoneVC.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(verifyPhoneVC, animated: false)
    }
    
    @IBAction func tapGestureRecognized(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func loginClicked(sender: AnyObject)
    {
        //        if userNameTextfield.text!.isEmpty
        //        {
        //            ErrorManager.sharedInstance.loginNoEmailEnteredError()
        //        }
        //        else if passwordTextField.text!.isEmpty
        //        {
        //            ErrorManager.sharedInstance.loginNoPasswordEnteredError()
        //        }
        //        else
        //        {
        if let deviceToken = defaults.valueForKey("deviceToken")
        {
            let gcmRegId = "ios".stringByAppendingString(deviceToken as! String)
            
            self.loginUser(self.userNameTextfield.text!, password: self.passwordTextField.text!, gcmRegistrationId: gcmRegId, withLoginButton: true)
        }
        else{
            if !self.requestManager.validConnection() {
                ErrorManager.sharedInstance.noNetworkConnection()
            }
            else{
                ErrorManager.sharedInstance.installFailure()
            }
        }
        //        }
    }
    
    //Loading Overlay Methods
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
    
    //PRAGMA MARK:- API handlers
    func loginUser(email: String, password: String, gcmRegistrationId: String, withLoginButton: Bool)
    {
        showOverlay()
        authenticationManager.authenticate(email, password: password, gcmRegId: gcmRegistrationId, success: { (response) -> () in
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
        self.passwordTextField.text = ""
        self.removeOverlay()
        loadCameraViewController()
        if let json = response as? [String: AnyObject]
        {
            clearStreamingUserDefaults(defaults)
            
            if let tocken = json["token"]
            {
                defaults.setValue(tocken, forKey: userAccessTockenKey)
            }
            if let userId = json["user"]
            {
                defaults.setValue(userId, forKey: userLoginIdKey)
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
            NSUserDefaults.standardUserDefaults().setValue("initialCall", forKey: "CallingAPI")
            GlobalDataChannelList.sharedInstance.initialise()
            ChannelSharedListAPI.sharedInstance.initialisedata()
        }
        else
        {
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    func clearStreamingUserDefaults(defaults:NSUserDefaults)
    {
        defaults.removeObjectForKey(streamingToken)
        defaults.removeObjectForKey(startedStreaming)
        defaults.removeObjectForKey(initializingStream)
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
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://192.168.42.1:554/live", parameters: nil , liveVideo: true) as! UIViewController
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    func loadCameraViewController()
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
    }
}

extension LoginViewController:UITextFieldDelegate{
    
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

