//
//  SnapCamSelectViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/1/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class SnapCamSelectViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    static let identifier = "SnapCamSelectViewController"
    @IBOutlet weak var snapCamSettingsTableView: UITableView!
    
    var dataSource = ["Live Stream", "Photos", "Video" , "Catch gif", "Time lapse", "Switch to iPhone"]
   
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
//    override func viewWillAppear(animated: Bool) {
//            self.view.backgroundColor = UIColor.clearColor()
//            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
//            let blurEffectView = UIVisualEffectView(effect: blurEffect)
//            //always fill the view
//            blurEffectView.frame = self.view.bounds
//            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
//            
//            self.view.addSubview(blurEffectView) //if you have more UIViews, use an insertSubview API to place it where needed
//        }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    //PRAGMA MARK:- TableView datasource, delegates
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let count = dataSource.count
        if count > 0
        {
            return count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
       let cell = tableView.dequeueReusableCellWithIdentifier(SnapCamTableViewCell.identifier, forIndexPath: indexPath) as! SnapCamTableViewCell
        if dataSource.count > indexPath.row
        {
            cell.optionlabel.text = dataSource[indexPath.row]
        }
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
//       switch(indexPath.row)
//       {
//       case 0: break
//          //live stream
//       }
        
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return snapCamSettingsTableView.bounds.height / CGFloat(dataSource.count)

    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("SnapCamCustomHeaderCell") as! SnapCamCustomHeaderCell
        return headerCell
    }
}





