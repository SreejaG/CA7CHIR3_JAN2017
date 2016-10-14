
import UIKit

class MyChannelViewController: UIViewController,UISearchBarDelegate,UIScrollViewDelegate {
    
    @IBOutlet weak var myChannelSearchBar: UISearchBar!
    @IBOutlet weak var myChannelTableView: UITableView!
    
    @IBOutlet var addChannelViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var myChannelTableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var SearchBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet var tableviewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var notifImage: UIButton!
    @IBOutlet var channelCreateButton: UIButton!
    
    @IBOutlet var addChannelView: UIView!
    
    @IBOutlet var channelTextField: UITextField!
    
    @IBOutlet var channelUpdateSaveButton: UIButton!
    
    @IBOutlet var channelUpdateCancelButton: UIButton!
    
    @IBOutlet var channelAddButton: UIButton!
    
    @IBOutlet var backButton: UIButton!
    
    static let identifier = "MyChannelViewController"
    
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    
    var gestureRecognizer = UIGestureRecognizer()
    var longPressRecognizer : UILongPressGestureRecognizer = UILongPressGestureRecognizer()
    
    var loadingOverlay: UIView?
    
    var searchActive : Bool = false
    var longPressFlag : Bool = false
    var searchFlagForUpdateChannel : Bool = false
    var longPressIndexPathRow : Int = Int()
    var cellChannelUpdatedNameStr = String()
    
    var searchDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    override func viewDidLoad() {
        NSUserDefaults.standardUserDefaults().setValue("", forKey: "editedValue")
        super.viewDidLoad()
        channelUpdateSaveButton.hidden = true
        channelUpdateCancelButton.hidden = true
        searchFlagForUpdateChannel = false
        longPressIndexPathRow = -1
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(MyChannelViewController.removeActivityIndicator(_:)), name: "removeActivityIndicatorMyChannelList", object: nil)
        
        showOverlay()
        
        if(GlobalDataChannelList.sharedInstance.globalChannelDataSource.count > 0)
        {
            removeOverlay()
            self.myChannelTableView.reloadData()
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
    
    func hideView(constraintConstant: CGFloat)
    {
        addChannelView.hidden = true
        myChannelSearchBar.hidden = true
        myChannelTableViewTopConstraint.constant = -120 + constraintConstant
    }
    
    func initialise()
    {
        myChannelSearchBar.delegate = self
        gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MyChannelViewController.handleTap(_:)))
        myChannelTableView.addGestureRecognizer(gestureRecognizer)
        channelCreateButton.hidden = true
    }
    
    func removeActivityIndicator(notif : NSNotification){
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.removeOverlay()
        })
        self.myChannelTableView.reloadData()
    }
    
    func handleTap(gestureRecognizer: UIGestureRecognizer) {
        if(longPressFlag == false){
            let swipeLocation = gestureRecognizer.locationInView(self.myChannelTableView)
            if let swipedIndexPath = self.myChannelTableView.indexPathForRowAtPoint(swipeLocation) {
                let sharingStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
                let channelItemListVC = sharingStoryboard.instantiateViewControllerWithIdentifier(ChannelItemListViewController.identifier) as! ChannelItemListViewController
                if(!searchActive){
                    if GlobalDataChannelList.sharedInstance.globalChannelDataSource.count > swipedIndexPath.row
                    {
                        channelItemListVC.channelId = GlobalDataChannelList.sharedInstance.globalChannelDataSource[swipedIndexPath.row][channelIdKey] as! String
                        channelItemListVC.channelName = GlobalDataChannelList.sharedInstance.globalChannelDataSource[swipedIndexPath.row][channelNameKey] as! String
                        channelItemListVC.totalMediaCount = Int(GlobalDataChannelList.sharedInstance.globalChannelDataSource[swipedIndexPath.row][totalMediaKey]! as! String)!
                    }
                }
                else{
                    if searchDataSource.count > swipedIndexPath.row
                    {
                        channelItemListVC.channelId = searchDataSource[swipedIndexPath.row][channelIdKey] as! String
                        channelItemListVC.channelName = searchDataSource[swipedIndexPath.row][channelNameKey] as! String
                        channelItemListVC.totalMediaCount = Int(searchDataSource[swipedIndexPath.row][totalMediaKey]! as! String)!
                    }
                }
                channelItemListVC.navigationController?.navigationBarHidden = true
                self.navigationController?.pushViewController(channelItemListVC, animated: false)
            }
        }
    }
    
    @IBAction func didTapNotificationButton(sender: AnyObject) {
        let notificationStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let channelItemListVC = notificationStoryboard.instantiateViewControllerWithIdentifier(MyChannelNotificationViewController.identifier) as! MyChannelNotificationViewController
        channelItemListVC.navigationController?.navigationBarHidden = true
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            kCAMediaTimingFunctionEaseOut)
        animation.type = kCATransitionFade
        animation.subtype = kCATransitionFromBottom
        animation.fillMode = kCAFillModeRemoved
        animation.duration = 0.2
        self.navigationController?.view.layer.addAnimation(animation, forKey: "animation")
        self.navigationController?.pushViewController(channelItemListVC, animated: false)
    }
    
    @IBAction func didtapBackButton(sender: AnyObject)
    {
        let cameraViewStoryboard = UIStoryboard(name:"PhotoViewer" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("PhotoViewerViewController") as! PhotoViewerViewController
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
    }
    
    @IBAction func didTapAddChannelButton(sender: AnyObject) {
        showviewWithNewConstraints()
        searchActive = false
    }
    
    @IBAction func didTapChanelUpdateCancel(sender: AnyObject) {
        self.notifImage.hidden = false
        self.channelAddButton.hidden = false
        self.channelUpdateCancelButton.hidden = true
        self.channelUpdateSaveButton.hidden = true
        self.backButton.hidden = false
        longPressIndexPathRow = -1
        longPressFlag = false
        searchActive = false
        myChannelSearchBar.text! = ""
        searchDataSource.removeAll()
        searchFlagForUpdateChannel = false
        NSUserDefaults.standardUserDefaults().setValue("", forKey: "editedValue")
        myChannelSearchBar.hidden = false
        self.myChannelTableView.reloadData()
    }
    
    
    @IBAction func didTapChannelUpdateSave(sender: AnyObject) {
        let indexPath = NSIndexPath(forRow:longPressIndexPathRow, inSection:0)
        let cell : MyChannelCell? = self.myChannelTableView.cellForRowAtIndexPath(indexPath) as! MyChannelCell?
        if((cell?.editChanelNameTextField.text)!.characters.count > 15 || (cell?.editChanelNameTextField.text)!.characters.count <= 3){
            NSUserDefaults.standardUserDefaults().setValue("", forKey: "editedValue")
            ErrorManager.sharedInstance.InvalidChannelEnteredError()
            cell?.editChanelNameTextField.text = ""
        }
        else{
            cell?.editChanelNameTextField.resignFirstResponder()
            showOverlay()
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            cellChannelUpdatedNameStr = (cell?.editChanelNameTextField.text)!
            
            var chanelId : String = String()
            if(searchFlagForUpdateChannel){
                if(longPressIndexPathRow < searchDataSource.count){
                    chanelId = searchDataSource[longPressIndexPathRow][channelIdKey] as! String
                }
            }
            else{
                if(longPressIndexPathRow < GlobalDataChannelList.sharedInstance.globalChannelDataSource.count){
                chanelId = GlobalDataChannelList.sharedInstance.globalChannelDataSource[longPressIndexPathRow][channelIdKey] as! String
                }
            }
            if(chanelId != ""){
                channelManager.updateChannelName(userId, accessToken: accessToken, channelName: cellChannelUpdatedNameStr, channelId: chanelId, success: { (response) in
                    self.authenticationSuccessHandlerUpdateChannel(response)
                    }, failure: { (error, message) in
                        self.authenticationFailureHandlerDelete(error, code: message)
                        return
                })
            }
            else{
                NSUserDefaults.standardUserDefaults().setValue("", forKey: "editedValue")
            }
        }
    }
    
    func authenticationSuccessHandlerUpdateChannel(response:AnyObject?)
    {
        removeOverlay()
        longPressFlag = false
        if (response as? [String: AnyObject]) != nil
        {
            if(searchFlagForUpdateChannel){
                searchDataSource[longPressIndexPathRow][channelNameKey] = cellChannelUpdatedNameStr
                let chaId = searchDataSource[longPressIndexPathRow][channelIdKey] as! String
                for i in 0 ..< GlobalDataChannelList.sharedInstance.globalChannelDataSource.count
                {
                    if(GlobalDataChannelList.sharedInstance.globalChannelDataSource[i][channelIdKey] as! String == chaId)
                    {
                         GlobalDataChannelList.sharedInstance.globalChannelDataSource[i][channelNameKey] = cellChannelUpdatedNameStr
                    }
                }
            }
            else{
                 GlobalDataChannelList.sharedInstance.globalChannelDataSource[self.longPressIndexPathRow][channelNameKey] = self.cellChannelUpdatedNameStr
            }
            myChannelSearchBar.text! = ""
            searchDataSource.removeAll()
            searchActive = false
            searchFlagForUpdateChannel = false
            longPressIndexPathRow = -1
            cellChannelUpdatedNameStr = ""
            myChannelSearchBar.hidden = false
            NSUserDefaults.standardUserDefaults().setValue("", forKey: "editedValue")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.notifImage.hidden = false
                self.channelAddButton.hidden = false
                self.channelUpdateCancelButton.hidden = true
                self.channelUpdateSaveButton.hidden = true
                self.backButton.hidden = false
                self.myChannelTableView.reloadData()
            })
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
            myChannelSearchBar.text! = ""
            searchDataSource.removeAll()
            searchActive = false
            searchFlagForUpdateChannel = false
            longPressIndexPathRow = -1
            cellChannelUpdatedNameStr = ""
            myChannelSearchBar.hidden = false
            NSUserDefaults.standardUserDefaults().setValue("", forKey: "editedValue")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.notifImage.hidden = false
                self.channelAddButton.hidden = false
                self.channelUpdateCancelButton.hidden = true
                self.channelUpdateSaveButton.hidden = true
                self.backButton.hidden = false
                self.myChannelTableView.reloadData()
            })
        }
    }

    func  showviewWithNewConstraints()
    {
        addChannelView.hidden = false
        addChannelViewTopConstraint.constant = -40
        myChannelSearchBar.hidden = true
        myChannelTableViewTopConstraint.constant = 0
    }
    
    @IBAction func didTapCreateButton(sender: AnyObject) {
        if(channelTextField.text?.characters.count > 15){
            channelTextField.resignFirstResponder()
            channelTextField.text = ""
            channelCreateButton.hidden = true
            ErrorManager.sharedInstance.InvalidChannelEnteredError()
        }
        else{
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
            let channelId = json["channelId"]?.stringValue
            let channelName = json["channelName"] as! String
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.timeZone = NSTimeZone(name: "UTC")
            let localDateStr = dateFormatter.stringFromDate(NSDate())
            
            GlobalDataChannelList.sharedInstance.globalChannelDataSource.insert([channelIdKey:channelId!, channelNameKey:channelName, totalMediaKey:"0", createdTimeKey: localDateStr, sharedOriginalKey:1, sharedTemporaryKey:1], atIndex: 0)
            
            let imageData = [[String:AnyObject]]()
            GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.updateValue(imageData, forKey: channelId!)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.myChannelTableView.reloadData()
            })
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandlerAddChannel(error: NSError?, code: String)
    {
        self.removeOverlay()
        channelTextField.text = ""
        
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
                    
                    var deleteIndexOfI : Int = Int()
                    var deleteFlag = false
                    
                    for i in 0 ..< GlobalDataChannelList.sharedInstance.globalChannelDataSource.count
                    {
                        let orgChannel = GlobalDataChannelList.sharedInstance.globalChannelDataSource[i][channelIdKey] as! String
                        if(orgChannel == channelId){
                            deleteFlag = true
                            deleteIndexOfI = i
                            break
                        }
                    }
                    if deleteFlag == true
                    {
                        GlobalDataChannelList.sharedInstance.globalChannelDataSource.removeAtIndex(deleteIndexOfI)
                    }
                }
                else{
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource.removeAtIndex(index)
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.myChannelTableView.reloadData()
                })
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
        myChannelSearchBar.text! = ""
        NSUserDefaults.standardUserDefaults().setValue("", forKey: "editedValue")
        searchDataSource.removeAll()
        self.notifImage.hidden = false
        self.channelAddButton.hidden = false
        self.channelUpdateCancelButton.hidden = true
        self.channelUpdateSaveButton.hidden = true
        self.backButton.hidden = false
        self.longPressFlag = false
        self.searchFlagForUpdateChannel = false
        self.searchActive = false
        self.longPressIndexPathRow = -1
        myChannelSearchBar.hidden = false
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
        myChannelTableView.reloadData()
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
    
    @IBAction func channelTextFieldChange(sender: AnyObject) {
        
        if let text = channelTextField.text where !text.isEmpty
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
    
    @IBAction func tapGestureRecognizer(sender: AnyObject) {
        if(longPressFlag == false){
            view.endEditing(true)
            self.myChannelSearchBar.text = ""
            self.myChannelSearchBar.resignFirstResponder()
            searchActive = false
            self.myChannelTableView.reloadData()
        }
    }
    
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
                ErrorManager.sharedInstance.InvalidChannelEnteredError()
                channelCreateButton.hidden = true
            }
        }
    }
    
    func addKeyboardObservers()
    {
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:#selector(MyChannelViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object:nil)]
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:#selector(MyChannelViewController.keyboardDidHide), name: UIKeyboardWillHideNotification, object:nil)]
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
            return  GlobalDataChannelList.sharedInstance.globalChannelDataSource.count > 0 ? ( GlobalDataChannelList.sharedInstance.globalChannelDataSource.count) : 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var dataSourceTmp : [[String:AnyObject]]?
        if(searchActive){
            dataSourceTmp = searchDataSource
        }
        else{
            dataSourceTmp = GlobalDataChannelList.sharedInstance.globalChannelDataSource
        }
        
        if dataSourceTmp!.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(MyChannelCell.identifier, forIndexPath:indexPath) as! MyChannelCell
            
            let channleName = dataSourceTmp![indexPath.row][channelNameKey] as? String
            if ((channleName == "My Day") || (channleName == "Archive"))
            {
                cell.removeGestureRecognizer(longPressRecognizer)
            }
            else{
                longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MyChannelViewController.handleChannelLongPress(_:)))
                cell.addGestureRecognizer(longPressRecognizer)
            }
            
            if(indexPath.row == longPressIndexPathRow)
            {
                let str = NSUserDefaults.standardUserDefaults().valueForKey("editedValue")
                cell.editChanelNameTextField.text = str as? String
                cell.channelNameLabel.hidden = true
                cell.editChanelNameTextField.hidden = false
                cell.editChanelNameTextField.userInteractionEnabled = true
                cell.editChanelNameTextField.autocorrectionType = .No
                cell.editChanelNameTextField.becomeFirstResponder()
                cell.channelItemCount.text = dataSourceTmp![indexPath.row][totalMediaKey] as? String
                if let latestImage = dataSourceTmp![indexPath.row][tImageKey]
                {
                    cell.channelHeadImageView.image = latestImage as? UIImage
                }
                else
                {
                    cell.channelHeadImageView.image = UIImage(named: "thumb12")
                }
            }
            else{
                cell.editChanelNameTextField.text = ""
                cell.editChanelNameTextField.hidden = true
                cell.editChanelNameTextField.userInteractionEnabled = false
                cell.channelNameLabel.hidden = false
                cell.channelNameLabel.text = dataSourceTmp![indexPath.row][channelNameKey] as? String
                cell.channelItemCount.text = dataSourceTmp![indexPath.row][totalMediaKey] as? String
                if let latestImage = dataSourceTmp![indexPath.row][tImageKey]
                {
                    cell.channelHeadImageView.image = latestImage as? UIImage
                }
                else
                {
                    cell.channelHeadImageView.image = UIImage(named: "thumb12")
                }
                cell.selectionStyle = .None
            }
            
            return cell
        }
        else{
            return UITableViewCell()
        }
    }

    func handleChannelLongPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let longPressLocation = longPressGestureRecognizer.locationInView(self.myChannelTableView)
        if let longPressIndexPath = self.myChannelTableView.indexPathForRowAtPoint(longPressLocation) {
            var chanelNameChk = String()
          
            if(longPressFlag == false){
                longPressFlag = true
                longPressIndexPathRow = longPressIndexPath.row
                
                if(searchFlagForUpdateChannel){
                    chanelNameChk = searchDataSource[longPressIndexPathRow][channelNameKey] as! String
                }
                else{
                    chanelNameChk = GlobalDataChannelList.sharedInstance.globalChannelDataSource[longPressIndexPathRow][channelNameKey] as! String
                }
                if(chanelNameChk == "My Day" || chanelNameChk == "Archive")
                {
                    longPressIndexPathRow = -1
                    longPressFlag = false
                    myChannelSearchBar.hidden = false
                }
                else
                {
                    myChannelSearchBar.hidden = true
                    notifImage.hidden = true
                    channelAddButton.hidden = true
                    channelUpdateCancelButton.hidden = false
                    channelUpdateSaveButton.hidden = false
                    backButton.hidden = true
                    myChannelTableView.reloadData()
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if(longPressFlag == false){
            var channelName : String = String()
            if(searchActive){
                channelName = searchDataSource[indexPath.row][channelNameKey] as! String
            }
            else{
                channelName = GlobalDataChannelList.sharedInstance.globalChannelDataSource[indexPath.row][channelNameKey] as! String
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
        return false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            var deletedChannelId : String = String()
            if(searchActive){
                deletedChannelId = self.searchDataSource[indexPath.row][channelIdKey] as! String
            }
            else{
                deletedChannelId = GlobalDataChannelList.sharedInstance.globalChannelDataSource[indexPath.row][channelIdKey] as! String
            }
            generateWaytoSendAlert(deletedChannelId, indexPath: indexPath.row)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if(addChannelView.hidden)
        {
            if(longPressFlag == false){
            myChannelSearchBar.hidden = false
            addChannelView.hidden = true
            myChannelTableViewTopConstraint.constant = -90
            }
        }
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if searchBar.text!.isEmpty
        {
            searchActive = false
            searchFlagForUpdateChannel = false
            searchDataSource.removeAll()
        }
        else{
            searchActive = true
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
    //    searchActive = false
    //    searchFlagForUpdateChannel = false
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        searchActive = false;
//        searchFlagForUpdateChannel = false

    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        searchActive = false;
//        searchFlagForUpdateChannel = false

    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchDataSource.removeAll()
        if myChannelSearchBar.text!.isEmpty
        {
            searchDataSource = GlobalDataChannelList.sharedInstance.globalChannelDataSource
            myChannelSearchBar.resignFirstResponder()
            self.myChannelTableView.reloadData()
        }
        else{
            if GlobalDataChannelList.sharedInstance.globalChannelDataSource.count > 0
            {
                for element in GlobalDataChannelList.sharedInstance.globalChannelDataSource{
                    let tmp: String = (element[channelNameKey]?.lowercaseString)!
                    if(tmp.containsString(searchText.lowercaseString))
                    {
                        searchDataSource.append(element)
                    }
                }
                searchActive = true
                searchFlagForUpdateChannel = true
                self.myChannelTableView.reloadData()
            }
        }
    }
}


