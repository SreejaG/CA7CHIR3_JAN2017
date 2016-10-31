
import AddressBook
import AddressBookUI
import UIKit

class ContactListViewController: UIViewController
{
    private var addressBookRef: ABAddressBookRef?
    
    func setAddressBook(addressBook: ABAddressBookRef) {
        addressBookRef = addressBook
    }
    
    static let identifier = "ContactListViewController"
    
    var channelId:String!
    var totalMediaCount: Int = Int()
    var channelName:String!
    
    var loadingOverlay: UIView?
    
    var contactPhoneNumbers: [String] = [String]()
    
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    let contactManagers = contactManager.sharedInstance
    
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var searchDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    let defaults = NSUserDefaults .standardUserDefaults()
    var userId = String()
    var accessToken = String()
    
    let userNameKey = "userName"
    let profileImageKey = "profileImage"
    let subscribedKey = "sharedindicator"
    let selectionKey = "selected"
    let profileImageUrlKey = "profile_image_URL"
    
    var searchActive: Bool = false
    
    var addUserArray : NSMutableArray = NSMutableArray()
    
    @IBOutlet var contactListSearchBar: UISearchBar!
    @IBOutlet var contactListTableView: UITableView!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var tableViewBottomConstraint: NSLayoutConstraint!
    
    var NoDatalabelFormySharingImageList : UILabel = UILabel()
    
    //Pull to refresh
    var refreshControl:UIRefreshControl!
    var pullToRefreshActive = false
    
    var operationQueueObjInSharingContactList = NSOperationQueue()
    var operationInSharingContactList = NSBlockOperation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userId = defaults.valueForKey(userLoginIdKey) as! String
        accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        addKeyboardObservers()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactListViewController.callRefreshContactListTableView(_:)), name: "refreshContactListTableView", object: nil)

        contactAuthorizationAlert()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(ContactListViewController.pullToRefresh),forControlEvents :
            UIControlEvents.ValueChanged)
        self.contactListTableView.addSubview(self.refreshControl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func addKeyboardObservers()
    {
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:#selector(EditProfileViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object:nil)]
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:#selector(EditProfileViewController.keyboardDidHide), name: UIKeyboardWillHideNotification, object:nil)]
    }
    
    func keyboardDidShow(notification:NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if tableViewBottomConstraint.constant == 0
        {
            self.tableViewBottomConstraint.constant = self.tableViewBottomConstraint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if tableViewBottomConstraint.constant != 0
        {
            self.tableViewBottomConstraint.constant = 0
        }
    }

    func pullToRefresh()
    {
        if(!pullToRefreshActive){
            pullToRefreshActive = true
            operationInSharingContactList.cancel()
            self.contactListSearchBar.text = ""
            self.contactListSearchBar.resignFirstResponder()
            searchActive = false
            self.getPullToRefreshData()
        }
        else
        {
        }
    }
    
    func getPullToRefreshData()
    {
        initialise()
    }
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        if(doneButton.hidden == false){
            doneButton.hidden = true
            if(searchActive){
                for i in 0 ..< searchDataSource.count
                {
                    if i < searchDataSource.count
                    {
                        let selectionValue : Int = searchDataSource[i]["orgSelected"] as! Int
                        searchDataSource[i]["tempSelected"] = selectionValue
                    }
                }
                for i in 0 ..< dataSource.count
                {
                    if i < dataSource.count
                    {
                        dataSource[i]["tempSelected"] = 0
                    }
                }
            }
            else{
                for i in 0 ..< dataSource.count
                {
                    if i < dataSource.count
                    {
                        let selectionValue : Int = dataSource[i]["orgSelected"] as! Int
                        dataSource[i]["tempSelected"] = selectionValue
                    }
                }
            }
            contactListTableView.reloadData()
        }
        else{
            self.navigationController?.popViewControllerAnimated(false)
        }
    }
    
    @IBAction func gestureTapped(sender: AnyObject) {
        view.endEditing(true)
        self.contactListSearchBar.text = ""
        self.contactListSearchBar.resignFirstResponder()
        searchActive = false
        self.contactListTableView.reloadData()
    }
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        doneButton.hidden = true
        contactListTableView.reloadData()
        contactListTableView.layoutIfNeeded()
        addUserArray.removeAllObjects()
        
        for i in 0 ..< dataSource.count
        {
            if i < dataSource.count
            {
                let userId = dataSource[i][userNameKey] as! String
                let selectionValue : Int = dataSource[i]["tempSelected"] as! Int
                if(selectionValue == 1){
                    addUserArray.addObject(userId)
                }
            }
        }
        
        if addUserArray.count > 0
        {
            inviteContactList(userId, accessToken: accessToken, channelid: channelId, addUser: addUserArray)
        }
    }
    
    func inviteContactList(userName: String, accessToken: String, channelid: String, addUser: NSMutableArray){
        showOverlay()
        channelManager.AddContactToChannel(userName, accessToken: accessToken, channelId: channelid, adduser: addUserArray, success: { (response) -> () in
            self.authenticationSuccessHandlerInvite(response)
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
    
    func initialise()
    {
        let addressBookRef1 = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        setAddressBook(addressBookRef1)
        
        searchDataSource.removeAll()
        dataSource.removeAll()
        addUserArray.removeAllObjects()
        searchActive = false
        doneButton.hidden = true
        contactPhoneNumbers.removeAll()
        NoDatalabelFormySharingImageList.removeFromSuperview()
        contactListTableView.reloadData()
        displayContacts()
    }
    
    func contactAuthorizationAlert()
    {
        let authorizationStatus = ABAddressBookGetAuthorizationStatus()
        switch authorizationStatus {
        case .Denied, .Restricted:
            generateContactSynchronizeAlert()
        case .Authorized:
            self.initialise()
        case .NotDetermined:
            promptForAddressBookRequestAccess()
        }
    }
    
    func generateContactSynchronizeAlert()
    {
        let alert = UIAlertController(title: "\"Catch\" would like to access your contacts", message: "The contacts in your address book will be transmitted to Catch for you to decide who to add", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Don't Allow", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.showEventsAcessDeniedAlert()
        }))
        self.presentViewController(alert, animated: false, completion: nil)
    }
    
    func promptForAddressBookRequestAccess() {
        ABAddressBookRequestAccessWithCompletion(addressBookRef) {
            (granted: Bool, error: CFError!) in
            dispatch_async(dispatch_get_main_queue()) {
                if !granted {
                    self.generateContactSynchronizeAlert()
                } else {
                    self.initialise()
                }
            }
        }
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
        presentViewController(alertController, animated: false, completion: nil)
    }
    
    func displayContacts(){
        if(!pullToRefreshActive){
            showOverlay()
        }
        contactPhoneNumbers.removeAll()
        let defaults = NSUserDefaults .standardUserDefaults()
        let phoneCode = defaults.valueForKey("countryCode") as! String
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
        }
        if contactPhoneNumbers.count > 0
        {
            addContactDetails(self.contactPhoneNumbers)
        }
        else{
            if(!pullToRefreshActive){
                self.removeOverlay()
            }
            else{
                self.refreshControl.endRefreshing()
                self.pullToRefreshActive = false
            }
            addNoDataLabel()
        }
    }
    
    func addNoDataLabel()
    {
        self.NoDatalabelFormySharingImageList = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
        self.NoDatalabelFormySharingImageList.textAlignment = NSTextAlignment.Center
        self.NoDatalabelFormySharingImageList.text = "No Contacts Available"
        self.view.addSubview(self.NoDatalabelFormySharingImageList)
    }
    
    func addContactDetails(contactPhoneNumbers: NSArray)
    {
        contactManagers.addContactDetails(userId, accessToken: accessToken, userContacts: contactPhoneNumbers, success:  { (response) -> () in
            self.authenticationSuccessHandlerAdd(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandlerAdd(error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerAdd(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            var status: Int!
            status = json["status"] as! Int
            if(status >= 1)
            {
                getChannelContactDetails(userId, token: accessToken, channelid: channelId)
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func authenticationFailureHandlerAdd(error: NSError?, code: String)
    {
        if(!pullToRefreshActive){
            self.removeOverlay()
        }
        else{
            self.refreshControl.endRefreshing()
            self.pullToRefreshActive = false
        }
        addNoDataLabel()
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if code == "CONTACT002" {
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
                if code == "CONTACT001"{
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
    
    func authenticationSuccessHandlerInvite(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                for i in 0 ..< dataSource.count
                {
                    if i < dataSource.count
                    {
                        let selectionValue : Int = dataSource[i]["tempSelected"] as! Int
                        dataSource[i]["orgSelected"] = selectionValue
                    }
                }
                loadMychannelDetailController()
            }
        }
    }
    
    func loadMychannelDetailController(){
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let channelDetailVC:UITabBarController = sharingStoryboard.instantiateViewControllerWithIdentifier(MyChannelDetailViewController.identifier) as! UITabBarController
        (channelDetailVC as! MyChannelDetailViewController).channelId = channelId as String
        (channelDetailVC as! MyChannelDetailViewController).channelName = channelName as String
        (channelDetailVC as! MyChannelDetailViewController).totalMediaCount = Int(totalMediaCount)
        channelDetailVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelDetailVC, animated: false)
    }
    
    func getChannelContactDetails(username: String, token: String, channelid: String)
    {
        channelManager.getChannelNonContactDetails(channelid, userName: username, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
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
        if(!pullToRefreshActive){
            self.removeOverlay()
        }
        else{
            self.refreshControl.endRefreshing()
            self.pullToRefreshActive = false
        }
        
        if let json = response as? [String: AnyObject]
        {
            dataSource.removeAll()
            let responseArr = json["contactList"] as! [AnyObject]
            for element in responseArr{
                let userName = element["user_name"] as! String
                let thumbUrl = UrlManager.sharedInstance.getUserProfileImageBaseURL() + userId + "/" + accessToken + "/" + userName
                let profileImage = UIImage(named: "dummyUser")
                dataSource.append([userNameKey:userName, profileImageUrlKey: thumbUrl,"tempSelected": 0, "orgSelected" : 0, profileImageKey : profileImage!])
            }
            
            self.contactListTableView.reloadData()
            
            if(dataSource.count > 0){
                operationInSharingContactList  = NSBlockOperation (block: {
                    self.downloadMediaFromGCS(self.operationInSharingContactList)
                })
                self.operationQueueObjInSharingContactList.addOperation(operationInSharingContactList)
//                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
//                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
//                dispatch_async(backgroundQueue, {
//                    self.downloadMediaFromGCS()
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    })
//                })
            }
            else{
                addNoDataLabel()
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
//    func createProfileImage(profileName: String) -> UIImage
//    {
//        var profileImage : UIImage = UIImage()
//        let url: NSURL = convertStringtoURL(profileName)
//        if let data = NSData(contentsOfURL: url){
//            let imageDetailsData = (data as NSData?)!
//            profileImage = UIImage(data: imageDetailsData)!
//        }
//        else{
//            profileImage = UIImage(named: "dummyUser")!
//        }
//        return profileImage
//    }
    
    func downloadMediaFromGCS(operationObj: NSBlockOperation){
        var localArray = [[String:AnyObject]]()
        for i in 0 ..< dataSource.count
        {
            localArray.append(dataSource[i])
        }
        for i in 0 ..< localArray.count
        {
            if(i < localArray.count){
                if operationObj.cancelled == true{
                    return
                }
                var profileImage : UIImage?
                let profileImageName = localArray[i][profileImageUrlKey] as! String
                if(profileImageName != "")
                {
//                    profileImage = createProfileImage(profileImageName)
                      profileImage = FileManagerViewController.sharedInstance.getProfileImage(profileImageName)
                }
                else{
                    profileImage = UIImage(named: "dummyUser")
                }
                localArray[i][profileImageKey] = profileImage
            }
        }
        for j in 0 ..< dataSource.count
        {
            if operationObj.cancelled == true{
                return
            }
            if j < dataSource.count
            {
                let userChk = dataSource[j][userNameKey] as! String
                for element in localArray
                {
                    let userLocalChk = element[userNameKey] as! String
                    if userChk == userLocalChk
                    {
                        if element[profileImageKey] != nil
                        {
                            dataSource[j][profileImageKey] = element[profileImageKey] as! UIImage
                        }
                    }
                }
            }
        }
        localArray.removeAll()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.contactListTableView.reloadData()
        })
    }
    
//    func downloadMediaFromGCS(){
//        for i in 0 ..< dataSource.count
//        {
//            if i < dataSource.count
//            {
//                var profileImage : UIImage?
//                let profileImageName = dataSource[i][profileImageUrlKey] as! String
//                if(profileImageName != "")
//                {
//                    profileImage = createProfileImage(profileImageName)
//                }
//                else{
//                    profileImage = UIImage(named: "dummyUser")
//                }
//                dataSource[i][profileImageKey] = profileImage
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    self.removeOverlay()
//                    self.contactListTableView.reloadData()
//                })
//            }
//        }
//    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        if(!pullToRefreshActive){
            self.removeOverlay()
        }
        else{
            self.refreshControl.endRefreshing()
            self.pullToRefreshActive = false
        }
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else
            {
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
        if(dataSource.count > 0){
        for i in 0 ..< dataSource.count
        {
            if i < dataSource.count
            {
                let selectionValue : Int = dataSource[i]["orgSelected"] as! Int
                dataSource[i]["tempSelected"] = selectionValue
            }
        }
        }
        else{
            addNoDataLabel()
        }
        contactListTableView.reloadData()
    }
    
    func callRefreshContactListTableView(notif:NSNotification){
        if(doneButton.hidden == true){
            doneButton.hidden = false
        }
        let indexpath = notif.object as! Int
        if(searchActive)
        {
            if(indexpath < searchDataSource.count){
                let selectedValue =  searchDataSource[indexpath]["tempSelected"] as! Int
                if(selectedValue == 1)
                {
                    searchDataSource[indexpath]["tempSelected"] = 0
                }
                else
                {
                    searchDataSource[indexpath]["tempSelected"] = 1
                }
                
                let selecteduserId =  searchDataSource[indexpath][userNameKey] as! String
                for i in 0 ..< dataSource.count
                {
                    if i < dataSource.count
                    {
                        let dataSourceUserId = dataSource[i][userNameKey] as! String
                        if(selecteduserId == dataSourceUserId)
                        {
                            dataSource[i]["tempSelected"] = searchDataSource[indexpath]["tempSelected"]
                        }
                    }
                }
            }
        }
        else
        {
            if(indexpath < dataSource.count){
                let selectedValue =  dataSource[indexpath]["tempSelected"] as! Int
                if(selectedValue == 1){
                    dataSource[indexpath]["tempSelected"] = 0
                }
                else{
                    dataSource[indexpath]["tempSelected"] = 1
                }
            }
        }
        
        contactListTableView.reloadData()
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

extension ContactListViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 45.0
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 60
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("ContactListHeaderTableViewCell") as! ContactListHeaderTableViewCell
        
        headerCell.contactListHeaderLabel.text = "USING CA7CH"
        return headerCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if(searchActive){
            return searchDataSource.count > 0 ? (searchDataSource.count) : 0
        }
        else{
            return dataSource.count > 0 ? (dataSource.count) : 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var dataSourceTmp : [[String:AnyObject]]?
        
        let cell = tableView.dequeueReusableCellWithIdentifier(ContactListTableViewCell.identifier, forIndexPath:indexPath) as! ContactListTableViewCell
        
        if(searchActive){
            dataSourceTmp = searchDataSource
        }
        else{
            dataSourceTmp = dataSource
        }
        
        if dataSourceTmp?.count > 0
        {
            cell.contactUserName.text = dataSourceTmp![indexPath.row][userNameKey] as? String
            let imageName =  dataSourceTmp![indexPath.row][profileImageKey]
            cell.contactProfileImage.image = imageName as? UIImage
            cell.subscriptionButton.tag = indexPath.row
            
            let selectionValue : Int = dataSourceTmp![indexPath.row]["tempSelected"] as! Int
            if(selectionValue == 1){
                cell.subscriptionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
            }
            else{
                cell.subscriptionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
            }
            
            cell.selectionStyle = .None
            return cell
        }
        else
        {
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
}

extension ContactListViewController: UISearchBarDelegate{
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if searchBar.text != ""
        {
            searchActive = true
        }
        else{
            searchActive = false
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchDataSource.removeAll()
        
        if contactListSearchBar.text!.isEmpty
        {
            searchDataSource = dataSource
            contactListSearchBar.resignFirstResponder()
            self.contactListTableView.reloadData()
        }
        else{
            if dataSource.count > 0
            {
                for element in dataSource{
                    let tmp: String = (element[userNameKey]?.lowercaseString)!
                    if(tmp.containsString(searchText.lowercaseString))
                    {
                        searchDataSource.append(element)
                    }
                }
                
                searchActive = true
                self.contactListTableView.reloadData()
            }
        }
    }
}

