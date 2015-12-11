//
//  SettingsViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/10/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    let optionTitle = "optionTitle"
    let optionType = "optionType"
    let accessryText = "accessryText"
    
    let toggleCell = "toggleCell"
    let normalCell = "normalCell"
    
    var cameraOptions = [[String:String]]()
    var accountOptions = [[String:String]]()
    var supportOptions = [[String:String]]()
    
    var dataSource:[[[String:String]]]?
    
    @IBOutlet weak var settingsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
         cameraOptions = [[optionTitle:"Upload to wifi", optionType : toggleCell, accessryText:""],[optionTitle:"Vivid Mode", optionType : toggleCell, accessryText:""],[optionTitle:"Time Lapse", optionType : normalCell, accessryText:""],[optionTitle:"Live Streaming Quality", optionType : normalCell, accessryText:"HD"],[optionTitle:"Save to Camera Roll", optionType : toggleCell, accessryText: ""],[optionTitle:"Get Snapcam! ", optionType : normalCell, accessryText: ""]]
        
         accountOptions = [[optionTitle:"Edit profile", optionType : normalCell, accessryText:""],[optionTitle:"Delete Archived Media", optionType : normalCell, accessryText:"Never"],[optionTitle:"Connect Accounts", optionType : normalCell, accessryText:""]]
        
         supportOptions = [[optionTitle:"Help Center ", optionType : normalCell, accessryText:""],[optionTitle:"Report a Problem", optionType : normalCell, accessryText:""]]
        
        dataSource = [cameraOptions,accountOptions,supportOptions]
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.settingsTableView.backgroundView = nil
        self.settingsTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

extension SettingsViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if section == 0
        {
            return 50.0
        }
        else
        {
             return 40.0
        }
    }
    
//    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        
//        if(section == 0) {
//            var view = UIView() // The width will be the same as the cell, and the height should be set in tableView:heightForRowAtIndexPath:
//            var label = UILabel()
//            label.text = "CAMERA"
//            label.textColor = UIColor.lightGrayColor()
//           
//            view.addSubview(label)
//           
//           view.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
//            return view
//        }
//        return nil
//    }
////    
////  func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
////  {
////     //view.tintColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
////    view.tintColor = UIColor.redColor()
////    }
    
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
            
        default:
             return 0
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        var cellDataSource:[String:String]?
        
        if let dataSource = dataSource
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
            if cellDataSource[optionType] == toggleCell
            {
               let cell = tableView.dequeueReusableCellWithIdentifier("SettingsToggleTableViewCell", forIndexPath:indexPath) as! SettingsToggleTableViewCell
                cell.titlelabel.text = cellDataSource[optionTitle]
                return cell
            }
            else
            {
                let cell = tableView.dequeueReusableCellWithIdentifier("SettingsTableViewCell", forIndexPath:indexPath) as! SettingsTableViewCell
                cell.titleLabel.text = cellDataSource[optionTitle]
                cell.accessryLabel.text = cellDataSource[accessryText]
                return cell
            }
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
    
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        switch section
        {
        case 0:
            return "CAMERA"
            
        case 1:
            return "ACCOUNT"
            
        case 2:
            return "SUPPORT"
            
        default:
            return ""
            
        }
    }
}
