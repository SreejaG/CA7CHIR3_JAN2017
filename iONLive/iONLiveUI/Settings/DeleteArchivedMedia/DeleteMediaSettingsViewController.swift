
import UIKit

class DeleteMediaSettingsViewController: UIViewController{
    
    static let identifier = "DeleteMediaSettingsViewController"
    
    @IBOutlet weak var deleteMediaSettingsTableView: UITableView!
    
    var dataSource = ["Never","After 30 Days","After 7 Days"]
    
    var selectedOption:String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(NSUserDefaults.standardUserDefaults().valueForKey("archiveMediaDeletion") != nil)
        {
            let value = NSUserDefaults.standardUserDefaults().valueForKey("archiveMediaDeletion") as! String
            selectedOption = FileManagerViewController.sharedInstance.getArchiveDeleteLongString(value)
        }
        else{
            selectedOption = "Never"
        }
        deleteMediaSettingsTableView.reloadData()
    }
    
    @IBAction func didTapBackButton(sender: AnyObject)
    {
        let value = FileManagerViewController.sharedInstance.getArchiveDeleteShortString(selectedOption)
        NSUserDefaults.standardUserDefaults().setValue(value, forKey: "archiveMediaDeletion")
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension DeleteMediaSettingsViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(DeleteMediaSettingsHeaderCell.identifier) as! DeleteMediaSettingsHeaderCell
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
            headerCell.headerTitleLabel.text = "Archieved Media is stored on the Catch Cloud."
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


extension DeleteMediaSettingsViewController:UITableViewDataSource
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
            let cell = tableView.dequeueReusableCellWithIdentifier(DeleteMediaOptionCell.identifier, forIndexPath:indexPath) as! DeleteMediaOptionCell
            cell.mediaDeleteOptionLabel.text = dataSource[indexPath.row]
            cell.selectionStyle = .None
            
            if selectedOption == dataSource[indexPath.row]
            {
                cell.selectionImageView.hidden = false
            }
            else
            {
                cell.selectionImageView.hidden = true
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
            deleteMediaSettingsTableView.reloadData()
        }
    }
}