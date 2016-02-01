//
//  iONLiveCamAPIListViewController.swift
//  iONLive
//
//  Created by Gadgeon on 1/18/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class iONLiveCamAPIListViewController: UIViewController {
    
    @IBOutlet weak var testingAPIListTableView: UITableView!
    static let identifier = "iONLiveCamAPIListViewController"
    
    var wifiButtonSelected = true
    var dataSource:[String]?
    var wifiAPIList = ["Image capture","Video capture","Camera configuration","Live streaming configuration","Cloud connectivity configuration","Camera status","System information and modification","Download Image file","Download HLS playlist","Download video file","Download HLS segment"]
    var bleAPIList = [""]
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        if wifiButtonSelected
        {
            dataSource = wifiAPIList
        }
        else
        {
            dataSource = bleAPIList
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //PRAGMA MARK:- IBActions
    @IBAction func backButtonClicked(sender: AnyObject)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    @IBAction func wifiButtonClicked(sender: AnyObject)
    {
        wifiButtonSelected = true
        dataSource = wifiAPIList
        testingAPIListTableView.reloadData()
    }
    
    @IBAction func bleButtonClicked(sender: AnyObject)
    {
        wifiButtonSelected = false
        dataSource = bleAPIList
        testingAPIListTableView.reloadData()
    }
}

extension iONLiveCamAPIListViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 75.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return dataSource != nil ? (dataSource!.count) :0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                let cell = UITableViewCell(style:.Default, reuseIdentifier:"Cell")
                cell.textLabel?.text = dataSource[indexPath.row]
                cell.selectionStyle = .None
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let pictureApiVC = apiTestStoryboard.instantiateViewControllerWithIdentifier(iONCamPictureAPIViewController.identifier) as! iONCamPictureAPIViewController
        switch indexPath.row
        {
            case 0:
                self.navigationController?.pushViewController(pictureApiVC, animated: true)
                break;
            default:
                break;
        }
        ///channelItemListVC.navigationController?.navigationBarHidden = true
    }
}
