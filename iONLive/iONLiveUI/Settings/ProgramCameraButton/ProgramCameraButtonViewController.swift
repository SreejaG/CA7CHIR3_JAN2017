//
//  ProgramCameraButtonViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/28/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class ProgramCameraButtonViewController: UIViewController {
    
    static let identifier = "ProgramCameraButtonViewController"

    @IBOutlet weak var programCameraButonTableView: UITableView!
    var dataSource = ["One click picture | Double click video","One click picture | Double click GIF","One click video | Double click live-stream"]
    
    var selectedOption:String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didTapBackButton(sender: AnyObject)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ProgramCameraButtonViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(ProgramCameraButtonHeaderCell.identifier) as! ProgramCameraButtonHeaderCell
        headerCell.topBorder.hidden = false
        headerCell.bottomBorder.hidden = false
        
        switch section
        {
        case 0:
            headerCell.topBorder.hidden = true
            headerCell.headerTitleLabel.text = ""
            break
        case 1:
            headerCell.bottomBorder.hidden = true
            headerCell.headerTitleLabel.text = ""
            break
        default:
            break
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 44.0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01   // to avoid extra blank lines
    }
}


extension ProgramCameraButtonViewController:UITableViewDataSource
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if dataSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(ProgramCameraButtonCell.identifier, forIndexPath:indexPath) as! ProgramCameraButtonCell
            cell.cameraOptionslabel.text = dataSource[indexPath.row]
            cell.selectionStyle = .None
            
            if selectedOption == dataSource[indexPath.row]
            {
                cell.selectionImage.hidden = false
            }
            else
            {
                cell.selectionImage.hidden = true
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if dataSource.count > indexPath.row
        {
            selectedOption = dataSource[indexPath.row]
            programCameraButonTableView.reloadData()
        }
    }
}
