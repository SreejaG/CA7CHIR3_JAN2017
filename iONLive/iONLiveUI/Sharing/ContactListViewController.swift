//
//  ContactListViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 13/04/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import AddressBook
import AddressBookUI
import CoreLocation
import UIKit

class ContactListViewController: UIViewController,CLLocationManagerDelegate{
    
    private var addressBookRef: ABAddressBookRef?
    
    func setAddressBook(addressBook: ABAddressBookRef) {
        addressBookRef = addressBook
    }
    
    static let identifier = "ContactListViewController"
    
    let locationManager:CLLocationManager = CLLocationManager()
    
    var channelId:String!
    var totalMediaCount: Int = Int()
    var channelName:String!
    var phoneCodeFromLocat : String = String()
    
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
    
    @IBOutlet var refreshButton: UIButton!
    @IBOutlet var doneButton: UIButton!
    
    @IBAction func didTapRefreshButton(sender: AnyObject) {
        displayContacts()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
        setUpLocationManager()
    }
    
    func setUpLocationManager()
    {
        self.locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.startUpdatingLocation()
    }
    
    
    // authorization status
    func locationManager(manager: CLLocationManager,
                         didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        var shouldIAllow = false
        var locationStatus = ""
        switch status {
        case CLAuthorizationStatus.Restricted:
            locationStatus = "Restricted Access to location"
        case CLAuthorizationStatus.Denied:
            locationStatus = "User denied access to location"
        case CLAuthorizationStatus.NotDetermined:
            locationStatus = "Status not determined"
        default:
            locationStatus = "Allowed to location Access"
            shouldIAllow = true
        }
        NSNotificationCenter.defaultCenter().postNotificationName("LabelHasbeenUpdated", object: nil)
        if (shouldIAllow == true) {
            NSLog("Location to Allowed")
            // Start location services
            locationManager.startUpdatingLocation()
        } else {
            NSLog("Denied access: \(locationStatus)")
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last! as CLLocation
        
        print("didUpdateLocations:  \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, e) -> Void in
            if let _ = e {
                print("Error:  \(e!.localizedDescription)")
            } else {
                let placemark = placemarks!.last! as CLPlacemark
                
                let userInfo = [
                    "city":     placemark.locality,
                    "state":    placemark.administrativeArea,
                    "country":  placemark.country,
                    "code":placemark.ISOcountryCode
                ]
                
                let phoneNumberUtil = NBPhoneNumberUtil.sharedInstance()
                self.phoneCodeFromLocat = "+\(phoneNumberUtil.getCountryCodeForRegion(userInfo["code"]!))"
            }
        })
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        if tapFlag == false
        {
            tapFlag = true
            doneButton.hidden = true
            refreshButton.hidden = false
            selectedContacts.removeAll()
            contactListTableView.reloadData()
        }
        else{
            self.navigationController?.popViewControllerAnimated(true)
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
        print(selectedContacts)
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
        refreshButton.hidden = false
        contactPhoneNumbers.removeAll()
        
        let addressBookRef1 = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        setAddressBook(addressBookRef1)
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        getChannelContactDetails(userId, token: accessToken, channelid: channelId)
        
    }
    
    
    func displayContacts(){
        contactPhoneNumbers.removeAll()
        let phoneCode = phoneCodeFromLocat
//        let defaults = NSUserDefaults .standardUserDefaults()
//        let phoneCode = defaults.valueForKey("phoneCodes")
        print(phoneCode)
        let allContacts = ABAddressBookCopyArrayOfAllPeople(addressBookRef).takeRetainedValue() as Array
        for record in allContacts {
            let phones : ABMultiValueRef = ABRecordCopyValue(record,kABPersonPhoneProperty).takeUnretainedValue() as ABMultiValueRef
            var phoneNumber: String = String()
            var appendPlus : String = String()
            for(var numberIndex : CFIndex = 0; numberIndex < ABMultiValueGetCount(phones); numberIndex++)
            {
                let phoneUnmaganed = ABMultiValueCopyValueAtIndex(phones, numberIndex)
                let phoneNumberStr = phoneUnmaganed.takeUnretainedValue() as! String
                let phoneNumberWithCode: String!
                print(phoneNumberStr)
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
    }
    
    func addContactDetails(contactPhoneNumbers: NSArray)
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        print(contactPhoneNumbers)
        
        contactManagers.addContactDetails(userId, accessToken: accessToken, userContacts: contactPhoneNumbers, success:  { (response) -> () in
            self.authenticationSuccessHandlerAdd(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandlerAdd(error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerAdd(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            var status: Int!
            status = json["status"] as! Int
            if(status >= 1)
            {
                initialise()
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
                initialise()
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
                if code == "CONTACT001"{
                    initialise()
                }
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
        if tapFlag == false
        {
            tapFlag = true
            doneButton.hidden = true
            refreshButton.hidden = false
            selectedContacts.removeAll()
            contactListTableView.reloadData()
        }
    }
    
    
    func authenticationSuccessHandlerInvite(response:AnyObject?)
    {
        removeOverlay()
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
        self.navigationController?.pushViewController(channelDetailVC, animated: true)
    }
    
    func getChannelContactDetails(username: String, token: String, channelid: String)
    {
        showOverlay()
        channelManager.getChannelNonContactDetails(channelid, userName: username, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            return
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
                if let imageName =  element["profile_image"]
                {
                    if imageName is NSArray{
                        let imageByteArray: NSArray = imageName!["data"] as! NSArray
                        var bytes:[UInt8] = []
                        for serverByte in imageByteArray {
                            bytes.append(UInt8(serverByte as! UInt))
                        }
                        let imageData:NSData = NSData(bytes: bytes, length: bytes.count)
                        if let datas = imageData as NSData? {
                            contactImage = UIImage(data: datas)!
                        }
                    }
                    else{
                        contactImage = UIImage(named: "avatar")!
                    }
                }
                dataSource.append([userNameKey:userName, profileImageKey: contactImage])
                //      selectedContacts.append([userNameKey:userName, selectionKey:"0"])
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
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
        if tapFlag == false
        {
            tapFlag = true
            doneButton.hidden = true
            refreshButton.hidden = false
            selectedContacts.removeAll()
            contactListTableView.reloadData()
        }
    }
    
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = self.view.bounds
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
            refreshButton.hidden = false
            doneButton.hidden = true
        }
        else{
            refreshButton.hidden = true
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
        return 0.01   // to avoid extra blank lines
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

