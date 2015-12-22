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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func backButtonClicked(sender: AnyObject) {
    }
}


//extension MySharedChannelsViewController: UITableViewDelegate
//{
//    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
//    {
//        return 45.0
//    }
//    
////    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
////    {
////        let  headerCell = tableView.dequeueReusableCellWithIdentifier(MySharedChannelsHeaderCell.identifier) as! MySharedChannelsHeaderCell
////        
////        switch (section) {
////        case 0:
////            headerCell.headerTitleLabel.text = ""
////        case 1:
////            headerCell.headerTitleLabel.text = "ACCOUNT INFO"
////        case 2:
////            headerCell.headerTitleLabel.text = "PRIVATE INFO"
////        case 3:
////            let privacyPolicyDesc = NSMutableAttributedString(string: "All your Media is Private unless Channels are shared to specific people. Archive is always private to you.")
////            let privacyPolicyString = NSMutableAttributedString(string:"\nPrivacy Policy")
////            privacyPolicyString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 44.0/255, green: 214.0/255, blue: 229.0/255, alpha: 1.0), range: NSMakeRange(0, privacyPolicyString.length))
////            privacyPolicyDesc.appendAttributedString(privacyPolicyString)
////            
////            headerCell.headerTitleLabel.attributedText = privacyPolicyDesc
////            
////        default:
////            headerCell.headerTitleLabel.text = ""
////        }
////        return headerCell
////    }
//    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
//    {
//        if indexPath.section == 0
//        {
//            return 90.0
//        }
//        else
//        {
//            return 44.0
//        }
//        
//    }
//    
//    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
//    {
//        return 0.01   // to avoid extra blank lines
//    }
//}


//extension MySharedChannelsViewController:UITableViewDataSource
//{
//    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
//    {
//        switch section
//        {
//        case 0:
//            return dataSource != nil ? (dataSource?[0].count)! :0
//            
//        case 1:
//            return dataSource != nil ? (dataSource?[1].count)! :0
//            
//        case 2:
//            return dataSource != nil ? (dataSource?[2].count)! :0
//            
//        case 3:
//            return 1  // for terms and conditn sectn
//            
//        default:
//            return 0
//        }
//    }
//    
//    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
//    {
//        if let dataSource = dataSource
//        {
//            if dataSource.count > indexPath.section && dataSource[indexPath.section].count > indexPath.row
//            {
//                var cellDataSource = dataSource[indexPath.section][indexPath.row]
//                switch indexPath.section
//                {
//                case 0:
//                    let cell = tableView.dequeueReusableCellWithIdentifier(EditProfPersonalInfoCell.identifier, forIndexPath:indexPath) as! EditProfPersonalInfoCell
//                    cell.displayNameTextField.text = cellDataSource[displayNameKey]
//                    cell.userNameTextField.text = cellDataSource[userNameKey]
//                    cell.selectionStyle = .None
//                    return cell
//                    
//                case 1:
//                    let cell = tableView.dequeueReusableCellWithIdentifier(EditProfAccountInfoCell.identifier, forIndexPath:indexPath) as! EditProfAccountInfoCell
//                    cell.accountInfoTitleLabel.text = cellDataSource[titleKey]
//                    cell.selectionStyle = .Default
//                    return cell
//                    
//                case 2:
//                    let cell = tableView.dequeueReusableCellWithIdentifier(EditProfPrivateInfoCell.identifier, forIndexPath:indexPath) as! EditProfPrivateInfoCell
//                    cell.privateInfoTitleLabel.text = cellDataSource[titleKey]
//                    cell.selectionStyle = .None
//                    return cell
//                default:
//                    return UITableViewCell()
//                }
//            }
//        }
//        return UITableViewCell()
//    }
//    
//    
//    func numberOfSectionsInTableView(tableView: UITableView) -> Int
//    {
//        if let dataSource = dataSource
//        {
//            return dataSource.count + 1 //1 for last termsAndConditn section
//        }
//        else
//        {
//            return 0
//        }
//    }
//    
//    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
//    {
//        
//    }
//}
