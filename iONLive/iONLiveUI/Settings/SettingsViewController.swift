//
//  SettingsViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/10/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
}

extension SettingsViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 50.0
    }
    
//    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
//    {
//        
//    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch section
        {
        case 0:
            return 6
            
        case 1:
            return 5
            
        case 2:
            return 2
            
        default:
            return 0
            
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingsToggleTableViewCell", forIndexPath:indexPath)
        return cell
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 3
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
