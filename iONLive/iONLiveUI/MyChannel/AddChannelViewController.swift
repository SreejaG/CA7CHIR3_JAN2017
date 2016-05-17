//
//  AddChannelViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 04/03/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class AddChannelViewController: UIViewController {
    
    static let identifier = "AddChannelViewController"
    
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var channelCreateButton: UIView!
    @IBOutlet var channelTextField: UITextField!
    
    @IBOutlet var addChannelTableView: UITableView!
    var userId : String!
    var accessToken : String!
    
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var addChannelView: UIView!
    @IBOutlet var addToChannelTitleLabel: UILabel!
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    
    var shareFlag : Bool = true
    var loadingOverlay: UIView?
    
    let channelNameKey = "channelName"
    let channelItemCountKey = "channelItemCount"
    let channelHeadImageNameKey = "channelHeadImageName"
    let channelIdKey = "channelId"
    let channelCreatedTimeKey = "channelCreatedTime"
    
    var channelSelected: NSMutableArray = NSMutableArray()
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var channelDetailsDict : [[String:AnyObject]] = [[String:AnyObject]]()
    var mediaDetailSelected : NSMutableArray = NSMutableArray()
    var selectedArray:[Int] = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        addToChannelTitleLabel.text = "ADD TO CHANNEL"
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        removeOverlay()
    }
    
    func initialise()
    {
        channelDetailsDict.removeAll()
        channelSelected.removeAllObjects()
        selectedArray.removeAll()
        doneButton.hidden = true
        shareFlag = true
        addChannelView.userInteractionEnabled = true
        addChannelView.alpha = 1
        addToChannelTitleLabel.text = "ADD TO CHANNEL"
        let defaults = NSUserDefaults.standardUserDefaults()
        userId = defaults.valueForKey(userLoginIdKey) as! String
        accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelDetails(userId, token: accessToken)
        channelCreateButton.hidden = true
        channelTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
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
    
    @IBAction func didTapCancelButon(sender: AnyObject){
        if(shareFlag == false){
            shareFlag = true
            addChannelView.userInteractionEnabled = true
            addChannelView.alpha = 1
            doneButton.hidden = true
            addToChannelTitleLabel.text = "ADD TO CHANNEL"
            selectedArray.removeAll()
            addChannelTableView.reloadData()
        }
        else{
            let storyboard = UIStoryboard(name:"MyChannel", bundle: nil)
            let channelVC = storyboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier) as! MyChannelViewController
            channelVC.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(channelVC, animated: false)
        }
    }
    
    @IBAction func didTapGestureRecognizer(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func didTapCreateButton(sender: AnyObject) {
        let channelname: String = channelTextField.text!
        channelTextField.text = ""
        channelCreateButton.hidden = true
        channelTextField.resignFirstResponder()
        addChannelDetails(userId, token: accessToken, channelName: channelname)
    }
    
    func getChannelDetails(userName: String, token: String)
    {
        showOverlay()
        channelManager.getChannelDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandlerList(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func addChannelDetails(userName: String, token: String, channelName: String)
    {
        showOverlay()
        channelManager.addChannelDetails(userName, accessToken: token, channelName: channelName, success: { (response) -> () in
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
            channelTextField.text = ""
            getChannelDetails(userId, token: accessToken)
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
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
        self.navigationController?.presentViewController(channelItemListVC, animated: true, completion: nil)
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
            ErrorManager.sharedInstance.inValidResponseError()
        }
        if(shareFlag == false){
            shareFlag = true
            addChannelView.userInteractionEnabled = true
            addChannelView.alpha = 1
            doneButton.hidden = true
            addToChannelTitleLabel.text = "ADD TO CHANNEL"
            selectedArray.removeAll()
            addChannelTableView.reloadData()
        }
    }
    
    func authenticationSuccessHandlerList(response:AnyObject?)
    {
        removeOverlay()
        channelSelected.removeAllObjects()
        selectedArray.removeAll()
        if(shareFlag == false){
            shareFlag = true
            addChannelView.userInteractionEnabled = true
            addChannelView.alpha = 1
            doneButton.hidden = true
            addToChannelTitleLabel.text = "ADD TO CHANNEL"
        }
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
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func setChannelDetails()
    {
        dataSource.removeAll()
        var imageDetails  = UIImage?()
        for element in channelDetailsDict{
            
            let channelId = element["channel_detail_id"]?.stringValue
            let channelName = element["channel_name"] as! String
            let mediaSharedCount = element["total_no_media_shared"]?.stringValue
            let createdTime = element["last_updated_time_stamp"] as! String
            let thumbUrl = element["thumbnail_Url"] as! String
            
            if(thumbUrl != "")
            {
                let url: NSURL = convertStringtoURL(thumbUrl)
                let data = NSData(contentsOfURL: url)
                if let imageData = data as NSData? {
                    imageDetails = UIImage(data: imageData)
                }
            }
            else{
                imageDetails = UIImage(named: "thumb12")
            }
            dataSource.append([channelIdKey:channelId!, channelNameKey:channelName, channelItemCountKey:mediaSharedCount!, channelCreatedTimeKey: createdTime, channelHeadImageNameKey:imageDetails!])
        }
        
        dataSource.sortInPlace({ p1, p2 in
            let time1 = p1[channelCreatedTimeKey] as! String
            let time2 = p2[channelCreatedTimeKey] as! String
            return time1 > time2
        })
        addChannelTableView.reloadData()
        
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
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
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        
        if channelSelected.count > 0
        {
            addMediaToChannels(channelSelected, mediaIds: mediaDetailSelected)
        }
    }
    
    func addMediaToChannels(channelIds:NSArray, mediaIds:NSArray){
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        showOverlay()
        imageUploadManger.addMediaToChannel(userId, accessToken: accessToken, mediaIds: mediaIds, channelId: channelIds, success: { (response) -> () in
            self.authenticationSuccessHandlerAdd(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerAdd(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            channelTextField.text = ""
            let storyboard = UIStoryboard(name:"MyChannel", bundle: nil)
            let channelVC = storyboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier) as! MyChannelViewController
            channelVC.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(channelVC, animated: false)
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
}

extension AddChannelViewController: UITableViewDelegate
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

extension AddChannelViewController:UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if dataSource.count > 0
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if dataSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(AddChannelCell.identifier, forIndexPath:indexPath) as! AddChannelCell
            
            if(selectedArray.count != dataSource.count){
                selectedArray.append(0)
            }
            if(selectedArray.count <= 0)
            {
                cell.accessoryType = .None
            }
            
            cell.addChannelTextLabel.text = dataSource[indexPath.row][channelNameKey] as? String
            cell.addChannelCountLabel.text = dataSource[indexPath.row][channelItemCountKey] as? String
            if let imageData =  dataSource[indexPath.row][channelHeadImageNameKey]
            {
                cell.addChannelImageView.image = imageData as? UIImage
            }
            if(dataSource[indexPath.row][channelItemCountKey] as! String == "0"){
                cell.addChannelImageView.image = UIImage(named: "thumb12")
            }
            
            for i in 0 ..< selectedArray.count
            {
                let selectedValue: String = dataSource[i][channelIdKey] as! String
                if indexPath.row == i
                {
                    if selectedArray[i] == 1
                    {
                        cell.accessoryType = .Checkmark
                        if(channelSelected.containsObject(Int(selectedValue)!)){
                            
                        }
                        else{
                            channelSelected.addObject(Int(selectedValue)!)
                        }
                    }
                    else{
                        cell.accessoryType = .None
                        if(channelSelected.containsObject(Int(selectedValue)!)){
                            
                            channelSelected.removeObject(Int(selectedValue)!)
                        }
                        else{
                            
                        }
                        
                    }
                }
            }
            cell.selectionStyle = .None
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        shareFlag = false
        addChannelView.userInteractionEnabled = false
        addChannelView.alpha = 0.3
        doneButton.hidden = false
        for i in 0 ..< selectedArray.count
        {
            if i == indexPath.row
            {
                if selectedArray[i] == 0
                {
                    selectedArray[i] = 1
                    
                }else{
                    selectedArray[i] = 0
                }
            }
        }
        tableView.reloadData()
    }
    
}



