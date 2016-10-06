

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
    
    var selectedChannelId:String!
    
    var channelSelected: NSMutableArray = NSMutableArray()
    var fulldataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    var localMediaDict : [[String:AnyObject]] = [[String:AnyObject]]()
    var localChannelDict : [[String:AnyObject]] = [[String:AnyObject]]()
    
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
    }
    
    func addKeyboardObservers()
    {
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:#selector(AddChannelViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object:nil)]
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:#selector(AddChannelViewController.keyboardDidHide), name: UIKeyboardWillHideNotification, object:nil)]
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
    
    func initialise()
    {
        channelSelected.removeAllObjects()
        selectedArray.removeAll()
        
        doneButton.hidden = true
        shareFlag = true
        channelCreateButton.hidden = true
        channelTextField.addTarget(self, action: #selector(AddChannelViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        addChannelView.userInteractionEnabled = true
        addChannelView.alpha = 1
        addToChannelTitleLabel.text = "ADD TO CHANNEL"
        
        let defaults = NSUserDefaults.standardUserDefaults()
        userId = defaults.valueForKey(userLoginIdKey) as! String
        accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        setChannelDetailsDummy()
    }
    
    func setChannelDetailsDummy()
    {
        fulldataSource.removeAll()
        for element in GlobalDataChannelList.sharedInstance.globalChannelDataSource{
            
            let channelId = element[channelIdKey] as! String
            if(channelId != selectedChannelId)
            {
                fulldataSource.append(element)
            }
            addChannelTableView.reloadData()
        }
    }
    
    func textFieldDidChange(textField: UITextField)
    {
        if let text = textField.text where !text.isEmpty
        {
            if(text.characters.count >= 3)
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
        if(channelTextField.text?.characters.count > 15){
            channelTextField.resignFirstResponder()
            channelTextField.text = ""
            channelCreateButton.hidden = true
            ErrorManager.sharedInstance.InvalidChannelEnteredError()
        }
        else{
            let channelname: String = channelTextField.text!
            channelTextField.text = ""
            channelCreateButton.hidden = true
            channelTextField.resignFirstResponder()
            addChannelDetails(userId, token: accessToken, channelName: channelname)
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
            let channelId = json["channelId"]?.stringValue
            let channelName = json["channelName"] as! String
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.timeZone = NSTimeZone(name: "UTC")
            let localDateStr = dateFormatter.stringFromDate(NSDate())
            
            GlobalDataChannelList.sharedInstance.globalChannelDataSource.insert([channelIdKey:channelId!, channelNameKey:channelName, totalMediaKey:"0", createdTimeKey: localDateStr,sharedOriginalKey:1, sharedTemporaryKey:1], atIndex: 0)
            
            let imageData = [[String:AnyObject]]()
            GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.updateValue(imageData, forKey: channelId!)
            
            fulldataSource.insert([channelIdKey:channelId!, channelNameKey:channelName, totalMediaKey:"0", createdTimeKey: localDateStr,sharedOriginalKey:1, sharedTemporaryKey:1], atIndex: 0)
            
            addChannelTableView.reloadData()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        localChannelDict.removeAll()
        for i in 0 ..< selectedArray.count
        {
            let channelSelectedId = fulldataSource[selectedArray[i]][channelIdKey] as! String
            localChannelDict.append(fulldataSource[selectedArray[i]])
            channelSelected.addObject(channelSelectedId)
        }
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
            self.authenticationSuccessHandlerAdd(response,channelIds: channelIds,mediaIds: mediaIds)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerAdd(response : AnyObject?, channelIds:NSArray, mediaIds:NSArray)
    {
        GlobalChannelToImageMapping.sharedInstance.addMediaToChannel(localChannelDict, mediaDetailOfSelectedChannel: localMediaDict)
        
        removeOverlay()
        if (response as? [String: AnyObject]) != nil
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
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        
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
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
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
                catch _ as NSError {
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
        if fulldataSource.count > 0
        {
            return fulldataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if fulldataSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(AddChannelCell.identifier, forIndexPath:indexPath) as! AddChannelCell
            
            cell.addChannelTextLabel.text = fulldataSource[indexPath.row][channelNameKey] as? String
            cell.addChannelCountLabel.text = fulldataSource[indexPath.row][totalMediaKey] as? String
            
            if let latestImage = fulldataSource[indexPath.row][tImageKey]
            {
                cell.addChannelImageView.image = latestImage as? UIImage
            }
            else
            {
                cell.addChannelImageView.image = UIImage(named: "thumb12")
            }
            
            if(fulldataSource[indexPath.row][totalMediaKey] as! String == "0"){
                cell.addChannelImageView.image = UIImage(named: "thumb12")
            }
            
            if(selectedArray.contains(indexPath.row)){
                cell.accessoryType = .Checkmark
            }
            else{
                cell.accessoryType = .None
            }
            
            cell.selectionStyle = .None
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        shareFlag = false
        
        if(selectedArray.contains(indexPath.row)){
            let elementIndex = selectedArray.indexOf(indexPath.row)
            selectedArray.removeAtIndex(elementIndex!)
        }
        else{
            selectedArray.append(indexPath.row)
        }
        if(selectedArray.count <= 0){
            addChannelView.userInteractionEnabled = true
            addChannelView.alpha = 1.0
            doneButton.hidden = true
        }
        else{
            addChannelView.userInteractionEnabled = false
            addChannelView.alpha = 0.4
            doneButton.hidden = false
        }
        tableView.reloadData()
    }
}



