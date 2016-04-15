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
    let subscribedKey = "sharedindicator"
    let selectionKey = "selected"
    
    var searchActive: Bool = false
    
    @IBOutlet var channelTitleLabel: UILabel!
    
    @IBOutlet var contactSearchBar: UISearchBar!
    
    @IBOutlet var contactTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        contactTableView.reloadData()
        contactTableView.layoutIfNeeded()
        print(selectedContacts)
        
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let sharingVC = sharingStoryboard.instantiateViewControllerWithIdentifier(MySharedChannelsViewController.identifier) as! MySharedChannelsViewController
        sharingVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(sharingVC, animated: true)
    }
    
    
    @IBAction func inviteContacts(sender: AnyObject) {
        
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let inviteContactsVC = sharingStoryboard.instantiateViewControllerWithIdentifier(ContactListViewController.identifier) as! ContactListViewController
        inviteContactsVC.channelId = channelId
        inviteContactsVC.channelName = channelName
        inviteContactsVC.totalMediaCount = totalMediaCount
        inviteContactsVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(inviteContactsVC, animated: true)
        
    }
    
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        
        contactTableView.reloadData()
        contactTableView.layoutIfNeeded()
        print(selectedContacts)
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
            var key : String = String()
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
                let subscriptionValue = element["sharedindicator"] as! String
                if(subscriptionValue == "true")
                {
//                    key = "1"
//                }
//                else{
//                    key = "0"
//                }
                dataSource.append([userNameKey:userName, profileImageKey: contactImage , subscribedKey: subscriptionValue])
                selectedContacts.append([userNameKey:userName, selectionKey:"1"])
                }
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
        }
        else{
            ErrorManager.sharedInstance.addContactError()
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
        return 0.01   // to avoid extra blank lines
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
            
            if(cell.deselectedArray.count > 0){
                
                for var i = 0; i < selectedContacts.count; i++
                {
                    let selectedValue: String = selectedContacts[i][userNameKey] as! String
                    if cell.deselectedArray.containsObject(selectedValue){
                        selectedContacts[i][selectionKey] = "0"
                    }
                }
            }
            
            if(cell.selectedArray.count > 0){
                
                for var i = 0; i < selectedContacts.count; i++
                {
                    let selectedValue: String = selectedContacts[i][userNameKey] as! String
                    if cell.selectedArray.containsObject(selectedValue){
                        selectedContacts[i][selectionKey] = "1"
                    }
                }
            }
            
            
            if selectedContacts.count > 0
            {
                for var i = 0; i < selectedContacts.count; i++
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


extension MyChannelSharingDetailsViewController: UISearchBarDelegate{
    func searchBarTextDidBeginEditing(searchBar: UISearchBar)
    {
        searchActive = true;
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
