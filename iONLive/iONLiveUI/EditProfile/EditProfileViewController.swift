//
//  EditProfileViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/14/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController, UINavigationControllerDelegate,UIImagePickerControllerDelegate {
    
    static let identifier = "EditProfileViewController"
    @IBOutlet weak var editProfileTableView: UITableView!
    
    let requestManager = RequestManager.sharedInstance
    let profileManager = ProfileManager.sharedInstance
    
    var loadingOverlay: UIView?
    let imagePicker = UIImagePickerController()
    var imageForProfile : UIImage = UIImage()
    
    @IBOutlet weak var tableViewBottomConstaint: NSLayoutConstraint!
    
    
    let userNameKey = "userNameKey"
    let displayNameKey = "displayNameKey"
    let titleKey = "titleKey"
    
    let personalInfoCell = "personalInfoCell"
    let accountInfoCell = "accountInfoCell"
    let privateInfoCell = "privateInfoCell"
    let countryPickerCell = "countryPickerCell"
    
    var profileInfoOptions = [[String:String]]()
    var privateInfoOptions = [[String:String]]()
    var accountInfoOptions = [[String:String]]()
    
    var dataSource:[[[String:String]]]?
    
    var userDetails: NSMutableDictionary = NSMutableDictionary()
    
    
    @IBOutlet weak var editProfTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    @IBAction func tapGestureRecognizer(sender: AnyObject) {
        view.endEditing(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.editProfTableView.backgroundView = nil
        self.editProfTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
        addKeyboardObservers()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func initialise()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getUserDetails(userId, token: accessToken)       
    }
    
    func getUserDetails(userName: String, token: String)
    {
        showOverlay()
        profileManager.getUserDetails(userName, accessToken:token, success: { (response) -> () in
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
            let responseArr = json["user"] as! [AnyObject]
            let userDict: NSMutableDictionary = NSMutableDictionary()
            
            for element in responseArr{
                userDict.setDictionary(element as! [NSObject : AnyObject])
            }
            for (key,value) in userDict
            {
                let valueAfterNullCheck =  nullToNil(value)
                userDetails.setValue(valueAfterNullCheck!, forKey: key as! String)
            }
            setUserDetails()
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
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
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
    
    func setUserDetails()
    {
        print(userDetails)
        let fullName = userDetails["full_name"] as! String
        let userName = userDetails["user_name"] as! String
        let email = userDetails["email"] as! String
        let mobileNo = userDetails["mobile_no"] as! String
        imageForProfile = UIImage(named: "girlFace2")!
        profileInfoOptions = [[displayNameKey:fullName, userNameKey:userName]] // replace uername etc here from API response of editP screen
        accountInfoOptions = [[titleKey:"Upgrade to Premium Account"], [titleKey:"Status"], [titleKey:"Reset Password"]]
        privateInfoOptions = [[titleKey:email],/*[titleKey:location],*/[titleKey:mobileNo]]
        
        dataSource = [profileInfoOptions,accountInfoOptions,privateInfoOptions]
        editProfTableView.reloadData()
    }
    
    //end
    
    @IBAction func saveClicked(sender: AnyObject) {
        
    }
    
    @IBAction func backClicked(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
}


extension EditProfileViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if section == 0
        {
            return 30.0
        }
        else if section == 3
        {
            return 60.0
        }
        else
        {
            return 55.0
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(EditProfileHeaderCell.identifier) as! EditProfileHeaderCell
        
        headerCell.borderLine.hidden = false
        headerCell.topBorderLine.hidden = false
        
        switch (section) {
        case 0:
            headerCell.headerTitleLabel.text = ""
            headerCell.topBorderLine.hidden = true
        case 1:
            headerCell.headerTitleLabel.text = "ACCOUNT INFO"
        case 2:
            headerCell.headerTitleLabel.text = "PRIVATE INFO"
        case 3:
            let privacyPolicyDesc = NSMutableAttributedString(string: "All your Media is Private unless Channels are shared to specific people. Archive is always private to you.")
            let privacyPolicyString = NSMutableAttributedString(string:"\nPrivacy Policy")
            privacyPolicyString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 44.0/255, green: 214.0/255, blue: 229.0/255, alpha: 1.0), range: NSMakeRange(0, privacyPolicyString.length))
            privacyPolicyDesc.appendAttributedString(privacyPolicyString)
            
            headerCell.headerTitleLabel.attributedText = privacyPolicyDesc
            headerCell.borderLine.hidden = true
            
        default:
            headerCell.headerTitleLabel.text = ""
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        if indexPath.section == 0
        {
            return 90.0
        }
        else
        {
            return 44.0
        }
        
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01   // to avoid extra blank lines
    }
}


extension EditProfileViewController:UITableViewDataSource
{
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch section
        {
        case 0:
            return dataSource != nil ? (dataSource?[0].count)! :0
            
        case 1:
            return dataSource != nil ? (dataSource?[1].count)! :0
            
        case 2:
            return dataSource != nil ? (dataSource?[2].count)! :0
            
        case 3:
            return 0  // for terms and conditn sectn
            
        default:
            return 0
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.section && dataSource[indexPath.section].count > indexPath.row
            {
                var cellDataSource = dataSource[indexPath.section][indexPath.row]
                switch indexPath.section
                {
                case 0:
                    let cell = tableView.dequeueReusableCellWithIdentifier(EditProfPersonalInfoCell.identifier, forIndexPath:indexPath) as! EditProfPersonalInfoCell
                    
                    cell.editProfileImageButton.addTarget(self, action: "editProfileTapped:", forControlEvents: UIControlEvents.TouchUpInside)
                    
                    if cellDataSource[displayNameKey] == ""
                    {
                        cell.displayNameTextField.attributedPlaceholder = NSAttributedString(string: "Full Name",
                            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
                    }
                    cell.userImage.image = imageForProfile
                    cell.displayNameTextField.text = cellDataSource[displayNameKey]
                    cell.userNameTextField.text = cellDataSource[userNameKey]
                    cell.selectionStyle = .None
                    return cell
                    
                case 1:
                    let cell = tableView.dequeueReusableCellWithIdentifier(EditProfAccountInfoCell.identifier, forIndexPath:indexPath) as! EditProfAccountInfoCell
                    cell.accountInfoTitleLabel.text = cellDataSource[titleKey]
                    if dataSource[indexPath.section].count-1 == indexPath.row
                    {
                        cell.borderLine.hidden = true
                    }
                    else
                    {
                        cell.borderLine.hidden = false
                    }
                    cell.selectionStyle = .Default
                    return cell
                    
                case 2:
                    let cell = tableView.dequeueReusableCellWithIdentifier(EditProfPrivateInfoCell.identifier, forIndexPath:indexPath) as! EditProfPrivateInfoCell
            
                    cell.privateInfoTitleLabel.text = cellDataSource[titleKey]
                    //no border line for last cell
                    if dataSource[indexPath.section].count-1 == indexPath.row
                    {
                        cell.borderLine.hidden = true
                    }
                    else
                    {
                        cell.borderLine.hidden = false
                    }
                    cell.selectionStyle = .None
                    return cell
                    
                default:
                    return UITableViewCell()
                }
            }
        }
        return UITableViewCell()
    }
    
    func editProfileTapped(sender:UIButton!)
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum){
            print("Button capture")
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum;
            imagePicker.allowsEditing = false
        
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
        
        })
        imageForProfile = image
        editProfTableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if let dataSource = dataSource
        {
            return dataSource.count + 1 //1 for last termsAndConditn section
        }
        else
        {
            return 0
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
    }
}

