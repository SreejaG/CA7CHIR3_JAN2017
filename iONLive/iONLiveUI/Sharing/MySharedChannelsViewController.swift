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
    @IBOutlet weak var tableViewBottomConstaint: NSLayoutConstraint!
    
    let channelNameKey = "channelName"
    let channelShareCountKey = "channelShareCount"
    let channelSelectionKey = "channelSelection"
    
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
    @IBAction func backButtonClicked(sender: AnyObject)
    {
        self.dismissViewControllerAnimated(true) { () -> Void in
        }
    }
    
    func createDummyDataSource()
    {
        dataSource = [[channelNameKey:"My Day",channelShareCountKey:"9",channelSelectionKey:"0"],[channelNameKey:"Work stuff",channelShareCountKey:"5",channelSelectionKey:"0"],[channelNameKey:"Ideas & screenshots",channelShareCountKey:"8",channelSelectionKey:"0"]]
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


extension MySharedChannelsViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 45.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(MySharedChannelsHeaderCell.identifier) as! MySharedChannelsHeaderCell
        headerCell.headerTitleLabel.text = "MY SHARED CHANNELS"
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 60
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01   // to avoid extra blank lines
    }
}


extension MySharedChannelsViewController:UITableViewDataSource
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
                let cell = tableView.dequeueReusableCellWithIdentifier(MySharedChannelsCell.identifier, forIndexPath:indexPath) as! MySharedChannelsCell
                cell.channelNameLabel.text = dataSource[indexPath.row][channelNameKey]
                cell.sharedCountLabel.text = dataSource[indexPath.row][channelShareCountKey]
                if Int(dataSource[indexPath.row][channelSelectionKey]!) == 0
                {
                    cell.channelSelectionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
                    cell.sharedCountLabel.hidden = true
                    cell.avatarIconImageView.hidden = true
                }
                else if Int(dataSource[indexPath.row][channelSelectionKey]!) == 1
                {
                    cell.channelSelectionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
                    cell.sharedCountLabel.hidden = false
                    cell.avatarIconImageView.hidden = false
                }
                cell.cellDataSource = dataSource[indexPath.row]
                cell.selectionStyle = .None
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
    }
}
