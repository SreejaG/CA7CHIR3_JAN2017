//
//  MySharedChannelsViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/22/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MySharedChannelsViewController: UIViewController {
    
    static let identifier = "MySharedChannelsViewController"
    @IBOutlet weak var sharedChannelsTableView: UITableView!
    @IBOutlet weak var sharedChannelsSearchBar: UISearchBar!
    @IBOutlet weak var tableViewBottomConstaint: NSLayoutConstraint!
    
    let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance
    
    let channelNameKey = "channelName"
    let channelItemCountKey = "channelItemCount"
    let channelHeadImageNameKey = "channelHeadImageName"
    let channelIdKey = "channelId"
    let channelCreatedTimeKey = "channelCreatedTime"
    let channelSelectionKey = "channelSelection"
    
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var channelDetailsDict : [[String:AnyObject]] = [[String:AnyObject]]()
    var searchActive : Bool = false
    var searchDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    var channelArrayFromDefaults : [[String:AnyObject]] = [[String:AnyObject]]()
    var channelArrayWithSelection : [[String:AnyObject]] = [[String:AnyObject]]()
    
    var loadingOverlay: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        channelDetailsDict.removeAll()
        dataSource.removeAll()
        sharedChannelsSearchBar.delegate = self
        createChannelDataSource()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        let defaults = NSUserDefaults .standardUserDefaults()
        sharedChannelsTableView.reloadData()
        defaults.setObject(channelArrayWithSelection, forKey: "channelArray")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func backButtonClicked(sender: AnyObject)
    {
        self.dismissViewControllerAnimated(true) { () -> Void in
        }
    }
    
    func addKeyboardObservers()
    {
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:"keyboardDidShow:", name: UIKeyboardDidShowNotification, object:nil)]
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:"keyboardDidHide", name: UIKeyboardWillHideNotification, object:nil)]
    }
    
    func keyboardDidShow(notification:NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if tableViewBottomConstaint.constant == 0
        {
            self.tableViewBottomConstaint.constant = self.tableViewBottomConstaint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if tableViewBottomConstaint.constant != 0
        {
            self.tableViewBottomConstaint.constant = 0
        }
    }
    
    @IBAction func gestureTapped(sender: AnyObject) {
        view.endEditing(true)
        self.sharedChannelsSearchBar.text = ""
        self.sharedChannelsSearchBar.resignFirstResponder()
        searchActive = false
        self.sharedChannelsTableView.reloadData()
        
    }
    
    func createChannelDataSource()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelDetails(userId, token: accessToken)
    }
    
    func getChannelDetails(userName: String, token: String)
    {
        showOverlay()
        channelManager.getChannelDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                return
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
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            channelDetailsDict = json["channels"] as! [[String:AnyObject]]
            setChannelDetails()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func setChannelDetails()
    {
        dataSource.removeAll()
        var imageDetails : UIImage?
        for element in channelDetailsDict{
            let sharedBool = Int(element["channel_shared_ind"] as! Bool)
            if(sharedBool == 1){
                let channelId = element["channel_detail_id"]?.stringValue
                let channelName = element["channel_name"] as! String
                let mediaSharedCount = element["total_no_media_shared"]?.stringValue
                let createdTime = element["last_updated_time_stamp"] as! String
                let thumbUrl = element["thumbnail_Url"] as! String
                if(thumbUrl != "")
                {
                    let url: NSURL = convertStringtoURL(thumbUrl)
                    if let data = NSData(contentsOfURL: url){
                        let imageDetailsData = (data as NSData?)!
                        imageDetails = UIImage(data: imageDetailsData)
                    }
                }
                else{
                    imageDetails = UIImage(named: "thumb12")
                }
                dataSource.append([channelIdKey:channelId!, channelNameKey:channelName, channelItemCountKey:    mediaSharedCount!, channelCreatedTimeKey: createdTime, channelHeadImageNameKey:imageDetails!])
                channelArrayWithSelection.append([channelIdKey:channelId!, channelSelectionKey:"0"])
            }
        }
        
        dataSource.sortInPlace({ p1, p2 in
            let time1 = p1[channelCreatedTimeKey] as! String
            let time2 = p2[channelCreatedTimeKey] as! String
            return time1 > time2
        })
        
        
        let defaults = NSUserDefaults .standardUserDefaults()
        if let channelArrayFromDefaults = defaults.arrayForKey("channelArray")
        {
            if(channelArrayFromDefaults.count > 0){
                for elements in channelArrayFromDefaults
                {
                    for var i = 0; i < channelArrayWithSelection.count; i++
                    {
                        if elements[channelIdKey] as! String == channelArrayWithSelection[i][channelIdKey] as! String{
                            if elements[channelSelectionKey] as! String == "1"
                            {
                                channelArrayWithSelection[i][channelSelectionKey] = "1"
                            }
                        }
                    }
                }
            }
        }
        
        sharedChannelsTableView.reloadData()
        
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
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
}

extension MySharedChannelsViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 45.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(MySharedChannelsHeaderCell.identifier) as! MySharedChannelsHeaderCell
        headerCell.headerTitleLabel.text = "MY SHARED CHANNELS"
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 60
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01   // to avoid extra blank lines
    }
}


extension MySharedChannelsViewController:UITableViewDataSource
{
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
        
        if(searchActive){
            dataSourceTmp = searchDataSource
            sharedChannelsTableView.reloadInputViews()
        }
        else{
            dataSourceTmp = dataSource
        }
        
        
        if dataSourceTmp!.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(MySharedChannelsCell.identifier, forIndexPath:indexPath) as! MySharedChannelsCell
            
            cell.channelNameLabel.text = dataSourceTmp![indexPath.row][channelNameKey] as? String
            cell.sharedCountLabel.text = dataSourceTmp![indexPath.row][channelItemCountKey] as? String
            if let imageData =  dataSourceTmp![indexPath.row][channelHeadImageNameKey]
            {
                cell.userImage.image = imageData as? UIImage
            }
            if(dataSourceTmp![indexPath.row][channelItemCountKey] as! String == "0"){
                cell.userImage.image = UIImage(named: "thumb12")
            }
            
            if(cell.selectedArray.count > 0){
                
                for var i = 0; i < channelArrayWithSelection.count; i++
                {
                    let selectedValue: String = channelArrayWithSelection[i][channelIdKey] as! String
                    if cell.selectedArray.containsObject(selectedValue){
                        channelArrayWithSelection[i][channelSelectionKey] = "1"
                    }
                }
            }
            
            if(cell.deselectedArray.count > 0){
                
                for var i = 0; i < channelArrayWithSelection.count; i++
                {
                    let selectedValue: String = channelArrayWithSelection[i][channelIdKey] as! String
                    if cell.deselectedArray.containsObject(selectedValue){
                        channelArrayWithSelection[i][channelSelectionKey] = "0"
                    }
                }
            }
            
            if channelArrayWithSelection.count > 0
            {
                for var i = 0; i < channelArrayWithSelection.count; i++
                {
                    if channelArrayWithSelection[i][channelIdKey] as! String == dataSourceTmp![indexPath.row][channelIdKey] as! String{
                        if channelArrayWithSelection[i][channelSelectionKey] as! String == "0"
                        {
                            
                            cell.channelSelectionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
                            cell.sharedCountLabel.hidden = true
                            cell.avatarIconImageView.hidden = true
                        }
                        else{
                            
                            cell.channelSelectionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
                            cell.sharedCountLabel.hidden = false
                            cell.avatarIconImageView.hidden = false
                        }
                    }
                }
                
            }
            
            cell.cellDataSource = dataSourceTmp![indexPath.row]
            cell.selectionStyle = .None
            return cell
        }
        else{
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let channelDetailVC:UITabBarController = sharingStoryboard.instantiateViewControllerWithIdentifier(MyChannelDetailViewController.identifier) as! UITabBarController
        if(!searchActive){
            if dataSource.count > indexPath.row
            {
                (channelDetailVC as! MyChannelDetailViewController).channelId = dataSource[indexPath.row][channelIdKey] as! String
                 (channelDetailVC as! MyChannelDetailViewController).channelName = dataSource[indexPath.row][channelNameKey] as! String
                 (channelDetailVC as! MyChannelDetailViewController).totalMediaCount = Int(dataSource[indexPath.row][channelItemCountKey]! as! String)!
            }
        }
        else{
            if searchDataSource.count > indexPath.row
            {
                (channelDetailVC as! MyChannelDetailViewController).channelId = searchDataSource[indexPath.row][channelIdKey] as! String
                (channelDetailVC as! MyChannelDetailViewController).channelName = searchDataSource[indexPath.row][channelNameKey] as! String
                (channelDetailVC as! MyChannelDetailViewController).totalMediaCount = Int(searchDataSource[indexPath.row][channelItemCountKey]! as! String)!
            }
        }
        
        channelDetailVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelDetailVC, animated: true)
    }
}

extension MySharedChannelsViewController : UISearchBarDelegate{
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
        sharedChannelsSearchBar.text = ""
        sharedChannelsSearchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchDataSource.removeAll()
        if sharedChannelsSearchBar.text == "" {
            sharedChannelsSearchBar.resignFirstResponder()
        }
        if dataSource.count > 0
        {
            for element in dataSource{
                let tmp: String = (element[channelNameKey]?.lowercaseString)!
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
        
        self.sharedChannelsTableView.reloadData()
    }
    
}
