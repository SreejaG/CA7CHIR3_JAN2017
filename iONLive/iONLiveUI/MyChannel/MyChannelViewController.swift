//
//  MyChannelViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/28/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MyChannelViewController: UIViewController,UISearchBarDelegate {
    
    static let identifier = "MyChannelViewController"
    
    @IBOutlet weak var myChannelSearchBar: UISearchBar!
    @IBOutlet var addChannelViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var myChannelTableView: UITableView!
    
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var notifImage: UIButton!
    @IBOutlet var addChannelView: UIView!
    
    @IBOutlet var channelTextField: UITextField!
    @IBOutlet var channelCreateButton: UIButton!
    @IBOutlet var myChannelTableViewTopConstraint: NSLayoutConstraint!
    let requestManager = RequestManager.sharedInstance
    @IBOutlet var SearchBarBottomConstraint: NSLayoutConstraint!
    let channelManager = ChannelManager.sharedInstance
    @IBOutlet var tableviewBottomConstraint: NSLayoutConstraint!
    var gestureRecognizer = UIGestureRecognizer()
  
    var loadingOverlay: UIView?
    
    let channelNameKey = "channelName"
    let channelItemCountKey = "channelItemCount"
    let channelHeadImageNameKey = "channelHeadImageName"
    let channelIdKey = "channelId"
    let channelCreatedTimeKey = "channelCreatedTime"
    
    var searchActive : Bool = false
    
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var searchDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var channelDetailsDict : [[String:AnyObject]] = [[String:AnyObject]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = NSUserDefaults .standardUserDefaults()
        if let notifFlag = defaults.valueForKey("notificationArrived")
        {
            if notifFlag as! String == "0"
            {
                let image = UIImage(named: "noNotif") as UIImage?
                notifImage.setImage(image, forState: .Normal)
            }
        }
        else{
            let image = UIImage(named: "notif") as UIImage?
            notifImage.setImage(image, forState: .Normal)
        }
        initialise()
        hideView(0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        searchActive = false
        myChannelTableView.reloadData()
        myChannelSearchBar.resignFirstResponder()
        tableViewBottomConstraint.constant = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapNotificationButton(sender: AnyObject) {
        
        let notificationStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let channelItemListVC = notificationStoryboard.instantiateViewControllerWithIdentifier(MyChannelNotificationViewController.identifier) as! MyChannelNotificationViewController
        channelItemListVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelItemListVC, animated: false)
        
    }
    
    @IBAction func didTapCreateButton(sender: AnyObject) {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        let channelname: String = channelTextField.text!
        channelTextField.resignFirstResponder()
        channelCreateButton.hidden = true
        addChannelViewTopConstraint.constant = 0
        myChannelTableViewTopConstraint.constant = 0
        hideView(0)
        myChannelSearchBar.text = ""
        myChannelSearchBar.resignFirstResponder()
        myChannelSearchBar.delegate = self
        addChannelDetails(userId, token: accessToken, channelName: channelname)
        
    }
    
    func addChannelDetails(userName: String, token: String, channelName: String)
    {
        showOverlay()
        channelManager.addChannelDetails(userName, accessToken: token, channelName: channelName, success: { (response) -> () in
            self.authenticationSuccessHandlerAddChannel(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandlerAddChannel(error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerAddChannel(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            channelTextField.text = ""
            let image = UIImage(named: "thumb12")
            let channelId = json["channelId"]?.stringValue
            let channelName = json["channelName"] as! String
            self.dataSource.insert([self.channelIdKey:channelId!,self.channelNameKey:channelName,self.channelItemCountKey:"0",self.channelCreatedTimeKey:self.dataSource[0][self.channelCreatedTimeKey]!], atIndex: 0)
            myChannelTableView.reloadData()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandlerAddChannel(error: NSError?, code: String)
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
    }
    
    @IBAction func channelTextFieldChange(sender: AnyObject) {
        
        if let text = channelTextField.text where !text.isEmpty
        {
            if text.characters.count >= 3
            {
                channelCreateButton.hidden = false
            }
            else
            {
                channelCreateButton.hidden = true
            }
        }
    }
    
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    @IBAction func tapGestureRecognizer(sender: AnyObject) {
        view.endEditing(true)
        self.myChannelSearchBar.text = ""
        self.myChannelSearchBar.resignFirstResponder()
        searchActive = false
        self.myChannelTableView.reloadData()
    }
    
    @IBAction func didtapBackButton(sender: AnyObject)
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
    }
    
    @IBAction func didTapAddChannelButton(sender: AnyObject) {
        
        showviewWithNewConstraints()
        searchActive = false
    }
    
    func  showviewWithNewConstraints()
    {
        addChannelView.hidden = false
        addChannelViewTopConstraint.constant = -40
        myChannelSearchBar.hidden = true
        myChannelTableViewTopConstraint.constant = 0
    }
    
    func hideView(constraintConstant: CGFloat)
    {
        addChannelView.hidden = true
        myChannelSearchBar.hidden = true
        myChannelTableViewTopConstraint.constant = -120 + constraintConstant
    }
    
    func initialise()
    {
        channelDetailsDict.removeAll()
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        myChannelSearchBar.delegate = self
        gestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        myChannelTableView.addGestureRecognizer(gestureRecognizer)
        channelCreateButton.hidden = true
        getChannelDetails(userId, token: accessToken)
    }
    
    func textFieldDidChange(textField: UITextField)
    {
        if let text = textField.text where !text.isEmpty
        {
            if text.characters.count >= 3
            {
                channelCreateButton.hidden = false
            }
            else
            {
                channelCreateButton.hidden = true
            }
        }
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
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
       if let json = response as? [String: AnyObject]
        {
            channelDetailsDict.removeAll()
            channelDetailsDict = json["channels"] as! [[String:AnyObject]]
            setChannelDetails()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
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
    }
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    func setChannelDetails()
    {
        dataSource.removeAll()
        var imageDetails : UIImage?
        for element in channelDetailsDict{
            let channelId = element["channel_detail_id"]?.stringValue
            let channelName = element["channel_name"] as! String
            let mediaSharedCount = element["total_no_media_shared"]?.stringValue
            let createdTime = element["last_updated_time_stamp"] as! String
            print("\(createdTime)   \(channelName)")
            let thumbUrlBeforeNullChk = element["thumbnail_Url"] as! String
            let url = nullToNil(thumbUrlBeforeNullChk) as! String
            let thumbUrl: NSURL = convertStringtoURL(url)
            let mediaDetailId = element["media_detail_id"]?.stringValue
            
            dataSource.append([channelIdKey:channelId!, channelNameKey:channelName, channelItemCountKey:mediaSharedCount!, channelCreatedTimeKey: createdTime, channelHeadImageNameKey:thumbUrl])
        }
        
        dataSource.sortInPlace({ p1, p2 in
            let time1 = p1[channelCreatedTimeKey] as! String
            let time2 = p2[channelCreatedTimeKey] as! String
            return time1 > time2
        })
        
        self.removeOverlay()
        myChannelTableView.reloadData()
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
    
    func addKeyboardObservers()
    {
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:"keyboardDidShow:", name: UIKeyboardDidShowNotification, object:nil)]
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:"keyboardDidHide", name: UIKeyboardWillHideNotification, object:nil)]
    }
    
    func keyboardDidShow(notification:NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if tableViewBottomConstraint.constant == 0
        {
            self.tableViewBottomConstraint.constant = self.tableViewBottomConstraint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if tableViewBottomConstraint.constant != 0
        {
            self.tableViewBottomConstraint.constant = 0
        }
    }
    
    func generateWaytoSendAlert(channelId: String, indexPath: Int)
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        let alert = UIAlertController(title: "Delete!!!", message: "Do you want to delete the channel", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.deleteChannelDetails(userId, token: accessToken, channelId: channelId, index: indexPath)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func deleteChannelDetails(userName: String, token: String, channelId:String, index: Int)
    {
        showOverlay()
        channelManager.deleteChannelDetails(userName: userName, accessToken: token, deleteChannelId: channelId, success: { (response) -> () in
            self.authenticationSuccessHandlerDelete(response,index: index)
        }) { (error, message) -> () in
            self.authenticationFailureHandlerDelete(error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerDelete(response:AnyObject?, index:Int)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                if(searchActive){
                    let channelId = searchDataSource[index][channelIdKey] as! String
                    searchDataSource.removeAtIndex(index)
                    for(var i = 0; i < dataSource.count; i++){
                        let orgChannel = dataSource[i][channelIdKey] as! String
                        if(orgChannel == channelId){
                            dataSource.removeAtIndex(i)
                        }
                    }
                }
                else{
                   dataSource.removeAtIndex(index)
                }
                myChannelTableView.reloadData()
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandlerDelete(error: NSError?, code: String)
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
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
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
    
    func handleTap(gestureRecognizer: UIGestureRecognizer) {
        let swipeLocation = gestureRecognizer.locationInView(self.myChannelTableView)
        if let swipedIndexPath = self.myChannelTableView.indexPathForRowAtPoint(swipeLocation) {
            let sharingStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
            let channelItemListVC = sharingStoryboard.instantiateViewControllerWithIdentifier(ChannelItemListViewController.identifier) as! ChannelItemListViewController
            if(!searchActive){
                if dataSource.count > swipedIndexPath.row
                {
                    channelItemListVC.channelId = dataSource[swipedIndexPath.row][channelIdKey] as! String
                    channelItemListVC.channelName = dataSource[swipedIndexPath.row][channelNameKey] as! String
                    channelItemListVC.totalMediaCount = Int(dataSource[swipedIndexPath.row][channelItemCountKey]! as! String)!
                }
            }
            else{
                if searchDataSource.count > swipedIndexPath.row
                {
                    channelItemListVC.channelId = searchDataSource[swipedIndexPath.row][channelIdKey] as! String
                    channelItemListVC.channelName = searchDataSource[swipedIndexPath.row][channelNameKey] as! String
                    channelItemListVC.totalMediaCount = Int(searchDataSource[swipedIndexPath.row][channelItemCountKey]! as! String)!
                }
            }
            channelItemListVC.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(channelItemListVC, animated: false)
        }
    }
}

extension MyChannelViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 75.0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
}

extension MyChannelViewController:UITableViewDataSource
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
        }
        else{
            dataSourceTmp = dataSource
        }
        
        if dataSourceTmp!.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(MyChannelCell.identifier, forIndexPath:indexPath) as! MyChannelCell
            
            cell.channelNameLabel.text = dataSourceTmp![indexPath.row][channelNameKey] as? String
            cell.channelItemCount.text = dataSourceTmp![indexPath.row][channelItemCountKey] as? String
            if let thumbUrl = dataSourceTmp![indexPath.row][channelHeadImageNameKey]
            {
                cell.channelHeadImageView.sd_setImageWithURL(thumbUrl as! NSURL,placeholderImage: UIImage(named: "thumb12"))
            }
            else{
                cell.channelHeadImageView.image = UIImage(named: "thumb12")
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
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        var channelName : String = String()
        if(searchActive){
            channelName = searchDataSource[indexPath.row][channelNameKey] as! String
        }
        else{
            channelName = dataSource[indexPath.row][channelNameKey] as! String
        }
       
        if ((channelName == "My Day") || (channelName == "Archive"))
        {
            return false
        }
        else
        {
            return true
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let deletedChannelId = self.dataSource[indexPath.row][self.channelIdKey]! as! String
            generateWaytoSendAlert(deletedChannelId, indexPath: indexPath.row)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if(addChannelView.hidden)
        {
            myChannelSearchBar.hidden = false
            addChannelView.hidden = true
            myChannelTableViewTopConstraint.constant = -90
        }
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if searchBar.text!.isEmpty
        {
            searchActive = false
            searchDataSource.removeAll()
        }
        else{
            searchActive = true
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchDataSource.removeAll()
        if myChannelSearchBar.text!.isEmpty
        {
            searchDataSource = dataSource
            myChannelSearchBar.resignFirstResponder()
            self.myChannelTableView.reloadData()
        }
        else{
            if dataSource.count > 0
            {
                for element in dataSource{
                    let tmp: String = (element[channelNameKey]?.lowercaseString)!
                    if(tmp.containsString(searchText.lowercaseString))
                    {
                        searchDataSource.append(element)
                    }
                }
                searchActive = true
                self.myChannelTableView.reloadData()
            }
        }
    }
}


