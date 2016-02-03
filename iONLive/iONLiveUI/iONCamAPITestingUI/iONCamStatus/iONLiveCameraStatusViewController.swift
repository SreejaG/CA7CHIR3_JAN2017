//
//  iONLiveCameraStatusViewController.swift
//  iONLive
//
//  Created by Vinitha on 2/3/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class iONLiveCameraStatusViewController: UIViewController {

    static let identifier = "iONLiveCameraStatusViewController"
    
 //PRAGMA MARK:- Outlets
    @IBOutlet var containerView: UIView!
    @IBOutlet var catalogTableView: UITableView!
    @IBOutlet var videoTableView: UITableView!
    
    @IBOutlet var freememTextField: UITextField!
    @IBOutlet var batteryLevelTextField: UITextField!
    @IBOutlet var spaceLeftTextField: UITextField!
    
//PRAGMA MARK:- table datasource
    var catalogDataSource : [String]?
    var videoDataSource : [String]?
    
//PRAGMA MARK:- class variables
    let requestManager = RequestManager.sharedInstance
    let iONLiveCameraStatusManager = iONLiveCameraStatus.sharedInstance
    
//PRAGMA MARK:- loadView
    override func viewDidLoad() {
        
        super.viewDidLoad()
        containerView.hidden = true
    }
    
    //PRAGMA MARK:- Actions
    @IBAction func didTapGetCameraStatus(sender: AnyObject) {
        
        iONLiveCameraStatusManager.getiONLiveCameraStatus({ (response) -> () in
            
            self.iONLiveCamGetStatusSuccessHandler(response)
            
            }) { (error, code) -> () in
                
                 ErrorManager.sharedInstance.alert("Status Failed", message: "Failure to get status ")
        }
        
    }
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //PRAGMA MARK:- API Handlers

    func iONLiveCamGetStatusSuccessHandler(response:AnyObject?)
    {
        containerView.hidden = false
        
        print("entered status")
        if let json = response as? [String: AnyObject]
        {
            print("success")
            if let freemem = json["freemem"]
            {
                freememTextField.text = freemem as? String
            }
            if let spaceLeft = json["spaceLeft"]
            {
                spaceLeftTextField.text = spaceLeft as? String
            }
            if let batteryLevel = json["batteryLevel"]
            {
                batteryLevelTextField.text = batteryLevel as? String
            }
            if let catalog = json["catalog"]
            {
                self.catalogDataSource = catalog as? [String]
                print("value[0]\(catalogDataSource![0])")
                catalogTableView.reloadData()
            }
            if let video = json["video"]
            {
                self.videoDataSource = video as? [String]
                print("value[0]\(videoDataSource![0])")
                videoTableView.reloadData()
            }
        }
    }
}
    //PRAGMA MARK:- Helper Methods
    
extension iONLiveCameraStatusViewController{
    
    func getNumberOfTableRows(tableView:UITableView) -> Int
    {
        if tableView.isEqual(catalogTableView)
        {
            return catalogDataSource != nil ? (catalogDataSource!.count) :0
        }
        else if tableView.isEqual(videoTableView)
        {
            return videoDataSource != nil ? (videoDataSource!.count):0
        }
        return 0
    }
    
    func getTableViewCell(dataSource:[String] , ForRow row:Int) -> UITableViewCell
    {
        if dataSource.count > row
        {
            let cell = UITableViewCell(style:.Default, reuseIdentifier:"Cell")
            cell.textLabel?.text = dataSource[row]
            cell.selectionStyle = .None
            cell.textLabel?.numberOfLines = 0;
            cell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
            return cell
        }
        return UITableViewCell()
    }
    
    func loadTableViewCell(tableView: UITableView , ForRow row:Int) -> UITableViewCell
    {
        if tableView.isEqual(catalogTableView)
        {
            return loadCatalogTableView(tableView, ForRow: row)
        }
        else if tableView.isEqual(videoTableView)
        {
            return loadVideoTableView(tableView ,ForRow: row)
        }
        return UITableViewCell()
    }
    
    func loadCatalogTableView(tableView: UITableView , ForRow row:Int) -> UITableViewCell
    {
        if let dataSource = catalogDataSource
        {
            return getTableViewCell(dataSource, ForRow: row)
        }
        return UITableViewCell()
    }
    
    func loadVideoTableView(tableView: UITableView , ForRow row:Int) -> UITableViewCell
    {
        if let dataSource = videoDataSource
        {
            return getTableViewCell(dataSource, ForRow: row)
        }
        return UITableViewCell()
    }
}
//PRAGMA MARK:- table DataSource Delegate

extension iONLiveCameraStatusViewController:UITableViewDelegate,UITableViewDataSource
{
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return getNumberOfTableRows(tableView)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        return loadTableViewCell(tableView, ForRow: indexPath.row)
    }
}

