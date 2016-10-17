
import UIKit

class ReportAProblemViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet var probelmTitle: UITextField!
    @IBOutlet var descTextView: UITextView!
    @IBOutlet var saveButton: UIButton!
    
    let requestManager = RequestManager.sharedInstance
    let reportManager = ReportManager.sharedInstance
    
    static let identifier = "ReportAProblemViewController"

    var loadingOverlay: UIView?
    
    let defaults = NSUserDefaults .standardUserDefaults()
    var userId : String = String()
    var accessToken: String = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func gestureTapped(sender: AnyObject) {
        view.endEditing(true)
    }
    
    func initialise() {
        userId = defaults.valueForKey(userLoginIdKey) as! String
        accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        saveButton.hidden = true
        
        descTextView.textColor = UIColor.lightGrayColor()
        descTextView.delegate = self
        descTextView.text = "Description"
        descTextView.alpha = 0.7
        
        descTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
        probelmTitle.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        descTextView.layer.borderWidth = 0.5
        probelmTitle.layer.borderWidth = 0.5
        
        probelmTitle.delegate = self
    }
    
    @IBAction func didTapSaveButton(sender: AnyObject) {
        saveButton.hidden = true
        descTextView.resignFirstResponder()
        probelmTitle.resignFirstResponder()
        if probelmTitle.text!.isEmpty
        {
            ErrorManager.sharedInstance.descOfProblemEmpty()
        }
        else if descTextView.text!.isEmpty
        {
            ErrorManager.sharedInstance.descOfProblemEmpty()
        }
        else{
            showOverlay()
            let title = probelmTitle.text
            let desc = descTextView.text as String
            reportProblem(title!, desc: desc)
        }
    }
    
    func reportProblem(title: String, desc: String) {
        reportManager.reportAProblem(userId, accessToken: accessToken, problemTitle: title, probelmDesc: desc, success: { (response) in
            self.authenticationSuccessHandler(response)
            }, failure: { (error, message) in
                self.authenticationFailureHandler(error, code: message)
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
                let alert = UIAlertController(title: "Success", message: "Mail send successfully", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                      self.redirect()
                }))
                self.presentViewController(alert, animated: true, completion: nil)
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
                loadInitialViewController(code)
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }

    
    @IBAction func didTapBackButton(sender: AnyObject) {
        descTextView.resignFirstResponder()
        probelmTitle.resignFirstResponder()
        if(saveButton.hidden == false){
            if (probelmTitle.text!.isEmpty || descTextView.text == "Description"){
                self.navigationController?.popViewControllerAnimated(false)
            }
            else{
                generateWaytoSendAlert()
            }
        }
        else{
            self.navigationController?.popViewControllerAnimated(false)
        }
    }
    
    func generateWaytoSendAlert()
    {
        let alert = UIAlertController(title: "Not Reported", message: "Do you want report a problem", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.saveButton.hidden = true
            self.showOverlay()
            let title = self.probelmTitle.text
            let desc = self.descTextView.text as String
            self.reportProblem(title!, desc: desc)
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: {
            (action) -> Void in
            self.redirect()
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func redirect() {
        self.navigationController?.popViewControllerAnimated(false)
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
}

extension ReportAProblemViewController: UITextViewDelegate
{
    func textViewDidBeginEditing(textView: UITextView) {
        saveButton.hidden = false
        if(descTextView.text == "Description"){
            descTextView.text = nil
        }
        descTextView.textColor = UIColor.blackColor()
        descTextView.alpha = 1.0
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if(descTextView.text == ""){
            descTextView.textColor = UIColor.lightGrayColor()
            descTextView.text = "Description"
            descTextView.alpha = 0.7
        }
    }
}

extension ReportAProblemViewController : UITextFieldDelegate
{
    func textFieldDidBeginEditing(textField: UITextField) {
            saveButton.hidden = false
    }
}

