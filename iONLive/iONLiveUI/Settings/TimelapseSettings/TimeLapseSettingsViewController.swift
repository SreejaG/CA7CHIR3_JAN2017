//
//  TimeLapseSettingsViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class TimeLapseSettingsViewController: UIViewController {
    
    static let identifier = "TimeLapseSettingsViewController"
    @IBOutlet weak var timeLapseTableView: UITableView!
    
    let captureImageOption = "captureImageOption"
    let imageDurationOption = "imageDurationOption"
    
    var dataSource = [["Every 5 seconds","Every 10 seconds","Every 15 seconds"],["Stop after 5 minutes","Stop after 10 minutes","Stop after 15 minutes"]]
    
    var selectedOptions:[String:String] = [String:String]()

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

extension TimeLapseSettingsViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 55.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(TimeLapseHeaderCell.identifier) as! TimeLapseHeaderCell
        headerCell.topBorder.hidden = false
        headerCell.bottomBorder.hidden = false
        
        switch section
        {
        case 0:
             headerCell.topBorder.hidden = true
             headerCell.headerTitleLabel.text = "CAPTURE IMAGE"
             break
        case 1:
             headerCell.headerTitleLabel.text = "IMAGE DURATION"
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


extension TimeLapseSettingsViewController:UITableViewDataSource
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return dataSource[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if dataSource.count > indexPath.section
        {
            if dataSource[indexPath.section].count > indexPath.row
            {
                let cell = tableView.dequeueReusableCellWithIdentifier(TimeTapseCell.identifier, forIndexPath:indexPath) as! TimeTapseCell
                cell.timelapseOptionLabel.text = dataSource[indexPath.section][indexPath.row]
                cell.selectionStyle = .None
                
                if getselectedOptionForSection(indexPath.section) == dataSource[indexPath.section][indexPath.row]
                {
                    cell.selectionImageView.hidden = false
                }
                else
                {
                    cell.selectionImageView.hidden = true
                }
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if dataSource.count > indexPath.section && dataSource[indexPath.section].count > indexPath.row
        {
            setSelectedOption(indexPath)
            timeLapseTableView.reloadData()
        }
    }
    
    func getselectedOptionForSection(section:Int) -> String?
    {
        var selectedOption:String?
        switch section
        {
        case 0:
            selectedOption = selectedOptions[captureImageOption]
            break
        case 1:
            selectedOption = selectedOptions[imageDurationOption]
            break
        default:
            selectedOption = ""
        }
        return selectedOption
    }
    
    func setSelectedOption(indexPath:NSIndexPath)
    {
        switch indexPath.section
        {
        case 0:
          selectedOptions[captureImageOption] = dataSource[indexPath.section][indexPath.row]
            break
        case 1:
           selectedOptions[imageDurationOption] = dataSource[indexPath.section][indexPath.row]
            break
        default:
            break
        }
    }
}

