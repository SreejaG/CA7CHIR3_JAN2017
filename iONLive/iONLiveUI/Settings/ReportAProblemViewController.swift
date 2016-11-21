
import UIKit

class ReportAProblemViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet var probelmTitle: UITextField!
    @IBOutlet var descTextView: UITextView!
    @IBOutlet var saveButton: UIButton!
    
    let requestManager = RequestManager.sharedInstance
    let reportManager = ReportManager.sharedInstance
    
    static let identifier = "ReportAProblemViewController"
    
    var loadingOverlay: UIView?
    
    let defaults = UserDefaults.standard
    var userId : String = String()
    var accessToken: String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func gestureTapped(_ sender: Any) {
        view.endEditing(true)
    }
    
    func initialise() {
        userId = defaults.value(forKey: userLoginIdKey) as! String
        accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        
        saveButton.isHidden = true
        
        descTextView.textColor = UIColor.lightGray
        descTextView.delegate = self
        descTextView.text = "Description"
        descTextView.alpha = 0.7
        
        descTextView.layer.borderColor = UIColor.lightGray.cgColor
        probelmTitle.layer.borderColor = UIColor.lightGray.cgColor
        
        descTextView.layer.borderWidth = 0.5
        probelmTitle.layer.borderWidth = 0.5
        
        probelmTitle.delegate = self
    }
    
    @IBAction func didTapSaveButton(_ sender: Any) {
        saveButton.isHidden = true
        descTextView.resignFirstResponder()
        probelmTitle.resignFirstResponder()
        if probelmTitle.text!.isEmpty
        {
            ErrorManager.sharedInstance.probelmTitleEmpty()
        }
        else if(descTextView.text!.isEmpty || descTextView.text == "Description")
        {
            ErrorManager.sharedInstance.descOfProblemEmpty()
        }
        else{
            showOverlay()
            let title = probelmTitle.text
            let desc = descTextView.text as String
            reportProblem(title: title!, desc: desc)
        }
    }
    
    func reportProblem(title: String, desc: String) {
        reportManager.reportAProblem(userName: userId, accessToken: accessToken, problemTitle: title, probelmDesc: desc, success: { (response) in
            self.authenticationSuccessHandler(response: response)
        }, failure: { (error, message) in
            self.authenticationFailureHandler(error: error, code: message)
            return
        })
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        descTextView.text = ""
        probelmTitle.text = ""
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                let alert = UIAlertController(title: "Success", message: "Mail send successfully", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                    self.redirect()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
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
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        descTextView.resignFirstResponder()
        probelmTitle.resignFirstResponder()
        if(saveButton.isHidden == false){
            if (probelmTitle.text!.isEmpty || descTextView.text == "Description"){
                _ = self.navigationController?.popViewController(animated: false)
            }
            else{
                generateWaytoSendAlert()
            }
        }
        else{
            _ = self.navigationController?.popViewController(animated: false)
        }
    }
    
    func generateWaytoSendAlert()
    {
        let alert = UIAlertController(title: "Not Reported", message: "Do you want report a problem", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.saveButton.isHidden = true
            self.showOverlay()
            let title = self.probelmTitle.text
            let desc = self.descTextView.text as String
            self.reportProblem(title: title!, desc: desc)
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: {
            (action) -> Void in
            self.redirect()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func redirect() {
        _ = self.navigationController?.popViewController(animated: false)
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
    
    func  loadInitialViewController(code: String){
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
            
            let defaults = UserDefaults.standard
            let deviceToken = defaults.value(forKey: "deviceToken") as! String
            defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            defaults.setValue(deviceToken, forKey: "deviceToken")
            defaults.set(1, forKey: "shutterActionMode");
            
            let sharingStoryboard = UIStoryboard(name:"Authentication", bundle: nil)
            let channelItemListVC = sharingStoryboard.instantiateViewController(withIdentifier: "AuthenticateNavigationController") as! AuthenticateNavigationController
            channelItemListVC.navigationController?.isNavigationBarHidden = true
            self.present(channelItemListVC, animated: false) { () -> Void in
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
            }
        }
    }
}

extension ReportAProblemViewController: UITextViewDelegate
{
    func textViewDidBeginEditing(_ textView: UITextView) {
        saveButton.isHidden = false
        if(descTextView.text == "Description"){
            descTextView.text = nil
        }
        descTextView.textColor = UIColor.black
        descTextView.alpha = 1.0
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if(descTextView.text == ""){
            descTextView.textColor = UIColor.lightGray
            descTextView.text = "Description"
            descTextView.alpha = 0.7
        }
    }
}

extension ReportAProblemViewController : UITextFieldDelegate
{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isHidden = false
    }
}

