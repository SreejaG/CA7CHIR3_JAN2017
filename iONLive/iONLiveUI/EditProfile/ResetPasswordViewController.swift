
import UIKit

class ResetPasswordViewController: UIViewController {
    
    static let identifier = "ResetPasswordViewController"
    let requestManager = RequestManager.sharedInstance
    
    var loadingOverlay: UIView?
    
    @IBOutlet weak var reEnterPasswordTextField: UITextField!
    @IBOutlet weak var resetPasswordTextfield: UITextField!
    @IBOutlet weak var resetPasswdBottomConstraint: NSLayoutConstraint!
    @IBOutlet var resetButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ResetPasswordViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        resetButton.isHidden = true
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
        reEnterPasswordTextField.autocorrectionType = UITextAutocorrectionType.no
        resetPasswordTextfield.autocorrectionType = UITextAutocorrectionType.no
        reEnterPasswordTextField.isSecureTextEntry = true
        resetPasswordTextfield.isSecureTextEntry = true
        
        resetPasswordTextfield.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        reEnterPasswordTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        
        addObserver()
    }
    
    func addObserver()
    {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(ResetPasswordViewController.keyboardDidShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardDidShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(ResetPasswordViewController.KeyboardDidHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardDidHide,
                                               object: nil)
    }
    
    //PRAGMA MARK:- keyboard notification handler
    func keyboardDidShow(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.view.layoutIfNeeded()
        if resetPasswdBottomConstraint.constant == 0
        {
            UIView.animate(withDuration: 1.0, animations: { () -> Void in
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
            UIView.animate(withDuration: 1.0, animations: { () -> Void in
                self.resetPasswdBottomConstraint.constant = 0
            })
        }
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldDidChange(_ textField: UITextField)
    {
        if(resetPasswordTextfield.text!.isEmpty || reEnterPasswordTextField.text!.isEmpty)
        {
            resetButton.isHidden = true
        }
        else{
            let decimalChrSet = NSCharacterSet.decimalDigits
            
            if(((resetPasswordTextfield.text?.characters.count)! < 8) || ((resetPasswordTextfield.text?.characters.count)! > 40))
            {
                resetButton.isHidden = true
            }
            if(((reEnterPasswordTextField.text?.characters.count)! < 8) || ((reEnterPasswordTextField.text?.characters.count)! > 40))
            {
                resetButton.isHidden = true
            }
            else if (resetPasswordTextfield.text! as String).rangeOfCharacter(from: decimalChrSet) == nil
            {
                resetButton.isHidden = true
            }
            else if (reEnterPasswordTextField.text! as String).rangeOfCharacter(from: decimalChrSet) == nil
            {
                resetButton.isHidden = true
            }
            else{
                resetButton.isHidden = false
            }
        }
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        resetPasswordTextfield.text = ""
        reEnterPasswordTextField.text = ""
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func resetPasswordClicked(_ sender: Any) {
        let text = resetPasswordTextfield.text!
        let reEnteredtext = reEnterPasswordTextField.text!
        if(text != reEnteredtext){
            ErrorManager.sharedInstance.passwordMismatch()
        }
        else
        {
            let userId = UserDefaults.standard.value(forKey: userLoginIdKey) as! String
            let  accessToken =  UserDefaults.standard.value(forKey: userAccessTockenKey) as! String
            self.showOverlay()
            ProfileManager.sharedInstance.resetPassword(userName: userId, accessToken: accessToken, resetPassword: resetPasswordTextfield.text!, success: { (response) in
                self.SuccessHandler(response: response!)
            }) { (error, code) in
                self.authenticationFailureHandler(error: error, code: code)
                return
            }
        }
    }
    
    func SuccessHandler(response : AnyObject?)
    {
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                let alert = UIAlertController(title: "Success", message: "Password updated successfully", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                    self.dismiss(animated: false, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        else
        {
            ErrorManager.sharedInstance.failedToUpdatepassword()
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
                loadInitialViewController(code: code)
            }
            else{
                ErrorManager.sharedInstance.failedToUpdatepassword()
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func  loadInitialViewController(code: String){
        if let tokenValid = UserDefaults.standard.value(forKey: "tokenValid")
        {
            if tokenValid as! String == "true"
            {
                DispatchQueue.main.async {
                    let documentsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] + "/GCSCA7CH"
                    
                    if(FileManager.default.fileExists(atPath: documentsPath))
                    {
                        let fileManager = FileManager.default
                        do {
                            try fileManager.removeItem(atPath: documentsPath)
                        }
                        catch _ as NSError {
                        }
                        _ = FileManagerViewController.sharedInstance.createParentDirectory()
                    }
                    else{
                        _ = FileManagerViewController.sharedInstance.createParentDirectory()
                    }
                    
                    let defaults = UserDefaults .standard
                    let deviceToken = defaults.value(forKey: "deviceToken") as! String
                    defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    defaults.setValue(deviceToken, forKey: "deviceToken")
                    defaults.set(1, forKey: "shutterActionMode");
                    defaults.setValue("false", forKey: "tokenValid")
                    
                    ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
                    
                    let sharingStoryboard = UIStoryboard(name:"Authentication", bundle: nil)
                    let channelItemListVC = sharingStoryboard.instantiateViewController(withIdentifier: "AuthenticateViewController") as! AuthenticateViewController
                    channelItemListVC.navigationController?.isNavigationBarHidden = true
                    self.navigationController?.pushViewController(channelItemListVC, animated: false)
                }
            }
        }
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRect(x:0, y:64, width:self.view.frame.width, height:self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
}

extension ResetPasswordViewController : UITextFieldDelegate{
    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        textField.layoutIfNeeded()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
}
