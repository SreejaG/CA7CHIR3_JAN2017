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
    
    var searchDataSource : [[[String:AnyObject]]]?
    
    var searchActive: Bool = false
    var contactExistChk :Bool!
    
    let nameKey = "user_name"
    let phoneKey = "mobile_no"
    let imageKey = "profile_image"
    
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
        self.contactTableView.backgroundView = nil
        self.contactTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
        
    }
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        print("hiiiii")
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
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
            print(json["contactListOfUser"])
            let responseArr = json["contactListOfUser"] as! [AnyObject]
            for element in responseArr{
                appContactsArr.append(element as! [String : AnyObject])
            }
            print(appContactsArr)
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
        print(appContactsArr)
        print(contactDataSource)
        
        
        dataSource = [appContactsArr,contactDataSource]
        print(dataSource)
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
        var cellDataSource:[String:AnyObject]?
        var datasourceTmp: [[[String:AnyObject]]]?
        
        if(searchActive){
            datasourceTmp = searchDataSource
        }
        else{
            datasourceTmp = dataSource
        }
        
        print(datasourceTmp)
        
        if let dataSource = datasourceTmp
        {
            if dataSource.count > indexPath.section
            {
                if dataSource[indexPath.section].count > indexPath.row
                {
                    cellDataSource = dataSource[indexPath.section][indexPath.row]
                }
            }
            
        }
        
        if let cellDataSource = cellDataSource
        {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("contactTableViewCell", forIndexPath:indexPath) as! contactTableViewCell
            
            cell.contactProfileName.text = cellDataSource[nameKey] as? String
            //            cell.contactProfileImage.image = cellDataSource[imageKey] as? UIImage
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
                print(tmp)
                if(tmp.hasPrefix(searchText.lowercaseString))
                {
                    searchAppContactsArr.append(element)
                    print(searchAppContactsArr)
                }
            }
        }
        if dataSource![1].count > 0
        {
            for element in dataSource![1]{
               let tmp: String =  (element["user_name"]?.lowercaseString)!
                print(tmp)
                if(tmp.hasPrefix(searchText.lowercaseString))
                {
                    searchContactDataSource.append(element)
                      print(searchContactDataSource)
                }
            }
        }
        
        searchDataSource = [searchAppContactsArr, searchContactDataSource]
        print(searchDataSource)
        
        if((searchAppContactsArr.count == 0) && (searchContactDataSource.count == 0)){
            searchActive = false;
        } else {
            searchActive = true;
        }
        
        self.contactTableView.reloadData()
    }
}
