//
//  EditProfileViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/14/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController {

    static let identifier = "EditProfileViewController"
    @IBOutlet weak var editProfileTableView: UITableView!
    
    @IBOutlet weak var tableViewBottomConstaint: NSLayoutConstraint!
    let userNameKey = "userNameKey"
    let displayNameKey = "displayNameKey"
    let titleKey = "titleKey"
    
    let personalInfoCell = "personalInfoCell"
    let accountInfoCell = "accountInfoCell"
    let privateInfoCell = "privateInfoCell"
    
    var profileInfoOptions = [[String:String]]()
    var privateInfoOptions = [[String:String]]()
    var accountInfoOptions = [[String:String]]()
    
    var dataSource:[[[String:String]]]?
    
    @IBOutlet weak var editProfTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileInfoOptions = [[displayNameKey:"Rom Eizenberg",userNameKey:"romeizenberg"]] // replace uername etc here from API response of editP screen
        accountInfoOptions = [[titleKey:"Upgrade to Premium Account"], [titleKey:"Status"]]
        privateInfoOptions = [[titleKey:"reizenberg@gmail.com"],[titleKey:"555-555-5555"]]
        
        dataSource = [profileInfoOptions,accountInfoOptions,privateInfoOptions]
        
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
            return 1  // for terms and conditn sectn
            
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
                    cell.displayNameTextField.text = cellDataSource[displayNameKey]
                    cell.userNameTextField.text = cellDataSource[userNameKey]
                    cell.selectionStyle = .None
                    return cell
                   
                case 1:
                    let cell = tableView.dequeueReusableCellWithIdentifier(EditProfAccountInfoCell.identifier, forIndexPath:indexPath) as! EditProfAccountInfoCell
                    cell.accountInfoTitleLabel.text = cellDataSource[titleKey]
                    //no border line for last cell
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

