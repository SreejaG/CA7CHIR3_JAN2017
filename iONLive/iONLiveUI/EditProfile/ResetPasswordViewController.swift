
import UIKit

class ResetPasswordViewController: UIViewController {
    
    static let identifier = "ResetPasswordViewController"
    
    var loadingOverlay: UIView?
    
    @IBOutlet weak var reEnterPasswordTextField: UITextField!
    @IBOutlet weak var resetPasswordTextfield: UITextField!
    @IBOutlet weak var resetPasswdBottomConstraint: NSLayoutConstraint!
    @IBOutlet var resetButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ResetPasswordViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        resetButton.hidden = true
        initialise()
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        resetPasswordTextfield.becomeFirstResponder()
        resetPasswordTextfield.delegate = self
        reEnterPasswordTextField.delegate = self
        reEnterPasswordTextField.autocorrectionType = UITextAutocorrectionType.No
        resetPasswordTextfield.autocorrectionType = UITextAutocorrectionType.No
        reEnterPasswordTextField.secureTextEntry = true
        resetPasswordTextfield.secureTextEntry = true
        
        resetPasswordTextfield.addTarget(self, action: #selector(self.textFieldDidChange), forControlEvents: .EditingChanged)
        reEnterPasswordTextField.addTarget(self, action: #selector(self.textFieldDidChange), forControlEvents: .EditingChanged)
        
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
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldDidChange(textField: UITextField)
    {
        if(resetPasswordTextfield.text!.isEmpty || reEnterPasswordTextField.text!.isEmpty)
        {
            resetButton.hidden = true
        }
        else{
            let decimalChrSet = NSCharacterSet.decimalDigitCharacterSet()
            
            if((resetPasswordTextfield.text?.characters.count < 8) || (resetPasswordTextfield.text?.characters.count > 40))
            {
                resetButton.hidden = true
            }
            if((reEnterPasswordTextField.text?.characters.count < 8) || (reEnterPasswordTextField.text?.characters.count > 40))
            {
                resetButton.hidden = true
            }
            else if resetPasswordTextfield.text!.rangeOfCharacterFromSet(decimalChrSet) == nil
            {
                resetButton.hidden = true
            }
            else if reEnterPasswordTextField.text!.rangeOfCharacterFromSet(decimalChrSet) == nil
            {
                resetButton.hidden = true
            }
            else{
                resetButton.hidden = false
            }
        }
    }

    @IBAction func backButtonClicked(sender: AnyObject) {
        resetPasswordTextfield.text = ""
        reEnterPasswordTextField.text = ""
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func resetPasswordClicked(sender: AnyObject) {
        let text = resetPasswordTextfield.text!
        let reEnteredtext = reEnterPasswordTextField.text!
        
//        if resetPasswordTextfield.text!.isEmpty
//        {
//            ErrorManager.sharedInstance.newPaswrdEmpty()
//        }
//        else if reEnterPasswordTextField.text!.isEmpty
//        {
//            ErrorManager.sharedInstance.confirmPaswrdEmpty()
//        }
//        else
        if(text != reEnteredtext){
            ErrorManager.sharedInstance.passwordMismatch()
//            resetPasswordTextfield.text = ""
//            reEnterPasswordTextField.text = ""
        }
        else
        {
//            let chrSet = NSCharacterSet.decimalDigitCharacterSet()
//            if((text.characters.count < 8) || (text.characters.count > 40))
//            {
//                ErrorManager.sharedInstance.InvalidPwdEnteredError()
//                resetPasswordTextfield.text = ""
//                reEnterPasswordTextField.text = ""
//                resetPasswordTextfield.becomeFirstResponder()
//                return
//            }
//            else if text.rangeOfCharacterFromSet(chrSet) == nil {
//                ErrorManager.sharedInstance.noNumberInPassword()
//                resetPasswordTextfield.text = ""
//                reEnterPasswordTextField.text = ""
//                resetPasswordTextfield.becomeFirstResponder()
//                return
//            }
//            else{
                let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
                let  accessToken =  NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
                self.showOverlay()
                ProfileManager.sharedInstance.resetPassword(userId, accessToken: accessToken, resetPassword: resetPasswordTextfield.text!, success: { (response) in
                    self.SuccessHandler(response!)
                }) { (error, code) in
                    self.removeOverlay()
                    ErrorManager.sharedInstance.failedToUpdatepassword()
                }
            }
//        }
    }
    
    func SuccessHandler(response : AnyObject?)
    {
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                let alert = UIAlertController(title: "Success", message: "Password updated successfully", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    self.dismissViewControllerAnimated(false, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        else
        {
            ErrorManager.sharedInstance.failedToUpdatepassword()
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

extension ResetPasswordViewController : UITextFieldDelegate{
    
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