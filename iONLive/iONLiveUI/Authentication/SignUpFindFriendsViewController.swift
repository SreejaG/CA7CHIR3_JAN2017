
import AddressBook
import AddressBookUI
import UIKit

class SignUpFindFriendsViewController: UIViewController{
    
    private var addressBookRef: ABAddressBookRef?
    
    func setAddressBook(addressBook: ABAddressBookRef) {
        addressBookRef = addressBook
    }
    
    static let identifier = "SignUpFindFriendsViewController"
    
    let requestManager = RequestManager.sharedInstance
    let contactManagers = contactManager.sharedInstance
    var phoneCode: String!
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var contactPhoneNumbers: [String] = [String]()
    let nameKey = "user_name"
    let phoneKey = "mobile_no"
    let imageKey = "profile_image"
    let inviteKey = "invitationKey"
    var loadingOverlay: UIView?
    var contactExist: Bool = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
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
        let addressBookRef1 = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        setAddressBook(addressBookRef1)
    }
    
    @IBAction func continueButtonClicked(sender: AnyObject) {
        contactAuthorizationAlert()
    }
    
    func contactAuthorizationAlert()
    {
        let authorizationStatus = ABAddressBookGetAuthorizationStatus()
        switch authorizationStatus {
        case .Denied, .Restricted:
            generateContactSynchronizeAlert()
        case .Authorized:
            displayContacts()
        case .NotDetermined:
            promptForAddressBookRequestAccess()
        }
    }
    
    func generateContactSynchronizeAlert()
    {
        let alert = UIAlertController(title: "\"Catch\" would like to access your contacts", message: "The contacts in your address book will be transmitted to Catch for you to decide who to add", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Don't Allow", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
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
                    self.generateContactSynchronizeAlert()
                } else {
                    self.displayContacts()
                }
            }
        }
    }
    func displayContacts(){
        showOverlay()
        contactPhoneNumbers.removeAll()
        let allContacts = ABAddressBookCopyArrayOfAllPeople(addressBookRef).takeRetainedValue() as Array
        for record in allContacts {
            let phones : ABMultiValueRef = ABRecordCopyValue(record,kABPersonPhoneProperty).takeUnretainedValue() as ABMultiValueRef
            var phoneNumber: String = String()
            var appendPlus : String = String()
            for numberIndex : CFIndex in 0 ..< ABMultiValueGetCount(phones)
            {
                let phoneUnmaganed = ABMultiValueCopyValueAtIndex(phones, numberIndex)
                let phoneNumberStr = phoneUnmaganed.takeUnretainedValue() as! String
                let phoneNumberWithCode: String!
                if(phoneNumberStr.hasPrefix("+")){
                    phoneNumberWithCode = phoneNumberStr
                }
                else if(phoneNumberStr.hasPrefix("00")){
                    let stringLength = phoneNumberStr.characters.count
                    let subStr = (phoneNumberStr as NSString).substringWithRange(NSRange(location: 2, length: stringLength - 2))
                    phoneNumberWithCode = phoneCode.stringByAppendingString(subStr)
                }
                else if(phoneNumberStr.hasPrefix("0")){
                    let stringLength = phoneNumberStr.characters.count
                    let subStr = (phoneNumberStr as NSString).substringWithRange(NSRange(location: 1, length: stringLength - 1))
                    phoneNumberWithCode = phoneCode.stringByAppendingString(subStr)
                }
                else{
                    phoneNumberWithCode = phoneCode.stringByAppendingString(phoneNumberStr)
                }
                
                if phoneNumberWithCode.hasPrefix("+")
                {
                    appendPlus = "+"
                }
                else{
                    appendPlus = "nil"
                }
                
                let phoneNumberStringArray = phoneNumberWithCode.componentsSeparatedByCharactersInSet(
                    NSCharacterSet.decimalDigitCharacterSet().invertedSet)
                if appendPlus == "+"
                {
                    phoneNumber = appendPlus.stringByAppendingString(NSArray(array: phoneNumberStringArray).componentsJoinedByString("")) as String
                }
                contactPhoneNumbers.append(phoneNumber)
            }
            var currentContactImage : UIImage = UIImage()
            
            if let currentContactImageData = ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail)?.takeRetainedValue() as CFDataRef!
            {
                currentContactImage = UIImage(data: currentContactImageData)!
            }
            else{
                currentContactImage = UIImage(named: "avatar")!
            }
            
            if(phoneNumber != ""){
                contactPhoneNumbers.append(phoneNumber)
                var currentContactName = String()
                if ABRecordCopyCompositeName(record) != nil
                {
                    currentContactName = ABRecordCopyCompositeName(record).takeRetainedValue() as String
                }
                else{
                    currentContactName = "No Name"
                }
                
                self.dataSource.append([self.nameKey: currentContactName, self.phoneKey: phoneNumber, self.imageKey: currentContactImage, "orgSelected":0, "tempSelected":0])
            }
        }
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
        contactManagers.addContactDetails(userId, accessToken: accessToken, userContacts: contactPhoneNumbers, success:  { (response) -> () in
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
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
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
    
    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://\(vowzaIp):1935/live", parameters: nil , liveVideo: true) as! UIViewController
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
        removeOverlay()
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let contactDetailsViewController = storyboard.instantiateViewControllerWithIdentifier("ContactDetailsViewController") as! ContactDetailsViewController
        contactDetailsViewController.contactDataSource = dataSource
        contactDetailsViewController.contactExistChk = contactExist
        contactDetailsViewController.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(contactDetailsViewController, animated: true)
    }
}
