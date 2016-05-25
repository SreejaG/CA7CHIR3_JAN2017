//
//  ContactListViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 13/04/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

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
    
    let userNameKey = "userName"
    let profileImageKey = "profile_image"
    let subscribedKey = "sharedindicator"
    let selectionKey = "selected"
    
    var searchActive: Bool = false
    var tapFlag : Bool = true
    
    var selectedContacts : [[String:AnyObject]] = [[String:AnyObject]]()
    var addUserArray : NSMutableArray = NSMutableArray()
    var deleteUserArray : NSMutableArray = NSMutableArray()
    
    @IBOutlet var contactListSearchBar: UISearchBar!
    @IBOutlet var contactListTableView: UITableView!
    @IBOutlet var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let addressBookRef1 = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        setAddressBook(addressBookRef1)
        contactAuthorizationAlert()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        removeOverlay()
    }
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        if tapFlag == false
        {
            tapFlag = true
            doneButton.hidden = true
            selectedContacts.removeAll()
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
        contactListTableView.reloadData()
        contactListTableView.layoutIfNeeded()
        addUserArray.removeAllObjects()
        deleteUserArray.removeAllObjects()
        for element in selectedContacts
        {
            if element["selected"] as! String == "1"
            {
                addUserArray.addObject(element["userName"] as! String)
            }
        }
        deleteUserArray = []
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        if addUserArray.count > 0
        {
            inviteContactList(userId, accessToken: accessToken, channelid: channelId, addUser: addUserArray, deleteUser: deleteUserArray)
        }
    }
    
    func inviteContactList(userName: String, accessToken: String, channelid: String, addUser: NSMutableArray, deleteUser:NSMutableArray){
        showOverlay()
        channelManager.inviteContactList(userName, accessToken: accessToken, channelId: channelid, adduser: addUser, deleteUser: deleteUser, success: { (response) -> () in
            self.authenticationSuccessHandlerInvite(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func  loadInitialViewController(){
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
        
        if(NSFileManager.defaultManager().fileExistsAtPath(documentsPath))
        {
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.removeItemAtPath(documentsPath)
            }
            catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
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
        self.navigationController?.presentViewController(channelItemListVC, animated: true, completion: nil)
    }
    
    
    func initialise()
    {
        searchDataSource.removeAll()
        dataSource.removeAll()
        addUserArray.removeAllObjects()
        deleteUserArray.removeAllObjects()
        selectedContacts.removeAll()
        searchActive = false
        tapFlag = true
        doneButton.hidden = true
        contactPhoneNumbers.removeAll()
        displayContacts()
    }
    
    func contactAuthorizationAlert()
    {
        let authorizationStatus = ABAddressBookGetAuthorizationStatus()
        switch authorizationStatus {
        case .Denied, .Restricted:
            print("Denied")
            generateContactSynchronizeAlert()
        case .Authorized:
            print("Authorized")
            self.initialise()
        case .NotDetermined:
            print("Not Determined")
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
                    print("Just denied")
                    self.generateContactSynchronizeAlert()
                } else {
                    print("Just authorized")
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
                    appendPlus = ""
                }
                
                let phoneNumberStringArray = phoneNumberWithCode.componentsSeparatedByCharactersInSet(
                    NSCharacterSet.decimalDigitCharacterSet().invertedSet)
                phoneNumber = appendPlus.stringByAppendingString(NSArray(array: phoneNumberStringArray).componentsJoinedByString("")) as String
                contactPhoneNumbers.append(phoneNumber)
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
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
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
                let defaults = NSUserDefaults .standardUserDefaults()
                let userId = defaults.valueForKey(userLoginIdKey) as! String
                let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
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
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
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
                loadInitialViewController()
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
        if tapFlag == false
        {
            tapFlag = true
            doneButton.hidden = true
            selectedContacts.removeAll()
            contactListTableView.reloadData()
        }
    }
    
    
    func authenticationSuccessHandlerInvite(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
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
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            dataSource.removeAll()
            let responseArr = json["contactList"] as! [AnyObject]
            var contactImage : UIImage = UIImage()
            for element in responseArr{
                let userName = element["userName"] as! String
                let thumbUrlBeforeNullChk =  element["profile_image_thumbnail"]
                let thumbUrl = nullToNil(thumbUrlBeforeNullChk) as! String
                if(thumbUrl != "")
                {
                    let url: NSURL = convertStringtoURL(thumbUrl)
                    if let data = NSData(contentsOfURL: url){
                        let imageDetailsData = (data as NSData?)!
                        contactImage = UIImage(data: imageDetailsData)!
                    }
                    else{
                        contactImage = UIImage(named: "dummyUser")!
                    }
                }
                else{
                    contactImage = UIImage(named: "dummyUser")!
                }
                dataSource.append([userNameKey:userName, profileImageKey: contactImage])
            }
            contactListTableView.reloadData()
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
        if tapFlag == false
        {
            tapFlag = true
            doneButton.hidden = true
            selectedContacts.removeAll()
            contactListTableView.reloadData()
        }
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func handleTap() {
        tapFlag = false
        if tapFlag == true
        {
            doneButton.hidden = true
        }
        else{
            doneButton.hidden = false
        }
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
        
        if selectedContacts.count != dataSource.count{
            for element in dataSource
            {
                let userName = element["userName"] as! String
                selectedContacts.append([userNameKey:userName, selectionKey:"0"])
            }
        }
        
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
            
            if tapFlag == true
            {
                cell.subscriptionButton.addTarget(self, action: "handleTap", forControlEvents: UIControlEvents.TouchUpInside)
                cell.deselectedArray.removeAllObjects()
                cell.selectedArray.removeAllObjects()
            }
            else{
                tapFlag = false
            }
            
            if(cell.deselectedArray.count > 0){
                
                for i in 0 ..< selectedContacts.count
                {
                    let selectedValue: String = selectedContacts[i][userNameKey] as! String
                    if cell.deselectedArray.containsObject(selectedValue){
                        selectedContacts[i][selectionKey] = "0"
                    }
                }
            }
            
            if(cell.selectedArray.count > 0){
                
                for i in 0 ..< selectedContacts.count
                {
                    let selectedValue: String = selectedContacts[i][userNameKey] as! String
                    if cell.selectedArray.containsObject(selectedValue){
                        selectedContacts[i][selectionKey] = "1"
                    }
                }
            }
            
            if selectedContacts.count > 0
            {
                for i in 0 ..< selectedContacts.count
                {
                    if selectedContacts[i][userNameKey] as! String == dataSourceTmp![indexPath.row][userNameKey] as! String{
                        if selectedContacts[i][selectionKey] as! String == "0"
                        {
                            cell.subscriptionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
                        }
                        else{
                            cell.subscriptionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
                        }
                    }
                }
            }
            cell.cellDataSource = dataSourceTmp![indexPath.row]
            
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
        if contactListSearchBar.text == "" {
            contactListSearchBar.resignFirstResponder()
        }
        if dataSource.count > 0
        {
            for element in dataSource{
                let tmp: String = (element[userNameKey]?.lowercaseString)!
                if(tmp.hasPrefix(searchText.lowercaseString))
                {
                    searchDataSource.append(element)
                    
                }
            }
        }
        
        if(searchDataSource.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.contactListTableView.reloadData()
    }
}

