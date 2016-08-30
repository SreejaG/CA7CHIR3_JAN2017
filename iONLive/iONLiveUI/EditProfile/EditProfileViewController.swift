
import UIKit

class EditProfileViewController: UIViewController, UINavigationControllerDelegate,UIImagePickerControllerDelegate,NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate,UITextFieldDelegate {
    
    static let identifier = "EditProfileViewController"
    @IBOutlet weak var editProfileTableView: UITableView!
    
    var fullNames : String = String()
    var userName : String = String()
    var emails : String = String()
    var mobileNo : String = String()
    var timeZoneInSecondsFromAPI : String = String()
    var timeZoneInSecondsUpdated : String = String()
    var timeZoneOffsetInUTCOriginal = String()
    var timeZoneOffsetInUTCUpdated : String = String()
    
    var email: String = String()
    var mobNo: String = String()
    var fullName: String = String()
    var ZoneInSeconds : String = String()
    
    let requestManager = RequestManager.sharedInstance
    let profileManager = ProfileManager.sharedInstance
    let imageUploadManger = ImageUpload.sharedInstance
    
    var activeField: UITextField = UITextField()
    
    var loadingOverlay: UIView?
    let imagePicker = UIImagePickerController()
    var imageForProfile : UIImage = UIImage()
    var imageForProfileOld : UIImage = UIImage()
    
    var fullImageURL : String = String()
    var thumbURL : String = String()
    
    var cellSection = Int()
    
    @IBOutlet weak var tableViewBottomConstaint: NSLayoutConstraint!
    
    @IBOutlet weak var saveButton: UIButton!
    
    let userNameKey = "userNameKey"
    let displayNameKey = "displayNameKey"
    let titleKey = "titleKey"
    let privateInfoKey = "privateInfo"
    
    let personalInfoCell = "personalInfoCell"
    let accountInfoCell = "accountInfoCell"
    let privateInfoCell = "privateInfoCell"
    let countryPickerCell = "countryPickerCell"
    
    var profileInfoOptions = [[String:String]]()
    var privateInfoOptions = [[String:String]]()
    var accountInfoOptions = [[String:String]]()
    
    var dataSource:[[[String:String]]]?
    
    var userDetails: NSMutableDictionary = NSMutableDictionary()
    
    @IBOutlet weak var editProfTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialise()
        
        NSNotificationCenter .defaultCenter() .addObserver(self, selector: #selector(EditProfileViewController.keyBoardWasShown(_:)), name: UIKeyboardDidShowNotification, object: nil)
    }
    
    @IBAction func tapGestureRecognizer(sender: AnyObject) {
        view.endEditing(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.editProfTableView.backgroundView = nil
        self.editProfTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
        addKeyboardObservers()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func initialise()
    {
        saveButton.hidden = true
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getUserDetails(userId, token: accessToken)
    }
    
    func getUserDetails(userName: String, token: String)
    {
        showOverlay()
        profileManager.getUserDetails(userName, accessToken:token, success: { (response) -> () in
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
                catch let error as NSError {
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
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["user"] as! [AnyObject]
            let userDict: NSMutableDictionary = NSMutableDictionary()
            
            for element in responseArr{
                userDict.setDictionary(element as! [NSObject : AnyObject])
            }
            for (key,value) in userDict
            {
                let valueAfterNullCheck =  nullToNil(value)
                userDetails.setValue(valueAfterNullCheck!, forKey: key as! String)
            }
            setUserDetails()
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
        dataSource![0][0][displayNameKey] = fullNames
        dataSource![2][0][privateInfoKey] = emails
        dataSource![2][1][privateInfoKey] = mobileNo
        dataSource![1][3][titleKey] = timeZoneOffsetInUTCOriginal
        editProfTableView.reloadData()
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
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func setUserDetails()
    {
        imageForProfile = UIImage()
        fullNames = userDetails["full_name"] as! String
        userName = userDetails["user_name"] as! String
        emails = userDetails["email"] as! String
        mobileNo = userDetails["mobile_no"] as! String
        timeZoneInSecondsFromAPI = userDetails["user_time_zone"] as! String
        
        let hoursFromOffset = Int(timeZoneInSecondsFromAPI)! / 3600
        let minutesFromOffset = (Int(timeZoneInSecondsFromAPI)! % 3600) / 60
        var addOrMinusChk = String()
        if timeZoneInSecondsFromAPI.hasPrefix("-"){
            addOrMinusChk = ""
        }
        else{
            addOrMinusChk = "+"
        }
        
        timeZoneOffsetInUTCOriginal = "UTC\(addOrMinusChk)\(hoursFromOffset):\(minutesFromOffset)"
        
        let thumbUrl =  userDetails["profile_image_thumbnail"] as! String
        if(thumbUrl != "")
        {
            let url: NSURL = convertStringtoURL(thumbUrl)
            if let data = NSData(contentsOfURL: url){
                let imageDetailsData = (data as NSData?)!
                imageForProfile = UIImage(data: imageDetailsData)!
            }
            else{
                imageForProfile = UIImage(named: "dummyUser")!
            }
        }
        else{
            imageForProfile = UIImage(named: "dummyUser")!
        }
        imageForProfileOld = imageForProfile
        
        profileInfoOptions = [[displayNameKey:fullNames, userNameKey:userName]]
        accountInfoOptions = [[titleKey:"Upgrade to Premium Account"], [titleKey:"Status"], [titleKey:"Reset Password"], [titleKey:timeZoneOffsetInUTCOriginal]]
        privateInfoOptions = [[privateInfoKey:emails],/*[titleKey:location],*/[privateInfoKey:mobileNo]]
        
        dataSource = [profileInfoOptions,accountInfoOptions,privateInfoOptions]
        editProfTableView.reloadData()
    }
    
    func ltzAbbrev() -> String
    {
        let zoneName = NSTimeZone.localTimeZone().name
        let timeValue = NSTimeZone.localTimeZone().localizedName(.ShortStandard, locale: NSLocale.init(localeIdentifier: zoneName))
        return timeValue!
    }
    
    @IBAction func saveClicked(sender: AnyObject) {
        saveButton.hidden = true
        showOverlay()
        getSignedUrl()
    }
    
    func generateWaytoSendAlert()
    {
        let alert = UIAlertController(title: "Not Saved", message: "Do you want to save the details", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.saveButton.hidden = true
            self.showOverlay()
            self.getSignedUrl()
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
    
    @IBAction func backClicked(sender: AnyObject) {
        if(saveButton.hidden == false){
            generateWaytoSendAlert()
        }
        else{
            self.navigationController?.popViewControllerAnimated(false)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getSignedUrl()  {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        profileManager.getUploadProfileImageURL(userId, accessToken: accessToken, success: { (response) in
            self.authenticationSuccessHandlerSignedUrl(response)
        }) { (error, message) in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerSignedUrl(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            if let fullUrl = json["UploadActualImageUrl"]{
                fullImageURL = fullUrl as! String
            }
            if let thumbUrl = json["UploadThumbnailUrl"]{
                thumbURL = thumbUrl as! String
            }
            
            let cameraController = IPhoneCameraViewController()
            let sizeThumb = CGSizeMake(70,70)
            let imageAfterConversionThumbnail = cameraController.thumbnaleImage(self.imageForProfile, scaledToFillSize: sizeThumb)
            let imageData = UIImageJPEGRepresentation(imageAfterConversionThumbnail, 0.5)
            let imagethumbDetailsData = (imageData as NSData?)!
            let thumbImageForProfile = UIImage(data:imagethumbDetailsData)
            
            uploadImage(fullImageURL, imageToSave: imageForProfile, completion: { (result) in
                self.uploadImage(self.thumbURL, imageToSave: thumbImageForProfile!, completion: { (result) in
                    if(result == "Success"){
                        self.imageForProfileOld = self.imageForProfile
                    }
                    else{
                        self.imageForProfile = self.imageForProfileOld
                    }
                })
            })
            self.updateProfileDetails()
        }
    }
    
    func  updateProfileDetails() {
        view.endEditing(true)
        editProfTableView.reloadData()
        editProfTableView.layoutIfNeeded()
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        for(var i = 0; i < dataSource?.count; i += 1)
        {
            var j = 0
            if i == 0
            {
                for  element in  dataSource![i]
                {
                    fullName = element[displayNameKey]!
                }
            }
            else if( i == 2){
                for  element in  dataSource![i]
                {
                    if j == 0
                    {
                        email = element[privateInfoKey]!
                    }
                    else{
                        mobNo = element[privateInfoKey]!
                    }
                    j = j + 1
                }
            }
        }
        var timeUpdate = String()
        if timeZoneInSecondsUpdated == ""
        {
            timeUpdate = timeZoneInSecondsFromAPI
        }
        else{
            timeUpdate = timeZoneInSecondsUpdated
        }
        let phoneNumberStringArray = mobNo.componentsSeparatedByCharactersInSet(
            NSCharacterSet.decimalDigitCharacterSet().invertedSet)
        let phoneNumber = "+".stringByAppendingString(NSArray(array: phoneNumberStringArray).componentsJoinedByString("")) as String
        profileManager.updateUserDetails(userId, accessToken: accessToken, email: email, location: "", mobNo: phoneNumber, fullName: fullName, timeZone: timeUpdate, success: { (response) in
            self.removeOverlay()
            let savingPath = "\(userId)Profile"
            FileManagerViewController.sharedInstance.saveImageToFilePath(savingPath, mediaImage: self.imageForProfile)
            self.fullNames = self.fullName
            self.mobileNo = self.mobNo
            self.emails = self.email
            self.timeZoneOffsetInUTCOriginal = self.timeZoneOffsetInUTCUpdated
            self.timeZoneInSecondsFromAPI = self.timeZoneInSecondsUpdated
        }) { (error, message) in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func  uploadImage(signedUrl: String, imageToSave: UIImage, completion: (result: String) -> Void)
    {
        let url = NSURL(string: signedUrl)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
        let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        var imageData: NSData = NSData()
        imageData = UIImageJPEGRepresentation(imageToSave, 0.5)!
        request.HTTPBody = imageData
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                completion(result:"Failed")
            }
            else {
                completion(result:"Success")
            }
        }
        dataTask.resume()
    }
    
    func addKeyboardObservers()
    {
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:"keyboardDidShow:", name: UIKeyboardDidShowNotification, object:nil)]
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:"keyboardDidHide", name: UIKeyboardWillHideNotification, object:nil)]
    }
    
    func keyboardDidShow(notification:NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if tableViewBottomConstaint.constant == 0
        {
            self.tableViewBottomConstaint.constant = self.tableViewBottomConstaint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if tableViewBottomConstaint.constant != 0
        {
            self.tableViewBottomConstaint.constant = 0
        }
    }
}

extension EditProfileViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if section == 0
        {
            return 30.0
        }
        else if section == 3
        {
            return 60.0
        }
        else
        {
            return 55.0
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(EditProfileHeaderCell.identifier) as! EditProfileHeaderCell
        
        headerCell.borderLine.hidden = false
        headerCell.topBorderLine.hidden = false
        
        switch (section) {
        case 0:
            headerCell.headerTitleLabel.text = ""
            headerCell.topBorderLine.hidden = true
        case 1:
            headerCell.headerTitleLabel.text = "ACCOUNT INFO"
        case 2:
            headerCell.headerTitleLabel.text = "PRIVATE INFO"
        case 3:
            let privacyPolicyDesc = NSMutableAttributedString(string: "All your Media is Private unless Channels are shared to specific people. Archive is always private to you.")
            let privacyPolicyString = NSMutableAttributedString(string:"\nPrivacy Policy")
            privacyPolicyString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 44.0/255, green: 214.0/255, blue: 229.0/255, alpha: 1.0), range: NSMakeRange(0, privacyPolicyString.length))
            privacyPolicyDesc.appendAttributedString(privacyPolicyString)
            
            headerCell.headerTitleLabel.attributedText = privacyPolicyDesc
            headerCell.borderLine.hidden = true
            
        default:
            headerCell.headerTitleLabel.text = ""
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        if indexPath.section == 0
        {
            return 90.0
        }
        else
        {
            return 44.0
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
}


extension EditProfileViewController:UITableViewDataSource
{
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch section
        {
        case 0:
            return dataSource != nil ? (dataSource?[0].count)! :0
            
        case 1:
            return dataSource != nil ? (dataSource?[1].count)! :0
            
        case 2:
            return dataSource != nil ? (dataSource?[2].count)! :0
            
        case 3:
            return 0
            
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.section && dataSource[indexPath.section].count > indexPath.row
            {
                var cellDataSource = dataSource[indexPath.section][indexPath.row]
                switch indexPath.section
                {
                case 0:
                    
                    let cell = tableView.dequeueReusableCellWithIdentifier(EditProfPersonalInfoCell.identifier, forIndexPath:indexPath) as! EditProfPersonalInfoCell
                    cell.editProfileImageButton.addTarget(self, action: "editProfileTapped:", forControlEvents: UIControlEvents.TouchUpInside)
                    
                    if cellDataSource[displayNameKey] == ""
                    {
                        cell.displayNameTextField.attributedPlaceholder = NSAttributedString(string: "Name", attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
                    }
                    let cameraController = IPhoneCameraViewController()
                    let sizeThumb = CGSizeMake(70,70)
                    let imageAfterConversionThumbnail = cameraController.thumbnaleImage(self.imageForProfileOld, scaledToFillSize: sizeThumb)
                    imageForProfileOld = imageAfterConversionThumbnail
                    cell.userImage.image = imageForProfile
                    
                    cell.userNameTextField.text = cellDataSource[userNameKey]
                    cell.userNameTextField.userInteractionEnabled = false
                    
                    cell.displayNameTextField.text = cellDataSource[displayNameKey]
                    
                    cell.displayNameTextField.tag = indexPath.section
                    cell.displayNameTextField.delegate = self
                    
                    cell.selectionStyle = .None
                    return cell
                    
                case 1:
                    let cell = tableView.dequeueReusableCellWithIdentifier(EditProfAccountInfoCell.identifier, forIndexPath:indexPath) as! EditProfAccountInfoCell
                    cell.accountInfoTitleLabel.text = cellDataSource[titleKey]
                    if dataSource[indexPath.section].count-1 == indexPath.row
                    {
                        cell.borderLine.hidden = true
                        cell.selectionStyle = .Default
                    }
                    else
                    {
                        cell.borderLine.hidden = false
                        cell.selectionStyle = .Default
                    }
                    if indexPath.row == 3
                    {
                        cell.accessoryType = .None
                        cell.selectionStyle = .None
                        let image = UIImage(named: "synchronising.png")
                        let button   = UIButton(type: UIButtonType.Custom) as UIButton
                        button.frame = CGRectMake(cell.frame.width - 30, cell.frame.height/2 - 10, 25, 25)
                        button.backgroundColor = UIColor.clearColor()
                        button.setImage(image, forState: .Normal)
                        button.addTarget(self, action: #selector(EditProfileViewController.synchronisingTapped(_:)), forControlEvents:.TouchUpInside)
                        cell.addSubview(button)
                    }
                    
                    return cell
                    
                case 2:
                    let cell = tableView.dequeueReusableCellWithIdentifier(EditProfPrivateInfoCell.identifier, forIndexPath:indexPath) as! EditProfPrivateInfoCell
                    cell.privateInfoTitleLabel.tag = 100 + indexPath.row
                    if(indexPath.row == 1){
                        cell.privateInfoTitleLabel.keyboardType = .PhonePad
                    }
                    else{
                        cell.privateInfoTitleLabel.keyboardType = .Default
                    }
                    cell.privateInfoTitleLabel.delegate = self
                    cellSection = indexPath.row
                    
                    cell.privateInfoTitleLabel.text = cellDataSource[privateInfoKey]
                    
                    if dataSource[indexPath.section].count-1 == indexPath.row
                    {
                        cell.borderLine.hidden = true
                    }
                    else
                    {
                        cell.borderLine.hidden = false
                    }
                    cell.selectionStyle = .None
                    return cell
                    
                default:
                    return UITableViewCell()
                }
            }
        }
        return UITableViewCell()
    }
    
    func synchronisingTapped(sender: AnyObject)
    {
        let timeOffset = NSTimeZone.systemTimeZone().secondsFromGMT
        let timeOffsetStr = String(timeOffset)
        if timeOffsetStr.hasPrefix("-")
        {
            timeZoneInSecondsUpdated = timeOffsetStr
        }
        else
        {
            timeZoneInSecondsUpdated = "+\(timeOffsetStr)"
        }
        
        if timeZoneInSecondsUpdated != timeZoneInSecondsFromAPI
        {
            let timeZoneOffsetInGMT : String = ltzAbbrev()
            let timeZoneOffsetStr = (timeZoneOffsetInGMT as NSString).stringByReplacingOccurrencesOfString("GMT", withString: "UTC")
            dataSource![1][3][titleKey] = timeZoneOffsetStr
            saveButton.hidden = false
        }
        let indexPath = NSIndexPath(forRow: 3, inSection: 1)
        self.editProfTableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        activeField = textField
        saveButton.hidden = false
    }
    
    func keyBoardWasShown(notif:NSNotification)
    {
        if(activeField.tag >= 100)
        {
            var info: NSDictionary = NSDictionary()
            info = notif .userInfo!
            let kbSize : CGSize = info.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
            var bkgndRect:CGRect = (activeField.superview?.frame)!
            bkgndRect.size.height += kbSize.height
            activeField.superview?.frame = bkgndRect
            editProfTableView.setContentOffset(CGPointMake(0, activeField.frame.origin.y + kbSize.height - 70), animated: true)
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        activeField = UITextField()
        
        if(textField.tag == 0)
        {
            if((textField.text?.isEmpty) == nil){
                
                dataSource![textField.tag][0][displayNameKey] = ""
            }
            else{
                dataSource![textField.tag][0][displayNameKey] = textField.text
            }
            textField.attributedPlaceholder = NSAttributedString(string: "Name",
                                                                 attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        }
        else if(textField.tag == 100){
            let isEmailValid = isEmail(textField.text!) as Bool!
            if isEmailValid == false
            {
                ErrorManager.sharedInstance.loginInvalidEmail()
                return
            }
            else
            {
                dataSource![2][0][privateInfoKey] = textField.text
            }
        }
        else if(textField.tag == 101){
            let textStr = textField.text
            if(textStr!.hasPrefix("+")){
                dataSource![2][1][privateInfoKey] = textField.text
            }
            else{
                ErrorManager.sharedInstance.withouCodeMobNumber()
                return
            }
        }
    }
    
    func isEmail(email:String) -> Bool {
        let regex = try? NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .CaseInsensitive)
        return regex?.firstMatchInString(email, options: [], range: NSMakeRange(0, email.characters.count)) != nil
    }
    
    func editProfileTapped(sender:UIButton!)
    {
        self.imagePicker.delegate = self
        let myActionSheet = UIAlertController(title: "", message: "How would you like to set your photo?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let takeAction = UIAlertAction(title: "Take a photo", style: UIAlertActionStyle.Default) { (action) in
            if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
                if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
                    self.imagePicker.allowsEditing = false
                    self.imagePicker.sourceType = .Camera
                    self.imagePicker.cameraCaptureMode = .Photo
                    self.presentViewController(self.imagePicker, animated: true, completion: {
                        
                    })
                    
                } else {
                }
            } else {
            }
        }

        let chooseAction = UIAlertAction(title: "Choose a photo", style: UIAlertActionStyle.Default) { (action) in
           
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .SavedPhotosAlbum
            self.presentViewController(self.imagePicker, animated: true, completion: nil)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) in
            print("Cancel action button tapped")
        }
        
        myActionSheet.addAction(takeAction)
        myActionSheet.addAction(chooseAction)
        myActionSheet.addAction(cancelAction)
        
        self.presentViewController(myActionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
        imageForProfile = image
        saveButton.hidden = false
        editProfTableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if let dataSource = dataSource
        {
            return dataSource.count + 1
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
    }
}

