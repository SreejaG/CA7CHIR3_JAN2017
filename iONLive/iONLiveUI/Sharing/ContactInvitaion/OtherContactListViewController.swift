
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
   
    var ca7chContactSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var phoneContactSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var searchCa7chContactSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var searchPhoneContactSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var contactPhoneNumbers: [String] = [String]()
    
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var contactListSearchBar: UISearchBar!
    @IBOutlet var ca7chTableView: UITableView!
    @IBOutlet var phoneTableView: UITableView!
    
    let userNameKey = "userName"
    let profileImageKey = "profileImage"
    let subscribedKey = "sharedindicator"
    let selectionKey = "selected"
    let profileImageUrlKey = "profile_image"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherContactListViewController.refreshCa7chContactsListTableView(_:)), name: "refreshCa7chContactsListTableView", object: nil)
        
         NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherContactListViewController.refreshphoneContactsListTableView(_:)), name: "refreshphoneContactsListTableView", object: nil)
        
        let addressBookRef1 = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        setAddressBook(addressBookRef1)
        contactAuthorizationAlert()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        ca7chContactSource.removeAll()
        contactPhoneNumbers.removeAll()
        phoneContactSource.removeAll()
        searchCa7chContactSource.removeAll()
        searchPhoneContactSource.removeAll()
        
        doneButton.hidden = true
        
        searchActive = false
        
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
                    self.phoneContactSource.append([self.userNameKey: currentContactName, self.profileImageKey: currentContactImage, "orgSelected":0, "tempSelected":0])
                }
            }
        }
        
        phoneTableView.reloadData()
        
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
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["contactList"] as! [AnyObject]
            
            for element in responseArr{
                let userName = element["user_name"] as! String
                let thumbUrl = UrlManager.sharedInstance.getUserProfileImageBaseURL() + userId + "/" + accessToken + "/" + userName
                ca7chContactSource.append([userNameKey:userName, profileImageUrlKey: thumbUrl,"tempSelected": 0, "orgSelected" : 0])
            }
            if(ca7chContactSource.count > 0){
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    self.downloadMediaFromGCS()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                    })
                })
            }
            else{
                removeOverlay()
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
        for i in 0 ..< ca7chContactSource.count
        {
            var profileImage : UIImage?
            let profileImageName = ca7chContactSource[i][profileImageUrlKey] as! String
            if(profileImageName != "")
            {
                profileImage = createProfileImage(profileImageName)
            }
            else{
                profileImage = UIImage(named: "dummyUser")
            }
            ca7chContactSource[i][profileImageKey] = profileImage
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                self.ca7chTableView.reloadData()
            })
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
            }
            else
            {
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
        ca7chTableView.reloadData()
    }
    
    func refreshCa7chContactsListTableView(notif:NSNotification){
        if(doneButton.hidden == true){
            doneButton.hidden = false
        }
        let indexpath = notif.object as! Int
//        if(searchActive)
//        {
//            if(indexpath < searchDataSource.count){
//                let selectedValue =  searchDataSource[indexpath]["tempSelected"] as! Int
//                if(selectedValue == 1)
//                {
//                    searchDataSource[indexpath]["tempSelected"] = 0
//                }
//                else
//                {
//                    searchDataSource[indexpath]["tempSelected"] = 1
//                }
//                
//                let selecteduserId =  searchDataSource[indexpath][userNameKey] as! String
//                for i in 0 ..< fullDataSource.count
//                {
//                    let dataSourceUserId = fullDataSource[i][userNameKey] as! String
//                    if(selecteduserId == dataSourceUserId)
//                    {
//                        fullDataSource[i]["tempSelected"] = searchDataSource[indexpath]["tempSelected"]
//                    }
//                }
//            }
//        }
//        else
//        {
            if(indexpath < ca7chContactSource.count){
                let selectedValue =  ca7chContactSource[indexpath]["tempSelected"] as! Int
                if(selectedValue == 1){
                    ca7chContactSource[indexpath]["tempSelected"] = 0
                }
                else{
                    ca7chContactSource[indexpath]["tempSelected"] = 1
                }
//            }
        }
        ca7chTableView.reloadData()
    }
    
    func refreshphoneContactsListTableView(notif:NSNotification){
        if(doneButton.hidden == true){
            doneButton.hidden = false
        }
        let indexpath = notif.object as! Int
        //        if(searchActive)
        //        {
        //            if(indexpath < searchDataSource.count){
        //                let selectedValue =  searchDataSource[indexpath]["tempSelected"] as! Int
        //                if(selectedValue == 1)
        //                {
        //                    searchDataSource[indexpath]["tempSelected"] = 0
        //                }
        //                else
        //                {
        //                    searchDataSource[indexpath]["tempSelected"] = 1
        //                }
        //
        //                let selecteduserId =  searchDataSource[indexpath][userNameKey] as! String
        //                for i in 0 ..< fullDataSource.count
        //                {
        //                    let dataSourceUserId = fullDataSource[i][userNameKey] as! String
        //                    if(selecteduserId == dataSourceUserId)
        //                    {
        //                        fullDataSource[i]["tempSelected"] = searchDataSource[indexpath]["tempSelected"]
        //                    }
        //                }
        //            }
        //        }
        //        else
        //        {
        if(indexpath < phoneContactSource.count){
            let selectedValue =  phoneContactSource[indexpath]["tempSelected"] as! Int
            if(selectedValue == 1){
                phoneContactSource[indexpath]["tempSelected"] = 0
            }
            else{
                phoneContactSource[indexpath]["tempSelected"] = 1
            }
            //            }
        }
        phoneTableView.reloadData()
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
        self.navigationController?.popViewControllerAnimated(false)
    }
    @IBAction func didTapDoneButton(sender: AnyObject) {
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
        if(tableView == ca7chTableView){
            let  headerCell = tableView.dequeueReusableCellWithIdentifier("Ca7chContactsHeaderTableViewCell") as! Ca7chContactsHeaderTableViewCell
            headerCell.headerLabel.text = "USING CA7CH"
            return headerCell
        }
        else{
            let  headerCell = tableView.dequeueReusableCellWithIdentifier("phoneContactsHeaderTableViewCell") as! phoneContactsHeaderTableViewCell
            headerCell.headerLabel.text = "MY CONTACTS"
            return headerCell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if(tableView == ca7chTableView){
            if(searchActive){
                return searchCa7chContactSource.count > 0 ? (searchCa7chContactSource.count) : 0
            }
            else{
                return ca7chContactSource.count > 0 ? (ca7chContactSource.count) : 0
            }
        }
        else{
            if(searchActive){
                return searchPhoneContactSource.count > 0 ? (searchPhoneContactSource.count) : 0
            }
            else{
                return phoneContactSource.count > 0 ? (phoneContactSource.count) : 0
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if(tableView == ca7chTableView){
            var dataSourceTmp1 : [[String:AnyObject]]?
            if(searchActive){
                dataSourceTmp1 = searchCa7chContactSource
            }
            else{
                dataSourceTmp1 = ca7chContactSource
            }

            let cell = tableView.dequeueReusableCellWithIdentifier(Ca7chContactsTableViewCell.identifier, forIndexPath:indexPath) as! Ca7chContactsTableViewCell
            
            if dataSourceTmp1!.count > 0
            {
                cell.contactUserName.text = dataSourceTmp1![indexPath.row][userNameKey] as? String
                let imageName =  dataSourceTmp1![indexPath.row][profileImageKey]
                cell.contactProfileImage.image = imageName as? UIImage
                cell.subscriptionButton.tag = indexPath.row
                
                let selectionValue : Int = dataSourceTmp1![indexPath.row]["tempSelected"] as! Int
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
        else{
            var dataSourceTmp2 : [[String:AnyObject]]?
            if(searchActive){
                dataSourceTmp2 = searchPhoneContactSource
            }
            else{
                dataSourceTmp2 = phoneContactSource
            }

            let cell = tableView.dequeueReusableCellWithIdentifier(phoneContactsTableViewCell.identifier, forIndexPath:indexPath) as! phoneContactsTableViewCell
            
            if dataSourceTmp2!.count > 0
            {
                cell.contactUserName.text = dataSourceTmp2![indexPath.row][userNameKey] as? String
                let imageName =  dataSourceTmp2![indexPath.row][profileImageKey]
                cell.contactProfileImage.image = imageName as? UIImage
                cell.subscriptionButton.tag = indexPath.row
                
                let selectionValue : Int = dataSourceTmp2![indexPath.row]["tempSelected"] as! Int
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
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
}

extension OtherContactListViewController: UISearchBarDelegate{
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
        searchPhoneContactSource.removeAll()
        searchCa7chContactSource.removeAll()
        
        if contactListSearchBar.text!.isEmpty
        {
            searchCa7chContactSource = ca7chContactSource
            searchPhoneContactSource = phoneContactSource
            
            contactListSearchBar.resignFirstResponder()
            self.ca7chTableView.reloadData()
            self.phoneTableView.reloadData()
        }
        else{
            if ca7chContactSource.count > 0
            {
                for element in ca7chContactSource{
                    let tmp: String = (element[userNameKey]?.lowercaseString)!
                    if(tmp.containsString(searchText.lowercaseString))
                    {
                        searchCa7chContactSource.append(element)
                    }
                }
            }
            if phoneContactSource.count > 0
            {
                for element in phoneContactSource{
                    let tmp: String = (element[userNameKey]?.lowercaseString)!
                    if(tmp.containsString(searchText.lowercaseString))
                    {
                        searchPhoneContactSource.append(element)
                    }
                }
            }
                searchActive = true
            print(searchCa7chContactSource)
            print(searchPhoneContactSource)
                self.ca7chTableView.reloadData()
                self.phoneTableView.reloadData()
        }
    }
}




