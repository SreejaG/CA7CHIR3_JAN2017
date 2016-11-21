
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
    
    @IBAction func didTapBackButton(_ sender: Any)
    {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension TimeLapseSettingsViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: TimeLapseHeaderCell.identifier) as! TimeLapseHeaderCell
        headerCell.topBorder.isHidden = false
        headerCell.bottomBorder.isHidden = false
        
        switch section
        {
        case 0:
            headerCell.topBorder.isHidden = true
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return dataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if dataSource.count > indexPath.section
        {
            if dataSource[indexPath.section].count > indexPath.row
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: TimeTapseCell.identifier, for:indexPath as IndexPath) as! TimeTapseCell
                cell.timelapseOptionLabel.text = dataSource[indexPath.section][indexPath.row]
                cell.selectionStyle = .none
                
                if getselectedOptionForSection(section: indexPath.section) == dataSource[indexPath.section][indexPath.row]
                {
                    cell.selectionImageView.isHidden = false
                }
                else
                {
                    cell.selectionImageView.isHidden = true
                }
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if dataSource.count > indexPath.section && dataSource[indexPath.section].count > indexPath.row
        {
            setSelectedOption(indexPath: indexPath as NSIndexPath)
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

