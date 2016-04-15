//
//  ContactListViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 13/04/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ContactListViewController: UIViewController{

    static let identifier = "ContactListViewController"
    
    var channelId:String!
    var totalMediaCount: Int = Int()
    var channelName:String!
    
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var searchDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    let userNameKey = "userName"
    let profileImageKey = "profile_image"
    let subscribedKey = "sharedindicator"
    let selectionKey = "selected"
    
    var searchActive: Bool = false
    
    var selectedContacts : [[String:AnyObject]] = [[String:AnyObject]]()
    var addUserArray : NSMutableArray = NSMutableArray()
    var deleteUserArray : NSMutableArray = NSMutableArray()
    
    @IBOutlet var contactListSearchBar: UISearchBar!
    @IBOutlet var contactListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
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
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        getChannelContactDetails(userId, token: accessToken, channelid: channelId)
        
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
                if(subscriptionValue == "false")
                {
                    dataSource.append([userNameKey:userName, profileImageKey: contactImage , subscribedKey: subscriptionValue])
                    selectedContacts.append([userNameKey:userName, selectionKey:"0"])
                }
            }
            print(dataSource)
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
        
        if(searchActive){
            dataSourceTmp = searchDataSource
        }
        else{
            dataSourceTmp = dataSource
        }
        
        print(dataSourceTmp)
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


extension ContactListViewController: UISearchBarDelegate{
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

