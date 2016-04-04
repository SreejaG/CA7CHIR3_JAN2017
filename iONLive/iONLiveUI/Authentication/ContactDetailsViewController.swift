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
    
    var loadingOverlay: UIView?
    
    @IBOutlet var contactSearchBar: UISearchBar!
    
    @IBOutlet var contactTableView: UITableView!
    
    @IBAction func gestureTapped(sender: AnyObject) {
        view.endEditing(true)
        self.contactSearchBar.text = ""
        self.contactSearchBar.resignFirstResponder()
        searchActive = false
        self.contactTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = true
        self.contactTableView.backgroundView = nil
        self.contactTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
        
    }
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        contactTableView.reloadData()
        var contactsArray : [String] = [String]()
        for(_,value) in checkedMobiles{
            contactsArray.append(value as! String)
        }
        print(contactsArray)
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        showOverlay()
        contactManagers.inviteContactDetails(userId, accessToken: accessToken, contacts: contactsArray, success: { (response) -> () in
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
                loadIphoneCameraController()
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func loadIphoneCameraController(){
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraVC, animated: false)
    }
    
    func initialise()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        if(contactExistChk == true){
            getContactDetails(userId, token: accessToken)
        }
        else{
            setContactDetails()
        }
        //        indexTitles = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];
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
    
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            appContactsArr.removeAll()
            let responseArr = json["contactListOfUser"] as! [AnyObject]
            for element in responseArr{
                appContactsArr.append(element as! [String : AnyObject])
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
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            if code == "CONTACT001"{
                setContactDetails()
            }
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
    
    func setContactDetails()
    {
        var index : Int = 0
        if appContactsArr.count > 0 {
            for element in appContactsArr{
                let appNumber = element["mobile_no"] as! String
                if let num : String = appNumber{
                    index = 0
                    for element in contactDataSource{
                        let contactNumber = element["mobile_no"] as! String
                        if contactNumber == num {
                            contactDataSource.removeAtIndex(index)
                        }
                        index++
                    }
                }
            }
        }
        
        dataSource = [appContactsArr,contactDataSource]
        contactTableView.reloadData()
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
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
        return 0.01   // to avoid extra blank lines
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
        
        
        if(cell.cellsDataSource != nil){
            
            if(cell.selectedCells.count > 0)
            {
                for element in cell.selectedCells{
                    if element[phoneKey] as? String == dataSource![indexPath.section][indexPath.row][phoneKey] as? String
                    {
                        if element[inviteKey] as! String == "1"
                        {
                            dataSource![indexPath.section][indexPath.row][inviteKey] = "1"
                            let section = String(indexPath.section).stringByAppendingString("_")
                            let keyVal = String(section).stringByAppendingString(String(indexPath.row))
                            checkedMobiles.setValue(element[phoneKey]!, forKey: String(keyVal))
                        }
                        else{
                            let section = String(indexPath.section).stringByAppendingString("_")
                            let keyVal = String(section).stringByAppendingString(String(indexPath.row))
                            dataSource![indexPath.section][indexPath.row][inviteKey] = "0"
                            checkedMobiles.removeObjectForKey(String(keyVal))
                        }
                    }
                }
            }
        }
        else{
            if  dataSource![indexPath.section][indexPath.row][inviteKey] as! String == "0"
            {
                let section = String(indexPath.section).stringByAppendingString("_")
                let keyVal = String(section).stringByAppendingString(String(indexPath.row))
                checkedMobiles.removeObjectForKey(String(keyVal))
                cell.contactSelectionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
            }
            else if  dataSource![indexPath.section][indexPath.row][inviteKey] as! String == "1"
            {
                let section = String(indexPath.section).stringByAppendingString("_")
                let keyVal = String(section).stringByAppendingString(String(indexPath.row))
                checkedMobiles.setValue(dataSource![indexPath.section][indexPath.row][phoneKey]!, forKey: String(keyVal))
                cell.contactSelectionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
            }
        }
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
            
            if let imageName =  cellDataSource[imageKey]
            {
                if(imageName is UIImage){
                    var testImage = UIImage?()
                    testImage = imageName as? UIImage
                    if(testImage == nil || testImage == UIImage()){
                        cell.contactProfileImage.image = UIImage(named: "avatar")
                        
                    }
                    else{
                        cell.contactProfileImage.image = testImage
                    }
                }
                else if imageName is NSArray{
                    let imageByteArray: NSArray = imageName["data"] as! NSArray
                    var bytes:[UInt8] = []
                    for serverByte in imageByteArray {
                        bytes.append(UInt8(serverByte as! UInt))
                    }
                    let imageData:NSData = NSData(bytes: bytes, length: bytes.count)
                    if let datas = imageData as NSData? {
                        cell.contactProfileImage.image = UIImage(data: datas)
                    }
                }
                else{
                    cell.contactProfileImage.image = UIImage(named: "avatar")
                }
            }
            cell.reloadInputViews()
            cell.cellsDataSource = dataSource![indexPath.section][indexPath.row]
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
        
    }
    
    //    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
    //        return indexTitles as? [String]
    //    }
    //
    //    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
    //        return indexTitles.indexOfObject(title)
    //    }
}


extension ContactDetailsViewController: UISearchBarDelegate{
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
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
        
        searchDataSource?.removeAll()
        var searchContactDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
        var searchAppContactsArr: [[String:AnyObject]] = [[String:AnyObject]]()
        searchContactDataSource.removeAll()
        searchAppContactsArr.removeAll()
        
        if dataSource![0].count > 0
        {
            for element in dataSource![0]{
                let tmp: String = (element["user_name"]?.lowercaseString)!
                if(tmp.hasPrefix(searchText.lowercaseString))
                {
                    searchAppContactsArr.append(element)
                }
            }
        }
        if dataSource![1].count > 0
        {
            for element in dataSource![1]{
                let tmp: String =  (element["user_name"]?.lowercaseString)!
                if(tmp.hasPrefix(searchText.lowercaseString))
                {
                    searchContactDataSource.append(element)
                }
            }
        }
        
        searchDataSource = [searchAppContactsArr, searchContactDataSource]
        
        if((searchAppContactsArr.count == 0) && (searchContactDataSource.count == 0)){
            searchActive = false;
        } else {
            searchActive = true;
        }
        
        self.contactTableView.reloadData()
    }
}
