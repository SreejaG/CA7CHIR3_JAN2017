//
//  ContactDetailsViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 16/03/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ContactDetailsViewController: UIViewController {
    var contactDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var contactDummy:[[String:AnyObject]] = [[String:AnyObject]]()
    var appContactsArr: [[String:AnyObject]] = [[String:AnyObject]]()
    var dataSource:[[[String:AnyObject]]]?
    var indexTitles : NSArray = NSArray()
    
    var searchDataSource : [[[String:AnyObject]]]?
    var checkedMobiles : NSMutableDictionary = NSMutableDictionary()
    
    var searchActive: Bool = false
    var contactExistChk :Bool!
    
    let nameKey = "user_name"
    let phoneKey = "mobile_no"
    let imageKey = "profile_image"
    let selectionKey = "selection"
    let inviteKey = "invitationKey"
    
    static let identifier = "ContactDetailsViewController"
    
    let requestManager = RequestManager.sharedInstance
    let contactManagers = contactManager.sharedInstance
    
    @IBOutlet weak var doneButton: UIButton!
    var loadingOverlay: UIView?
    
    @IBOutlet var contactSearchBar: UISearchBar!
    
    @IBOutlet var contactTableView: UITableView!
    
    @IBAction func gestureTapped(sender: AnyObject) {
        view.endEditing(true)
        self.contactSearchBar.text = ""
        self.contactSearchBar.resignFirstResponder()
        searchActive = false
        self.contactTableView.reloadData()
        self.contactTableView.layoutIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
     //   doneButton.hidden = true
         NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactDetailsViewController.callSignUpRefreshContactListTableView(_:)), name: "refreshSignUpContactListTableView", object: nil)
        initialise()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = true
        self.contactTableView.backgroundView = nil
        self.contactTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
    }
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        doneButton.hidden = true
        contactTableView.reloadData()
        contactTableView.layoutIfNeeded()
        let contactsArray : NSMutableArray = NSMutableArray()
        contactsArray.removeAllObjects()
        
        for var i = 0; i < dataSource?.count; i++
        {
            for element in dataSource![i]{
                let selected = element["tempSelected"] as! Int
                if(selected == 1){
                    print(element[nameKey] as! String)
                    let number = element[phoneKey] as! String
                    contactsArray.addObject(number)
                }
            }
        }
        if(contactsArray.count > 0){
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            showOverlay()
            contactManagers.inviteContactDetails(userId, accessToken: accessToken, contacts: contactsArray, success: { (response) -> () in
                    self.authenticationSuccessHandlerInvite(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandlerInvite(error, code: message)
                return
            }
        }
        else{
            loadIphoneCameraController()
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
            self.presentViewController(channelItemListVC, animated: false) { () -> Void in
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        })
    }
    
    func authenticationSuccessHandlerInvite(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                loadIphoneCameraController()
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
            for var i = 0; i < dataSource!.count; i++
            {
                for var j = 0; j < dataSource![i].count; j++
                {
                    let selected = dataSource![i][j]["orgSelected"] as! Int
                    dataSource![i][j]["tempSelected"] = selected
                }
            }
            contactTableView.reloadData()
        }
    }
    
    func authenticationFailureHandlerInvite(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
           
            if code == "CONTACT001"{
              //   ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
                loadIphoneCameraController()
            }
            else  if code == "CONTACT002"{
            //     ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
                loadIphoneCameraController()
            }
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
        for var i = 0; i < dataSource!.count; i++
        {
            for var j = 0; j < dataSource![i].count; j++
            {
                let selected = dataSource![i][j]["orgSelected"] as! Int
                dataSource![i][j]["tempSelected"] = selected
            }
        }
        contactTableView.reloadData()
    }
    
    func loadIphoneCameraController(){
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraVC, animated: false)
    }
    
    func initialise()
    {
        dataSource?.removeAll()
        appContactsArr.removeAll()
        searchDataSource?.removeAll()
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        if(contactExistChk == true){
            getContactDetails(userId, token: accessToken)
        }
        else{
            setContactDetails()
        }
        contactTableView.tableFooterView = UIView()
    }
    
    func getContactDetails(userName: String, token: String)
    {
        showOverlay()
        contactManagers.getContactDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            return
        }
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
            appContactsArr.removeAll()
            let responseArr = json["contactListOfUser"] as! [AnyObject]
            var contactImage : UIImage = UIImage()
            for element in responseArr{
                
                let userName = element[nameKey] as! String
                let selection = "0"
                let mobNum = element[phoneKey] as! String
                
                //signed url iprofile
               
                let thumbUrlBeforeNullChk =  element["profile_image_thumbnail"]
                let thumbUrl =  nullToNil(thumbUrlBeforeNullChk) as! String
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

                appContactsArr.append([nameKey:userName, phoneKey:mobNum,imageKey:contactImage, "orgSelected":0, "tempSelected":0])
               
            }
            setContactDetails()
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
          
            if code == "CONTACT001"{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
                setContactDetails()
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
     //   self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func setContactDetails()
    {
        
        contactDummy.removeAll()
        var Cflag : Bool = false
        for i in 0 ..< contactDataSource.count
        {
            Cflag = false
            let contactNumber = contactDataSource[i]["mobile_no"] as! String
            for j in 0 ..< appContactsArr.count
            {
                let appNumber = appContactsArr[j]["mobile_no"] as! String
                if(contactNumber == appNumber) {
                    Cflag = true
                    break
                }
                else{
                    Cflag = false
                }
            }
            if(Cflag == false){
                contactDummy.append(contactDataSource[i])
            }
        }
        
        contactDataSource.removeAll()
        contactDataSource = contactDummy
        contactDummy.removeAll()
       
        dataSource = [appContactsArr,contactDataSource]
        
        contactTableView.reloadData()
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func callSignUpRefreshContactListTableView(notif:NSNotification){
        if(doneButton.hidden == true){
            doneButton.hidden = false
        }
        let dict = notif.object as! [String:Int]
        let section: Int = dict["sectionKey"]!
        let row : Int = dict["rowKey"]!
        if(searchActive)
        {
            let selectedValue =  searchDataSource![section][row]["tempSelected"] as! Int
            if(selectedValue == 1)
            {
                searchDataSource![section][row]["tempSelected"] = 0
            }
            else
            {
                searchDataSource![section][row]["tempSelected"] = 1
            }
            
            let selecteduserId =  searchDataSource![section][row][nameKey] as! String
            for var j = 0; j < dataSource![section].count; j++
            {
                let dataSourceUserId = dataSource![section][j][nameKey] as! String
                if(selecteduserId == dataSourceUserId)
                {
                    dataSource![section][j]["tempSelected"] = searchDataSource![section][row]["tempSelected"]
                }
            }
        }
        else
        {
            let selectedValue =  dataSource![section][row]["tempSelected"] as! Int
            if(selectedValue == 1){
                dataSource![section][row]["tempSelected"] = 0
            }
            else{
                dataSource![section][row]["tempSelected"] = 1
            }
        }
        
        contactTableView.reloadData()
    }
    
}

extension ContactDetailsViewController:UITableViewDelegate,UITableViewDataSource
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
        
        switch (section) {
        case 0:
            headerCell.contactHeaderTitle.text = "USING CATCH"
        case 1:
            headerCell.contactHeaderTitle.text = "MY CONTACTS"
        default:
            headerCell.contactHeaderTitle.text = ""
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        
        switch section
        {
        case 0:
            if(searchActive){
                return searchDataSource != nil ? (searchDataSource?[0].count)! :0
            }
            else{
                return dataSource != nil ? (dataSource?[0].count)! :0
            }
        case 1:
            if(searchActive){
                return searchDataSource != nil ? (searchDataSource?[1].count)! :0
            }
            else{
                return dataSource != nil ? (dataSource?[1].count)! :0
            }
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("contactTableViewCell", forIndexPath:indexPath) as! contactTableViewCell
        
        var cellDataSource:[String:AnyObject]?
        var datasourceTmp: [[[String:AnyObject]]]?
        
        if(searchActive){
            datasourceTmp = searchDataSource
        }
        else{
            datasourceTmp = dataSource
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
            cell.contactProfileName.text = cellDataSource[nameKey] as? String
            cell.contactProfileImage.image = cellDataSource[imageKey] as? UIImage
            cell.contactSelectionButton.tag = indexPath.row
            cell.section = indexPath.section
            
            let selectionValue : Int = cellDataSource["tempSelected"] as! Int
            if(selectionValue == 1){
                cell.contactSelectionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
            }
            else{
                cell.contactSelectionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
            }

            cell.selectionStyle = .None
            return cell
        }
        else
        {
            return UITableViewCell()
        }
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if let dataSource = dataSource
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadData()
        
    }
}

extension ContactDetailsViewController: UISearchBarDelegate{
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
        contactTableView.reloadData()
        contactTableView.layoutIfNeeded()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchDataSource?.removeAll()
        var searchContactDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
        var searchAppContactsArr: [[String:AnyObject]] = [[String:AnyObject]]()
        searchContactDataSource.removeAll()
        searchAppContactsArr.removeAll()
        
        if contactSearchBar.text!.isEmpty
        {
            searchDataSource = dataSource
            contactSearchBar.resignFirstResponder()
            self.contactTableView.reloadData()
        }
        else{
            if dataSource![0].count > 0
            {
                for element in dataSource![0]{
                    var tmp: String = ""
                    tmp = (element["user_name"]?.lowercaseString)!
                    if(tmp.containsString(searchText.lowercaseString))
                    {
                        searchAppContactsArr.append(element)
                    }
                }
            }
            if dataSource![1].count > 0
            {
                for element in dataSource![1]{
                    var tmp: String =  ""
                    tmp = (element["user_name"]?.lowercaseString)!
                    if(tmp.containsString(searchText.lowercaseString))
                    {
                        searchContactDataSource.append(element)
                    }
                }
            }
            searchDataSource = [searchAppContactsArr, searchContactDataSource]
            searchActive = true
            self.contactTableView.reloadData()
        }
    }
}
