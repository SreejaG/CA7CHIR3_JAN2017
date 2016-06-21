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
    var fullDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var channelDetailsDict : [[String:AnyObject]] = [[String:AnyObject]]()
    var searchActive : Bool = false
    var searchDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var selectedArray : [Int] = [Int]()
    var addChannelArray : NSMutableArray = NSMutableArray()
    var deleteChannelArray : NSMutableArray = NSMutableArray()
    
    @IBOutlet var doneButton: UIButton!
    
    var loadingOverlay: UIView?
    
    var tapFlag : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("CallRefreshMySharedChannelTableView:"), name: "refreshMySharedChannelTableView", object: nil)
        channelDetailsDict.removeAll()
        dataSource.removeAll()
        fullDataSource.removeAll()
        selectedArray.removeAll()
        addChannelArray.removeAllObjects()
        deleteChannelArray.removeAllObjects()
        sharedChannelsSearchBar.delegate = self
        createChannelDataSource()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func backButtonClicked(sender: AnyObject)
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
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
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        self.sharedChannelsTableView.reloadData()
        sharedChannelsTableView.layoutIfNeeded()
        addChannelArray.removeAllObjects()
        deleteChannelArray.removeAllObjects()
        for var i = 0; i < fullDataSource.count; i++
        {
            let channelid = fullDataSource[i][channelIdKey] as! String
            if(selectedArray.contains(i)){
               addChannelArray.addObject(channelid)
            }
            else{
                deleteChannelArray.addObject(channelid)
            }
        }
        if((addChannelArray.count > 0) || (deleteChannelArray.count > 0)){
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            enableDisableChannels(userId, token: accessToken, addChannels: addChannelArray, deleteChannels: deleteChannelArray)
        }
    }
    
    func  enableDisableChannels(userName: String, token: String, addChannels: NSMutableArray, deleteChannels:NSMutableArray) {
        showOverlay()
        channelManager.enableDisableChannels(userName, accessToken: token, addChannel: addChannels, deleteChannel: deleteChannels, success: { (response) in
            self.authenticationSuccessHandlerEnableDisable(response)
        }) { (error, message) in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func loadInitialViewController(code: String){
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
    
    func authenticationSuccessHandlerEnableDisable(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                 sharedChannelsTableView.reloadData()
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func createChannelDataSource()
    {
        tapFlag = true
        doneButton.hidden = true
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
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        channelDetailsDict.removeAll()
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
        fullDataSource.removeAll()
        
        for element in channelDetailsDict{
            let sharedBool = Int(element["channel_shared_ind"] as! Bool)
            let channelId = element["channel_detail_id"]?.stringValue
            let channelName = element["channel_name"] as! String
            if channelName != "Archive"
            {
                let mediaSharedCount = element["total_no_media_shared"]?.stringValue
                let createdTime = element["last_updated_time_stamp"] as! String
                let thumbUrl = element["thumbnail_Url"] as! String
                let mediaDetailId = element["media_detail_id"]?.stringValue
                dataSource.append([channelIdKey:channelId!, channelNameKey:channelName, channelItemCountKey:    mediaSharedCount!, channelCreatedTimeKey: createdTime, channelHeadImageNameKey:thumbUrl, channelSelectionKey:sharedBool])
            }
        }
        dataSource.sortInPlace({ p1, p2 in
            let time1 = p1[channelCreatedTimeKey] as! String
            let time2 = p2[channelCreatedTimeKey] as! String
            return time1 > time2
        })
        if(dataSource.count > 0){
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, {
                self.downloadMediaFromGCS()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                })
            })
        }
    }
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
        let data = NSData(contentsOfURL: downloadURL)
        if let imageData = data as NSData? {
            if let mediaImage1 = UIImage(data: imageData)
            {
                mediaImage = mediaImage1
            }
            completion(result: mediaImage)
        }
        else
        {
            completion(result:UIImage(named: "thumb12")!)
        }
    }
    
    func downloadMediaFromGCS(){
        for var i = 0; i < dataSource.count; i++
        {
            var imageForMedia : UIImage = UIImage()
            let mediaUrl = dataSource[i][channelHeadImageNameKey] as! String
            if(mediaUrl != ""){
                let url: NSURL = convertStringtoURL(mediaUrl)
                downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                    if(result != UIImage()){
                        imageForMedia = result
                    }
                })
            }
            self.fullDataSource.append([self.channelIdKey:self.dataSource[i][self.channelIdKey]!,self.channelNameKey:self.dataSource[i][self.channelNameKey]!,self.channelItemCountKey:self.dataSource[i][self.channelItemCountKey]!,self.channelCreatedTimeKey:self.dataSource[i][self.channelCreatedTimeKey]!,self.channelHeadImageNameKey:imageForMedia,self.channelSelectionKey: self.dataSource[i][self.channelSelectionKey]!])
            let channelSharedBool = self.dataSource[i][self.channelSelectionKey] as! Int
            if(channelSharedBool == 1){
                selectedArray.append(i)
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.sharedChannelsTableView.reloadData()
            })
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
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
        if tapFlag == true
        {
            doneButton.hidden = true
        }
        else{
            doneButton.hidden = false
        }
        self.sharedChannelsTableView.reloadData()
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
    
    func CallRefreshMySharedChannelTableView(notif:NSNotification){
        let indexpath = notif.object as! Int
        if(selectedArray.contains(indexpath)){
            let elementIndex = selectedArray.indexOf(indexpath)
            selectedArray.removeAtIndex(elementIndex!)
        }
        else{
            selectedArray.append(indexpath)
        }
        sharedChannelsTableView.reloadData()
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
        return 0.01
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
            return fullDataSource.count > 0 ? (fullDataSource.count) : 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var dataSourceTmp : [[String:AnyObject]]?
        if(searchActive){
            dataSourceTmp = searchDataSource
        }
        else{
            dataSourceTmp = fullDataSource
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
            cell.channelSelectionButton.tag = indexPath.row
            if(selectedArray.contains(indexPath.row)){
                cell.channelSelectionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
                cell.sharedCountLabel.hidden = false
                cell.avatarIconImageView.hidden = false
            }
            else{
                cell.channelSelectionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
                cell.sharedCountLabel.hidden = true
                cell.avatarIconImageView.hidden = true
            }
            
            if tapFlag == true
            {
                cell.channelSelectionButton.addTarget(self, action: "handleTap", forControlEvents: UIControlEvents.TouchUpInside)
            }
            else{
                tapFlag = false
            }
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
            if fullDataSource.count > indexPath.row
            {
                (channelDetailVC as! MyChannelDetailViewController).channelId = fullDataSource[indexPath.row][channelIdKey] as! String
                (channelDetailVC as! MyChannelDetailViewController).channelName = fullDataSource[indexPath.row][channelNameKey] as! String
                (channelDetailVC as! MyChannelDetailViewController).totalMediaCount = Int(fullDataSource[indexPath.row][channelItemCountKey]! as! String)!
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
        self.navigationController?.pushViewController(channelDetailVC, animated: false)
    }
}

extension MySharedChannelsViewController : UISearchBarDelegate,UISearchDisplayDelegate{
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if self.sharedChannelsSearchBar.text != ""
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
        if sharedChannelsSearchBar.text == "" {
            sharedChannelsSearchBar.resignFirstResponder()
        }
        if fullDataSource.count > 0
        {
            for element in fullDataSource{
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
