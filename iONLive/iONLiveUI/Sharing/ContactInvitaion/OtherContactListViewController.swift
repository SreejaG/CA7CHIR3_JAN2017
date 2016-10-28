
import AddressBook
import AddressBookUI
import UIKit

class OtherContactListViewController: UIViewController {
    
    private var addressBookRef: ABAddressBookRef?
    
    func setAddressBook(addressBook: ABAddressBookRef) {
        addressBookRef = addressBook
    }
    
    static let identifier = "OtherContactListViewController"
    
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    let contactManagers = contactManager.sharedInstance
    
    let defaults = NSUserDefaults .standardUserDefaults()
    var userId = String()
    var accessToken = String()
    
    var channelId:String!
    var totalMediaCount: Int = Int()
    var channelName:String!
    
    var loadingOverlay: UIView?
    
    var searchActive: Bool = false
    var indicatorStopFlag : Bool = false
   
    var ca7chContactSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var phoneContactSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    var searchContactSource:[[[String:AnyObject]]] = [[[String:AnyObject]]]()
    
    var contactSource:[[[String:AnyObject]]] = [[[String:AnyObject]]]()
    
    var contactPhoneNumbers: [String] = [String]()
    
    var addUserArray : NSMutableArray = NSMutableArray()
    var inviteUserArray : NSMutableArray = NSMutableArray()
    
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var contactListSearchBar: UISearchBar!
    @IBOutlet var ca7chTableView: UITableView!
    @IBOutlet var ca7chTableBottomConstraint: NSLayoutConstraint!
    
    let userNameKey = "userName"
    let profileImageKey = "profileImage"
    let subscribedKey = "sharedindicator"
    let selectionKey = "selected"
    let profileImageUrlKey = "profile_image_URL"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherContactListViewController.refreshCa7chContactsListTableView(_:)), name: "refreshCa7chContactsListTableView", object: nil)
                
        let addressBookRef1 = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        setAddressBook(addressBookRef1)
        contactAuthorizationAlert()
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
        if ca7chTableBottomConstraint.constant == 0
        {
            self.ca7chTableBottomConstraint.constant = self.ca7chTableBottomConstraint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if ca7chTableBottomConstraint.constant != 0
        {
            self.ca7chTableBottomConstraint.constant = 0
        }
    }

    func initialise()
    {
        ca7chContactSource.removeAll()
        phoneContactSource.removeAll()

        contactPhoneNumbers.removeAll()
        
        contactSource.removeAll()
        searchContactSource.removeAll()
        
        doneButton.hidden = true
        
        searchActive = false
        
        addKeyboardObservers()
        
        userId = defaults.valueForKey(userLoginIdKey) as! String
        accessToken = defaults.valueForKey(userAccessTockenKey) as! String
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
    
    
    @IBAction func gestureTapped(sender: AnyObject) {
        view.endEditing(true)
        self.contactListSearchBar.text = ""
        self.contactListSearchBar.resignFirstResponder()
        searchActive = false
        self.ca7chTableView.reloadData()
        self.ca7chTableView.layoutIfNeeded()
    }
    
    func displayContacts(){
        showOverlay()
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
                
                var currentContactImage : UIImage = UIImage()
                
                if let currentContactImageData = ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail)?.takeRetainedValue() as CFDataRef!
                {
                    currentContactImage = UIImage(data: currentContactImageData)!
                }
                else{
                    currentContactImage = UIImage(named: "dummyUser")!
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
                    self.phoneContactSource.append([self.userNameKey: currentContactName, self.profileImageKey: currentContactImage, "orgSelected":0, "tempSelected":0])
                }
            }
        }
        
        if contactPhoneNumbers.count > 0
        {
            addContactDetails(self.contactPhoneNumbers)
        }
        else{
            removeOverlay()
        }
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
        self.removeOverlay()
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
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
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
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["contactList"] as! [AnyObject]
            
            for element in responseArr{
                let userName = element["user_name"] as! String
                let thumbUrl = UrlManager.sharedInstance.getUserProfileImageBaseURL() + userId + "/" + accessToken + "/" + userName
                let profileImage = UIImage(named: "dummyUser")

                ca7chContactSource.append([userNameKey:userName, profileImageUrlKey: thumbUrl,"tempSelected": 0, "orgSelected" : 0, profileImageKey : profileImage!])
            }
            
            self.setContactDetails()
            
            if(ca7chContactSource.count > 0){
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    self.downloadMediaFromGCS()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    })
                })
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func createProfileImage(profileName: String) -> UIImage
    {
        var profileImage : UIImage = UIImage()
        let url: NSURL = convertStringtoURL(profileName)
        if let data = NSData(contentsOfURL: url){
            let imageDetailsData = (data as NSData?)!
            profileImage = UIImage(data: imageDetailsData)!
        }
        else{
            profileImage = UIImage(named: "dummyUser")!
        }
        return profileImage
    }
    
    func downloadMediaFromGCS(){
        var localArray = [[String:AnyObject]]()
        for i in 0 ..< contactSource[0].count
        {
            localArray.append(contactSource[0][i])
        }
        for i in 0 ..< localArray.count
        {
            if(i < localArray.count){
                var profileImage : UIImage?
                let profileImageName = localArray[i][profileImageUrlKey] as! String
                if(profileImageName != "")
                {
                    profileImage = createProfileImage(profileImageName)
                }
                else{
                    profileImage = UIImage(named: "dummyUser")
                }
                localArray[i][profileImageKey] = profileImage
            }
        }
        for j in 0 ..< contactSource[0].count
        {
            if j < contactSource[0].count
            {
                let userChk = contactSource[0][j][userNameKey] as! String
                for element in localArray
                {
                    let userLocalChk = element[userNameKey] as! String
                    if userChk == userLocalChk
                    {
                        if element[profileImageKey] != nil
                        {
                            contactSource[0][j][profileImageKey] = element[profileImageKey] as! UIImage
                        }
                    }
                }
            }
        }
        localArray.removeAll()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.indicatorStopFlag = true
            self.ca7chTableView.reloadData()
        })
    }

//    func downloadMediaFromGCS(){
//        for i in 0 ..< ca7chContactSource.count
//        {
//            if i < ca7chContactSource.count
//            {
//                var profileImage : UIImage?
//                let profileImageName = ca7chContactSource[i][profileImageUrlKey] as! String
//                if(profileImageName != "")
//                {
//                    profileImage = createProfileImage(profileImageName)
//                }
//                else{
//                    profileImage = UIImage(named: "dummyUser")
//                }
//                contactSource[0][i][profileImageKey] = profileImage
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    self.ca7chTableView.reloadData()
//                })
//            }
//        }
//    }
    
    func setContactDetails()
    {
        contactSource = [ca7chContactSource,phoneContactSource]
        ca7chTableView.reloadData()
    }

    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        self.setContactDetails()

        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
            }
            else
            {
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func refreshCa7chContactsListTableView(notif:NSNotification){
        if(doneButton.hidden == true){
            doneButton.hidden = false
        }
        let dict = notif.object as! [String:Int]
        let section: Int = dict["sectionKey"]!
        let row : Int = dict["rowKey"]!
        if(searchActive)
        {
            if searchContactSource[section].count > row
            {
                let selectedValue =  searchContactSource[section][row]["tempSelected"] as! Int
                if(selectedValue == 1)
                {
                    searchContactSource[section][row]["tempSelected"] = 0
                }
                else
                {
                    searchContactSource[section][row]["tempSelected"] = 1
                }
                let selecteduserId =  searchContactSource[section][row][userNameKey] as! String
                for j in 0 ..< contactSource[section].count
                {
                    if j < contactSource[section].count
                    {
                        let dataSourceUserId = contactSource[section][j][userNameKey] as! String
                        if(selecteduserId == dataSourceUserId)
                        {
                            contactSource[section][j]["tempSelected"] = searchContactSource[section][row]["tempSelected"]
                        }
                    }
                }
            }
        }
        else
        {
            if contactSource[section].count > row
            {
                let selectedValue =  contactSource[section][row]["tempSelected"] as! Int
                if(selectedValue == 1){
                    contactSource[section][row]["tempSelected"] = 0
                }
                else{
                    contactSource[section][row]["tempSelected"] = 1
                }
            }
        }
        ca7chTableView.reloadData()
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
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        if(doneButton.hidden == false){
            doneButton.hidden = true
            for i in 0 ..< contactSource[0].count
            {
                if i < contactSource[0].count
                {
                    let selectionValue : Int = contactSource[0][i]["orgSelected"] as! Int
                    contactSource[0][i]["tempSelected"] = selectionValue
                }
            }
            for j in 0 ..< contactSource[1].count
            {
                if j < contactSource[1].count
                {
                    let selectionValue : Int = contactSource[1][j]["orgSelected"] as! Int
                    contactSource[1][j]["tempSelected"] = selectionValue
                }
            }
            ca7chTableView.reloadData()
        }
        else{
            self.navigationController?.popViewControllerAnimated(false)
        }
    }
    @IBAction func didTapDoneButton(sender: AnyObject) {
        doneButton.hidden = true
        ca7chTableView.reloadData()
        ca7chTableView.layoutIfNeeded()
       

        addUserArray.removeAllObjects()
        
        for i in 0 ..< contactSource[0].count
        {
            if i < contactSource[0].count
            {
                let userId = contactSource[0][i][userNameKey] as! String
                let selectionValue : Int = contactSource[0][i]["tempSelected"] as! Int
                if(selectionValue == 1){
                    addUserArray.addObject(userId)
                }
            }
        }
        
        for j in 0 ..< contactSource[1].count
        {
            if j < contactSource[1].count
            {
                let userId = contactSource[1][j][userNameKey] as! String
                let selectionValue : Int = contactSource[1][j]["tempSelected"] as! Int
                if(selectionValue == 1){
                    inviteUserArray.addObject(userId)
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
    
    func authenticationSuccessHandlerInvite(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                for i in 0 ..< contactSource[0].count
                {
                    if i < contactSource[0].count
                    {
                        let selectionValue : Int = contactSource[0][i]["tempSelected"] as! Int
                        contactSource[0][i]["orgSelected"] = selectionValue
                    }
                }
                for j in 0 ..< contactSource[1].count
                {
                    if j < contactSource[1].count
                    {
                        let selectionValue : Int = contactSource[1][j]["tempSelected"] as! Int
                        contactSource[1][j]["orgSelected"] = selectionValue
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
}

extension OtherContactListViewController:UITableViewDelegate,UITableViewDataSource
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
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("Ca7chContactsHeaderTableViewCell") as! Ca7chContactsHeaderTableViewCell
        
        switch (section) {
        case 0:
            headerCell.headerLabel.text = "USING CATCH"
        case 1:
            headerCell.headerLabel.text = "MY CONTACTS"
        default:
            headerCell.headerLabel.text = ""
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        
        switch section
        {
        case 0:
            if(searchActive){
                if(searchContactSource.count > 0){
                    return searchContactSource[0].count > 0 ? (searchContactSource[0].count) : 0
                }
                else{
                    return 0
                }
            }
            else{
                return contactSource[0].count > 0 ? (contactSource[0].count) : 0
            }
        case 1:
            if(searchActive){
                if(searchContactSource.count > 0){
                    return searchContactSource[1].count > 0 ? (searchContactSource[1].count) : 0
                }
                else{
                    return 0
                }
            }
            else{
                return contactSource[1].count > 0 ? (contactSource[1].count) : 0
            }
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(Ca7chContactsTableViewCell.identifier, forIndexPath:indexPath) as! Ca7chContactsTableViewCell
        
        var cellDataSource:[String:AnyObject]?
        var datasourceTmp: [[[String:AnyObject]]]?
        
        if(searchActive){
            datasourceTmp = searchContactSource
        }
        else{
            datasourceTmp = contactSource
        }
        
        if let dataSources = datasourceTmp
        {
            if dataSources.count > indexPath.section
            {
                if dataSources[indexPath.section].count > indexPath.row
                {
                    cellDataSource = dataSources[indexPath.section][indexPath.row]
                }
            }
        }
        
        if let cellDataSource = cellDataSource
        {
            cell.contactUserName.text = cellDataSource[userNameKey] as? String
            cell.contactProfileImage.image = cellDataSource[profileImageKey] as? UIImage
            cell.subscriptionButton.tag = indexPath.row
            cell.section = indexPath.section
            
            let selectionValue : Int = cellDataSource["tempSelected"] as! Int
            if(selectionValue == 1){
                cell.subscriptionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
            }
            else{
                cell.subscriptionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
            }
            cell.selectionStyle = .None
            if(indexPath.section == 0){
                if(indicatorStopFlag == false){
                    cell.profileDownloadIndicator.hidden = false
                    cell.contactProfileImage.alpha = 0.4
                    cell.profileDownloadIndicator.startAnimating()
                }
                else{
                    cell.profileDownloadIndicator.hidden = true
                    cell.contactProfileImage.alpha = 1.0
                    cell.profileDownloadIndicator.stopAnimating()
                }
            }
            else{
                cell.profileDownloadIndicator.hidden = true
                cell.contactProfileImage.alpha = 1.0
            }
            
            return cell
        }
        else
        {
            return UITableViewCell()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
         return contactSource.count > 0 ? (contactSource.count) : 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadData()
    }
}

extension OtherContactListViewController: UISearchBarDelegate{
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
            if searchBar.text != ""
            {
                searchActive = true
            }
            else{
                searchActive = false
            }
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
        ca7chTableView.reloadData()
        ca7chTableView.layoutIfNeeded()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchContactSource.removeAll()
        var searchCa7chContactDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
        var searchPhoneContactsDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
        searchCa7chContactDataSource.removeAll()
        searchPhoneContactsDataSource.removeAll()
        
        if contactListSearchBar.text!.isEmpty
        {
            searchContactSource = contactSource
            contactListSearchBar.resignFirstResponder()
            self.ca7chTableView.reloadData()
        }
        else{
            if contactSource[0].count > 0
            {
                for element in contactSource[0]{
                    var tmp: String = ""
                    tmp = (element[userNameKey]?.lowercaseString)!
                    if(tmp.containsString(searchText.lowercaseString))
                    {
                        searchCa7chContactDataSource.append(element)
                    }
                }
            }
            if contactSource[1].count > 0
            {
                for element in contactSource[1]{
                    var tmp: String =  ""
                    tmp = (element[userNameKey]?.lowercaseString)!
                    if(tmp.containsString(searchText.lowercaseString))
                    {
                        searchPhoneContactsDataSource.append(element)
                    }
                }
            }
            searchContactSource = [searchCa7chContactDataSource, searchPhoneContactsDataSource]
            searchActive = true
            self.ca7chTableView.reloadData()
        }
    }
}
