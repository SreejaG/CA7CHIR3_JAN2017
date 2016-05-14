//
//  MyChannelSharingDetailsViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MyChannelSharingDetailsViewController: UIViewController {
    
    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var searchDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    var selectedContacts : [[String:AnyObject]] = [[String:AnyObject]]()
    var addUserArray : NSMutableArray = NSMutableArray()
    var deleteUserArray : NSMutableArray = NSMutableArray()
    
    let userNameKey = "userName"
    let profileImageKey = "profile_image"
    let selectionKey = "selected"
    
    var searchActive: Bool = false
    var tapFlag : Bool = true
    
    @IBOutlet var inviteButton: UIButton!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var channelTitleLabel: UILabel!
    @IBOutlet var contactSearchBar: UISearchBar!
    @IBOutlet var contactTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarItem.selectedImage = UIImage(named:"friend_avatar_blue")?.imageWithRenderingMode(.AlwaysOriginal)
        if let channelName = channelName
        {
            channelTitleLabel.text = channelName.uppercaseString
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        removeOverlay()
    }
    
    @IBAction func gestureTapped(sender: AnyObject) {
        view.endEditing(true)
        self.contactSearchBar.text = ""
        self.contactSearchBar.resignFirstResponder()
        searchActive = false
        self.contactTableView.reloadData()
    }
    
    @IBAction func backClicked(sender: AnyObject)
    {
        if tapFlag == false
        {
            tapFlag = true
            doneButton.hidden = true
            inviteButton.hidden = false
            selectedContacts.removeAll()
            contactTableView.reloadData()
            contactTableView.layoutIfNeeded()
        }
        else{
            let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
            let sharingVC = sharingStoryboard.instantiateViewControllerWithIdentifier(MySharedChannelsViewController.identifier) as! MySharedChannelsViewController
            sharingVC.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(sharingVC, animated: false)
        }
    }
    
    @IBAction func inviteContacts(sender: AnyObject) {
        
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let inviteContactsVC = sharingStoryboard.instantiateViewControllerWithIdentifier(ContactListViewController.identifier) as! ContactListViewController
        inviteContactsVC.channelId = channelId
        inviteContactsVC.channelName = channelName
        inviteContactsVC.totalMediaCount = totalMediaCount
        inviteContactsVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(inviteContactsVC, animated: false)
        
    }
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        
        contactTableView.reloadData()
        contactTableView.layoutIfNeeded()
        addUserArray.removeAllObjects()
        deleteUserArray.removeAllObjects()
        for element in selectedContacts
        {
            if element["selected"] as! String == "1"
            {
                addUserArray.addObject(element["userName"] as! String)
            }
            else{
                deleteUserArray.addObject(element["userName"] as! String)
            }
        }
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        if((addUserArray.count > 0) || (deleteUserArray.count > 0))
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
            let createGCSParentPath =  FileManagerViewController.sharedInstance.createParentDirectory()
            print(createGCSParentPath)
        }
        else{
            let createGCSParentPath =  FileManagerViewController.sharedInstance.createParentDirectory()
            print(createGCSParentPath)
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

    func authenticationSuccessHandlerInvite(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                initialise()
            }
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
        inviteButton.hidden = false
        channelId = (self.tabBarController as! MyChannelDetailViewController).channelId
        channelName = (self.tabBarController as! MyChannelDetailViewController).channelName
        totalMediaCount = (self.tabBarController as! MyChannelDetailViewController).totalMediaCount
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        getChannelContactDetails(userId, token: accessToken, channelid: channelId)
        
    }
    
    func getChannelContactDetails(username: String, token: String, channelid: String)
    {
        showOverlay()
        channelManager.getChannelContactDetails(channelid, userName: username, accessToken: token, success: { (response) -> () in
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
            var channelSelected : String = String()
            var contactImage : UIImage = UIImage()
            for element in responseArr{
                let userName = element["userName"] as! String
                if let imageName =  element["profile_image"]
                {
                    if let imageByteArray: NSArray = imageName!["data"] as? NSArray
                    {
                        var bytes:[UInt8] = []
                        for serverByte in imageByteArray {
                            bytes.append(UInt8(serverByte as! UInt))
                        }
                        
                        if let profileData:NSData = NSData(bytes: bytes, length: bytes.count){
                            let profileImageData = profileData as NSData?
                            contactImage = UIImage(data: profileImageData!)!
                        }
                    }
                    else{
                        contactImage = UIImage(named: "avatar")!
                    }
                }
                else{
                    contactImage = UIImage(named: "avatar")!
                }
                
                let subscriptionValue =  Int(element["sharedindicator"] as! Bool)
                if(subscriptionValue == 1)
                {
                    channelSelected = "1"
                }
                else{
                    channelSelected = "0"
                }
                dataSource.append([userNameKey:userName, profileImageKey: contactImage, selectionKey:subscriptionValue])
            }
            contactTableView.reloadData()
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
            inviteButton.hidden = false
            selectedContacts.removeAll()
            contactTableView.reloadData()
            contactTableView.layoutIfNeeded()
        }
    }
    
    func handleTap() {
        tapFlag = false
        if tapFlag == true
        {
            inviteButton.hidden = false
            doneButton.hidden = true
        }
        else{
            inviteButton.hidden = true
            doneButton.hidden = false
        }
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - (64 + 50))
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    func generateWaytoSendAlert(ContactId: String)
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        let alert = UIAlertController(title: "Delete!!!", message: "Do you want to delete the contact", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.deleteContactDetails(userId, token: accessToken, contactName: ContactId, channelid: self.channelId)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: false, completion: nil)
    }
    
    func  deleteContactDetails(userName: String, token:String, contactName:String, channelid:String){
        channelManager.deleteContactDetails(userName: userName, accessToken: token, channelId: channelid, contactName: contactName, success: { (response) in
            self.authenticationSuccessHandlerDeleteContact(response)
        }) { (error, message) in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerDeleteContact(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                initialise()
            }
            
        }
    }
    
}

extension MyChannelSharingDetailsViewController:UITableViewDelegate,UITableViewDataSource
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
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("contactHeaderTableViewCell") as! contactHeaderTableViewCell
        
        headerCell.contactHeaderTitle.text = "SHARING WITH"
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier(contactSharingDetailTableViewCell.identifier, forIndexPath:indexPath) as! contactSharingDetailTableViewCell
        
        if selectedContacts.count != dataSource.count
        {
            var channelSelected : String = String()
            for element in dataSource
            {
                let userName = element[userNameKey] as! String
                let subscriptionValue =  Int(element[selectionKey] as! Bool)
                if(subscriptionValue == 1)
                {
                    channelSelected = "1"
                }
                else{
                    channelSelected = "0"
                }
                selectedContacts.append([userNameKey:userName, selectionKey:channelSelected])
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
            if tapFlag == true
            {
                cell.subscriptionButton.addTarget(self, action: "handleTap", forControlEvents: UIControlEvents.TouchUpInside)
                cell.deselectedArray.removeAllObjects()
                cell.selectedArray.removeAllObjects()
            }
            else{
                tapFlag = false
            }
            
            cell.contactUserName.text = dataSourceTmp![indexPath.row][userNameKey] as? String
            let imageName =  dataSourceTmp![indexPath.row][profileImageKey]
            cell.contactProfileImage.image = imageName as? UIImage
            
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
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let deletedUserId = self.dataSource[indexPath.row][self.userNameKey]! as! String
            generateWaytoSendAlert(deletedUserId)
        }
    }
}

extension MyChannelSharingDetailsViewController: UISearchBarDelegate{
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
        if contactSearchBar.text == "" {
            contactSearchBar.resignFirstResponder()
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
        self.contactTableView.reloadData()
    }
}
