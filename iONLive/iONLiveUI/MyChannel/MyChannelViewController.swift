//
//  MyChannelViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/28/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MyChannelViewController: UIViewController {
    
    static let identifier = "MyChannelViewController"

    @IBOutlet weak var myChannelSearchBar: UISearchBar!
    @IBOutlet weak var myChannelTableView: UITableView!

    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!

    let channelNameKey = "channelName"
    let channelItemCountKey = "channelItemCount"
    let channelHeadImageNameKey = "channelHeadImageName"
    
    var dataSource:[[String:String]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createDummyDataSource()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didtapBackButton(sender: AnyObject)
    {
        self.navigationController?.viewControllers[0].dismissViewControllerAnimated(true, completion: { () -> Void in
        })
    }
    
    func createDummyDataSource()
    {
        dataSource = [[channelNameKey:"My Day",channelItemCountKey:"8",channelHeadImageNameKey:"thumb11"],[channelNameKey:"Work stuff",channelItemCountKey:"17",channelHeadImageNameKey:"thumb10"],[channelNameKey:"Ideas & screenshots",channelItemCountKey:"5",channelHeadImageNameKey:"thumb8"],[channelNameKey:"Archive",channelItemCountKey:"276",channelHeadImageNameKey:"thumb9"]]
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
}


extension MyChannelViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 75.0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01   // to avoid extra blank lines
    }
}


extension MyChannelViewController:UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return dataSource != nil ? (dataSource?.count)! :0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                let cell = tableView.dequeueReusableCellWithIdentifier(MyChannelCell.identifier, forIndexPath:indexPath) as! MyChannelCell
                cell.channelNameLabel.text = dataSource[indexPath.row][channelNameKey]
                cell.channelItemCount.text = dataSource[indexPath.row][channelItemCountKey]
                if let imageName = dataSource[indexPath.row][channelHeadImageNameKey]
                {
                    cell.channelHeadImageView.image = UIImage(named:imageName)
                }
                cell.selectionStyle = .None
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let sharingStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let channelItemListVC = sharingStoryboard.instantiateViewControllerWithIdentifier(ChannelItemListViewController.identifier) as! ChannelItemListViewController
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                channelItemListVC.channelName = dataSource[indexPath.row][channelNameKey]
            }
        }
        channelItemListVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelItemListVC, animated: true)
    }
}


